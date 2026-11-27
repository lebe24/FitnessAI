import AVFoundation
import Flutter
import UIKit

/// Video work the app does on the device: reading a clip's size, trimming and
/// compressing it, and pulling frames out of it for the form analysis.
///
/// It uses the platform's own decoder (AVFoundation), so there is no extra
/// dependency, and none of this touches the network: only the few small JPEG
/// frames that `cropFrames` returns are ever sent anywhere, and that is decided
/// in Dart. See doc/video_analysis_plan.md, section 5.
///
/// Channel `befit/video_tools`. Every call runs off the main thread.
final class VideoToolsChannel {
  private let queue = DispatchQueue(label: "befit.video_tools", qos: .userInitiated)
  private var exports: [String: AVAssetExportSession] = [:]
  private let lock = NSLock()

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "befit/video_tools", binaryMessenger: messenger)
    let tools = VideoToolsChannel()
    channel.setMethodCallHandler { call, result in tools.handle(call, result: result) }
  }

  // MARK: - Dispatch

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      return result(FlutterError(code: "bad_args", message: "Expected a map", details: nil))
    }
    if call.method == "freeSpace" {
      return result(freeSpace())
    }
    queue.async {
      do {
        let value: Any?
        switch call.method {
        case "info": value = try self.info(args)
        case "thumbnail": value = try self.thumbnail(args)
        case "grayFrames": value = try self.grayFrames(args)
        case "cropFrames": value = try self.cropFrames(args)
        case "exportClip":
          // Completes later, from the export session's callback.
          try self.exportClip(args, result: result)
          return
        case "exportProgress": value = self.exportProgress(args)
        case "cancelExport": self.cancelExport(args); value = nil
        default:
          DispatchQueue.main.async { result(FlutterMethodNotImplemented) }
          return
        }
        DispatchQueue.main.async { result(value) }
      } catch let error as VideoToolsError {
        DispatchQueue.main.async {
          result(FlutterError(code: error.code, message: error.message, details: nil))
        }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "failed", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  private struct VideoToolsError: Error {
    let code: String
    let message: String
  }

  private func asset(_ args: [String: Any]) throws -> AVURLAsset {
    guard let path = args["path"] as? String, FileManager.default.fileExists(atPath: path) else {
      throw VideoToolsError(code: "no_file", message: "The video file is missing")
    }
    return AVURLAsset(url: URL(fileURLWithPath: path))
  }

  private func videoTrack(_ asset: AVURLAsset) throws -> AVAssetTrack {
    guard let track = asset.tracks(withMediaType: .video).first else {
      throw VideoToolsError(code: "no_video", message: "That file has no video")
    }
    return track
  }

  /// The size the video is *shown* at, after its rotation is applied.
  private func displaySize(_ track: AVAssetTrack) -> CGSize {
    let size = track.naturalSize.applying(track.preferredTransform)
    return CGSize(width: abs(size.width), height: abs(size.height))
  }

  // MARK: - freeSpace

  /// Space available for things the user would not want lost ("important
  /// usage"): what iOS itself reports to apps, counting space it can reclaim.
  private func freeSpace() -> Any? {
    let url = URL(fileURLWithPath: NSHomeDirectory())
    guard let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
      let bytes = values.volumeAvailableCapacityForImportantUsage
    else { return nil }
    return NSNumber(value: bytes)
  }

  // MARK: - info

  private func info(_ args: [String: Any]) throws -> [String: Any] {
    let asset = try self.asset(args)
    let track = try videoTrack(asset)
    let size = displaySize(track)
    return [
      "durationMs": Int((CMTimeGetSeconds(asset.duration) * 1000).rounded()),
      "width": Int(size.width.rounded()),
      "height": Int(size.height.rounded()),
      "fps": Double(track.nominalFrameRate),
    ]
  }

  // MARK: - thumbnail

  private func generator(_ asset: AVURLAsset, maxEdge: CGFloat?, exact: Bool) -> AVAssetImageGenerator {
    let g = AVAssetImageGenerator(asset: asset)
    g.appliesPreferredTrackTransform = true
    if let edge = maxEdge { g.maximumSize = CGSize(width: edge, height: edge) }
    if exact {
      g.requestedTimeToleranceBefore = .zero
      g.requestedTimeToleranceAfter = .zero
    }
    return g
  }

  private func jpeg(_ image: CGImage, quality: CGFloat) -> Data? {
    UIImage(cgImage: image).jpegData(compressionQuality: quality)
  }

  private func thumbnail(_ args: [String: Any]) throws -> FlutterStandardTypedData {
    let asset = try self.asset(args)
    let atMs = (args["atMs"] as? NSNumber)?.doubleValue ?? 0
    let maxEdge = CGFloat((args["maxEdge"] as? NSNumber)?.doubleValue ?? 480)
    let g = generator(asset, maxEdge: maxEdge, exact: false)
    let time = CMTime(seconds: atMs / 1000, preferredTimescale: 600)
    let image = try g.copyCGImage(at: time, actualTime: nil)
    guard let data = jpeg(image, quality: 0.75) else {
      throw VideoToolsError(code: "encode", message: "Could not encode the thumbnail")
    }
    return FlutterStandardTypedData(bytes: data)
  }

  // MARK: - grayFrames

  /// Small greyscale frames at the requested times, for the motion map.
  ///
  /// Reads the file once, front to back, and keeps the luma plane of the frame
  /// nearest each time. That is far quicker than seeking to each time: a seek
  /// has to decode from the previous keyframe every time.
  /// Returns `{width, height, frames: [Uint8List]}` in display orientation.
  private func grayFrames(_ args: [String: Any]) throws -> [String: Any] {
    let asset = try self.asset(args)
    let track = try videoTrack(asset)
    guard let times = (args["timesMs"] as? [NSNumber])?.map({ $0.doubleValue }), !times.isEmpty else {
      throw VideoToolsError(code: "bad_args", message: "No times")
    }
    let outWidth = max(16, (args["width"] as? NSNumber)?.intValue ?? 160)

    let display = displaySize(track)
    let outHeight = max(16, Int((CGFloat(outWidth) * display.height / display.width).rounded()))
    let rotation = Rotation(transform: track.preferredTransform)

    let reader = try AVAssetReader(asset: asset)
    let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
    ])
    output.alwaysCopiesSampleData = false
    reader.add(output)
    guard reader.startReading() else {
      throw VideoToolsError(code: "read", message: reader.error?.localizedDescription ?? "Could not read the video")
    }

    var frames = [Data?](repeating: nil, count: times.count)
    var next = 0
    var previous: (time: Double, data: Data)?

    while next < times.count, let sample = output.copyNextSampleBuffer() {
      guard let buffer = CMSampleBufferGetImageBuffer(sample) else { continue }
      let t = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sample)) * 1000
      let data = lumaFrame(buffer, outWidth: outWidth, outHeight: outHeight, rotation: rotation)

      // Hand each requested time the frame closest to it.
      while next < times.count, t >= times[next] {
        if let prev = previous, abs(prev.time - times[next]) < abs(t - times[next]) {
          frames[next] = prev.data
        } else {
          frames[next] = data
        }
        next += 1
      }
      previous = (t, data)
    }
    // Times past the last frame get the last frame.
    if let last = previous {
      while next < times.count { frames[next] = last.data; next += 1 }
    }
    reader.cancelReading()

    return [
      "width": outWidth,
      "height": outHeight,
      "frames": frames.map { FlutterStandardTypedData(bytes: $0 ?? Data(count: outWidth * outHeight)) },
    ]
  }

  private enum Rotation {
    case none, cw90, cw180, cw270

    init(transform t: CGAffineTransform) {
      // preferredTransform is a rotation by a multiple of 90 degrees.
      if t.a == 0 && t.b == 1 && t.c == -1 && t.d == 0 { self = .cw90 }
      else if t.a == 0 && t.b == -1 && t.c == 1 && t.d == 0 { self = .cw270 }
      else if t.a == -1 && t.d == -1 { self = .cw180 }
      else { self = .none }
    }
  }

  /// Box-sample the luma plane down to outWidth x outHeight, rotated upright.
  private func lumaFrame(_ buffer: CVPixelBuffer, outWidth: Int, outHeight: Int, rotation: Rotation) -> Data {
    CVPixelBufferLockBaseAddress(buffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }

    let srcW = CVPixelBufferGetWidthOfPlane(buffer, 0)
    let srcH = CVPixelBufferGetHeightOfPlane(buffer, 0)
    let stride = CVPixelBufferGetBytesPerRowOfPlane(buffer, 0)
    guard let base = CVPixelBufferGetBaseAddressOfPlane(buffer, 0) else {
      return Data(count: outWidth * outHeight)
    }
    let src = base.assumingMemoryBound(to: UInt8.self)

    var out = [UInt8](repeating: 0, count: outWidth * outHeight)
    for y in 0..<outHeight {
      for x in 0..<outWidth {
        // Position in the upright picture, 0...1.
        let u = (Double(x) + 0.5) / Double(outWidth)
        let v = (Double(y) + 0.5) / Double(outHeight)
        // Where that is in the stored (unrotated) picture.
        let (su, sv): (Double, Double)
        switch rotation {
        case .none: (su, sv) = (u, v)
        case .cw90: (su, sv) = (v, 1 - u)
        case .cw180: (su, sv) = (1 - u, 1 - v)
        case .cw270: (su, sv) = (1 - v, u)
        }
        let sx = min(srcW - 1, max(0, Int(su * Double(srcW))))
        let sy = min(srcH - 1, max(0, Int(sv * Double(srcH))))
        out[y * outWidth + x] = src[sy * stride + sx]
      }
    }
    return Data(out)
  }

  // MARK: - cropFrames

  /// Full-quality frames at the given times, cropped to a normalised rectangle
  /// (left, top, right, bottom, each 0...1 of the upright picture), scaled so
  /// the long edge is at most `maxEdge`, as JPEG. These are what is sent.
  private func cropFrames(_ args: [String: Any]) throws -> [FlutterStandardTypedData] {
    let asset = try self.asset(args)
    guard let times = (args["timesMs"] as? [NSNumber])?.map({ $0.doubleValue }), !times.isEmpty else {
      throw VideoToolsError(code: "bad_args", message: "No times")
    }
    let maxEdge = CGFloat((args["maxEdge"] as? NSNumber)?.doubleValue ?? 768)
    let quality = CGFloat((args["quality"] as? NSNumber)?.doubleValue ?? 0.7)
    let rect = args["rect"] as? [String: Any]
    let l = CGFloat((rect?["left"] as? NSNumber)?.doubleValue ?? 0)
    let t = CGFloat((rect?["top"] as? NSNumber)?.doubleValue ?? 0)
    let r = CGFloat((rect?["right"] as? NSNumber)?.doubleValue ?? 1)
    let b = CGFloat((rect?["bottom"] as? NSNumber)?.doubleValue ?? 1)

    let g = generator(asset, maxEdge: nil, exact: true)
    var out: [FlutterStandardTypedData] = []
    for ms in times {
      let time = CMTime(seconds: ms / 1000, preferredTimescale: 600)
      let full = try g.copyCGImage(at: time, actualTime: nil)
      let w = CGFloat(full.width), h = CGFloat(full.height)
      let crop = CGRect(x: l * w, y: t * h, width: max(1, (r - l) * w), height: max(1, (b - t) * h)).integral
      let cropped = full.cropping(to: crop) ?? full

      let cw = CGFloat(cropped.width), ch = CGFloat(cropped.height)
      let scale = min(1, maxEdge / max(cw, ch))
      let target = CGSize(width: (cw * scale).rounded(), height: (ch * scale).rounded())
      let format = UIGraphicsImageRendererFormat.default()
      format.scale = 1
      let image = UIGraphicsImageRenderer(size: target, format: format).image { _ in
        UIImage(cgImage: cropped).draw(in: CGRect(origin: .zero, size: target))
      }
      guard let data = image.jpegData(compressionQuality: quality) else {
        throw VideoToolsError(code: "encode", message: "Could not encode a frame")
      }
      out.append(FlutterStandardTypedData(bytes: data))
    }
    return out
  }

  // MARK: - exportClip

  /// Trim to [startMs, endMs] and compress to at most 720p H.264 in an .mp4.
  /// Completes when the export does; `exportProgress` can be polled meanwhile.
  private func exportClip(_ args: [String: Any], result: @escaping FlutterResult) throws {
    let asset = try self.asset(args)
    guard let outPath = args["outPath"] as? String, let token = args["token"] as? String else {
      throw VideoToolsError(code: "bad_args", message: "Missing output")
    }
    let startMs = (args["startMs"] as? NSNumber)?.doubleValue ?? 0
    let endMs = (args["endMs"] as? NSNumber)?.doubleValue ?? (CMTimeGetSeconds(asset.duration) * 1000)

    guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1280x720) else {
      throw VideoToolsError(code: "export", message: "This video can't be compressed")
    }
    let outURL = URL(fileURLWithPath: outPath)
    try? FileManager.default.removeItem(at: outURL)
    session.outputURL = outURL
    session.outputFileType = .mp4
    session.shouldOptimizeForNetworkUse = true
    session.timeRange = CMTimeRange(
      start: CMTime(seconds: startMs / 1000, preferredTimescale: 600),
      end: CMTime(seconds: endMs / 1000, preferredTimescale: 600))

    lock.lock(); exports[token] = session; lock.unlock()
    session.exportAsynchronously { [weak self] in
      self?.lock.lock(); self?.exports[token] = nil; self?.lock.unlock()
      DispatchQueue.main.async {
        switch session.status {
        case .completed: result(true)
        case .cancelled: result(FlutterError(code: "cancelled", message: "Export cancelled", details: nil))
        default:
          result(FlutterError(
            code: "export", message: session.error?.localizedDescription ?? "Export failed", details: nil))
        }
      }
    }
  }

  private func exportProgress(_ args: [String: Any]) -> Double {
    guard let token = args["token"] as? String else { return 0 }
    lock.lock(); defer { lock.unlock() }
    return Double(exports[token]?.progress ?? 0)
  }

  private func cancelExport(_ args: [String: Any]) {
    guard let token = args["token"] as? String else { return }
    lock.lock(); let session = exports[token]; lock.unlock()
    session?.cancelExport()
  }
}
