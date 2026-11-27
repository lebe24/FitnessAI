import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum ShareOutcome { shared, dismissed, unavailable }

/// Hands an image to the phone's share menu.
abstract class ImageSharer {
  /// [origin] is where the share menu points from; iPad requires it.
  Future<ShareOutcome> share(Uint8List png, {required String fileName, Rect? origin});
}

class SystemImageSharer implements ImageSharer {
  const SystemImageSharer();

  @override
  Future<ShareOutcome> share(Uint8List png, {required String fileName, Rect? origin}) async {
    // Written to the temporary folder, which the system clears.
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(png, flush: true);
    final result = await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'image/png')],
      sharePositionOrigin: origin,
    ));
    return switch (result.status) {
      ShareResultStatus.success => ShareOutcome.shared,
      ShareResultStatus.dismissed => ShareOutcome.dismissed,
      ShareResultStatus.unavailable => ShareOutcome.unavailable,
    };
  }
}
