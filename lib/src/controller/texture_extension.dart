part of 'power3d_controller.dart';

/// Texture Management extension for [Power3DController].
extension TextureExtension on Power3DController {
  /// Retrieves the list of all textures in the current scene.
  Future<List<Power3DTexture>> getTexturesList() async {
    if (_webViewController == null) return [];

    try {
      final result = await _webViewController!.runJavaScriptReturningResult(
        'JSON.stringify(getTexturesList())',
      );

      String resultString = result.toString();
      if (resultString.startsWith('"') && resultString.endsWith('"')) {
        try {
          final decoded = jsonDecode(resultString);
          resultString = decoded.toString();
        } catch (e) {
          resultString = resultString
              .substring(1, resultString.length - 1)
              .replaceAll('\\"', '"');
        }
      }

      if (resultString == 'null' || resultString.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(resultString);
      final List<Power3DTexture> textures =
          jsonList.map((j) => Power3DTexture.fromJson(j)).toList();

      value = value.copyWith(textures: textures);
      return textures;
    } catch (e) {
      debugPrint('Failed to get textures list: $e');
      return [];
    }
  }

  /// Gets the base64 encoded image data for a specific texture.
  Future<String?> getTextureData(String textureId) async {
    if (_webViewController == null) return null;

    final completer = Completer<String?>();
    _textureCompleters[textureId] = completer;

    try {
      await _webViewController!.runJavaScript(
        'requestTextureData("$textureId")',
      );

      // Wait up to 10 seconds for the texture data
      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _textureCompleters.remove(textureId);
          return null;
        },
      );
    } catch (e) {
      _textureCompleters.remove(textureId);
      debugPrint('Failed to get texture data: $e');
      return null;
    }
  }

  /// Updates properties of a specific texture.
  Future<void> updateTexture(String textureId, TextureUpdate config) async {
    if (_webViewController == null) return;

    await _webViewController!.runJavaScript(
      'updateTextureProperty("$textureId", ${jsonEncode(config.toJson())})',
    );

    // Update local state if the texture exists in the list
    final newTextures = value.textures.map((t) {
      if (t.uniqueId == textureId) {
        return Power3DTexture(
          uniqueId: t.uniqueId,
          name: t.name,
          className: t.className,
          isRenderTarget: t.isRenderTarget,
          level: config.level ?? t.level,
          url: t.url,
          uScale: config.uScale ?? t.uScale,
          vScale: config.vScale ?? t.vScale,
          uOffset: config.uOffset ?? t.uOffset,
          vOffset: config.vOffset ?? t.vOffset,
        );
      }
      return t;
    }).toList();

    value = value.copyWith(textures: newTextures);
  }

  /// Exports a texture to a local file.
  Future<String?> exportTexture(String textureId, String path) async {
    final base64Data = await getTextureData(textureId);
    if (base64Data == null) return null;

    try {
      final String cleanData = base64Data.contains(',')
          ? base64Data.split(',')[1]
          : base64Data;
      final bytes = base64Decode(cleanData);
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      return path;
    } catch (e) {
      debugPrint('Failed to export texture: $e');
      return null;
    }
  }
}
