import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';

class Power3DAssetManager {
  static const String _zipPath = 'packages/power3d/assets/power3d_assets.zip';
  static const String _libDirName = 'power3d_assets';

  /// Ensures assets are unzipped in the application directory.
  /// Returns the path to the index.html file.
  static Future<String> prepareAssets() async {
    final appDir = await getApplicationSupportDirectory();
    final targetDir = Directory(p.join(appDir.path, _libDirName));

    // Check if index.html exists, if so, assume unzipped (or check version in future)
    final indexFile = File(p.join(targetDir.path, 'index.html'));
    
    // For now, if directory exists, we skip unzipping. 
    // In production, we should probably check a version file.
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
      await _unzipAssets(targetDir.path);
    } else if (!await indexFile.exists()) {
      // Emergency re-unzip if directory exists but index is missing
      await _unzipAssets(targetDir.path);
    }

    return indexFile.path;
  }

  static Future<void> _unzipAssets(String targetPath) async {
    try {
      final ByteData data = await rootBundle.load(_zipPath);
      final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final outFile = File(p.join(targetPath, filename));
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(data);
        } else {
          await Directory(p.join(targetPath, filename)).create(recursive: true);
        }
      }
    } catch (e) {
      print('Error unzipping Power3D assets: $e');
      rethrow;
    }
  }

  /// Gets the base URL for the unzipped assets.
  static Future<String> getBaseUrl() async {
    final appDir = await getApplicationSupportDirectory();
    return p.join(appDir.path, _libDirName);
  }
}
