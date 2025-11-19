import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Data source for file storage operations
abstract class FileStorageDataSource {
  Future<String> saveImageFile(String sourcePath);
  Future<void> deleteImageFile(String imagePath);
  Future<bool> imageFileExists(String imagePath);
}

class FileStorageDataSourceImpl implements FileStorageDataSource {
  static const String _imagesDirectory = 'fitness_images';

  Future<Directory> get _imagesDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(path.join(appDir.path, _imagesDirectory));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  @override
  Future<String> saveImageFile(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Source file does not exist: $sourcePath');
    }

    final imagesDir = await _imagesDir;
    final fileName = path.basename(sourcePath);
    // Add timestamp to ensure uniqueness
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueFileName = '${timestamp}_$fileName';
    final destinationPath = path.join(imagesDir.path, uniqueFileName);

    // Copy the file
    await sourceFile.copy(destinationPath);

    return destinationPath;
  }

  @override
  Future<void> deleteImageFile(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<bool> imageFileExists(String imagePath) async {
    final file = File(imagePath);
    return await file.exists();
  }
}

