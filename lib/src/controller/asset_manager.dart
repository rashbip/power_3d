import 'dart:io';
import 'package:flutter/foundation.dart';
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
    final indexFile = File(p.join(targetDir.path, 'index.html'));

    debugPrint('Power3DAssetManager: appDir=${appDir.path}');
    debugPrint('Power3DAssetManager: targetDir=${targetDir.path}');
    debugPrint(
      'Power3DAssetManager: targetDir exists=${await targetDir.exists()}',
    );
    debugPrint(
      'Power3DAssetManager: indexFile exists=${await indexFile.exists()}',
    );

    final tooltipFile = File(
      p.join(targetDir.path, 'js', 'annotation', 'styles', 'tooltip.js'),
    );

    final babylonFile = File(p.join(targetDir.path, 'babylon', 'babylon.js'));
    final brokenBabylonFile = File(p.join(targetDir.path, 'babylon\\babylon.js'));

    if (!await targetDir.exists()) {
      debugPrint('Power3DAssetManager: Creating dir and unzipping...');
      await targetDir.create(recursive: true);
      await _unzipAssets(targetDir.path);
    } else if (!await indexFile.exists() || 
               !await tooltipFile.exists() || 
               !await babylonFile.exists() ||
               await brokenBabylonFile.exists()) {
      debugPrint(
        'Power3DAssetManager: Assets incomplete or broken (backslash issue detected) - cleaning and re-unzipping...',
      );
      // Clean up the directory to remove files with wrong names/separators
      try {
        await targetDir.delete(recursive: true);
        await targetDir.create(recursive: true);
      } catch (e) {
        debugPrint('Power3DAssetManager: Error cleaning targetDir: $e');
      }
      await _unzipAssets(targetDir.path);
    }

    // Ensure style directory exists for optional plugins
    final styleDir = Directory(
      p.join(targetDir.path, 'js', 'annotation', 'styles'),
    );
    if (!await styleDir.exists()) {
      await styleDir.create(recursive: true);
      debugPrint(
        'Power3DAssetManager: Created styles directory for external plugins.',
      );
    }

    debugPrint('Power3DAssetManager: returning indexFile=${indexFile.path}');
    return indexFile.path;
  }

  static Future<void> _unzipAssets(String targetPath) async {
    try {
      debugPrint('Power3DAssetManager: Loading zip from assets: $_zipPath');
      final ByteData data = await rootBundle.load(_zipPath);
      final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      debugPrint(
        'Power3DAssetManager: Zip loaded, ${bytes.length} bytes. Decoding...',
      );

      final archive = ZipDecoder().decodeBytes(bytes);
      debugPrint('Power3DAssetManager: Archive has ${archive.length} files');

      for (final file in archive) {
        // Normalize separators to forward slashes to ensure directories are 
        // correctly created on Android/Linux.
        final filename = file.name.replaceAll('\\', '/');
        
        if (file.isFile) {
          final fileData = file.content as List<int>;
          final outFile = File(p.join(targetPath, filename));
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(fileData);
        } else {
          await Directory(p.join(targetPath, filename)).create(recursive: true);
        }
      }
      debugPrint('Power3DAssetManager: Unzip complete!');
    } catch (e) {
      debugPrint('Power3DAssetManager: ERROR unzipping: $e');
      rethrow;
    }
  }

  /// Gets the base URL for the unzipped assets.
  static Future<String> getBaseUrl() async {
    final appDir = await getApplicationSupportDirectory();
    return p.join(appDir.path, _libDirName);
  }
}
