part of 'power3d_controller.dart';

/// Materials and Lighting extension for [Power3DController].
extension MaterialExtension on Power3DController {
  /// Updates the shading and rendering mode of the 3D scene (e.g., [ShadingMode.wireframe]).
  Future<void> setShadingMode(ShadingMode mode) async {
    value = value.copyWith(shadingMode: mode);
    if (_webViewController == null) return;
    await _webViewController!.runJavaScript(
      'updateShadingMode("${mode.name}")',
    );
  }

  /// Updates the global material properties applied to the entire model.
  ///
  /// This can be used to override colors, metallic/roughness properties, and alpha.
  Future<void> setGlobalMaterial(MaterialConfig config) async {
    value = value.copyWith(globalMaterial: config);
    if (_webViewController == null) return;

    final String? colorHex = config.color != null
        ? '#${config.color!.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}'
        : null;
    final String? emissiveHex = config.emissiveColor != null
        ? '#${config.emissiveColor!.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}'
        : null;

    final Map<String, dynamic> jsConfig = {
      'color': colorHex,
      'metallic': config.metallic,
      'roughness': config.roughness,
      'alpha': config.alpha,
      'emissiveColor': emissiveHex,
      'doubleSided': config.doubleSided,
    };

    await _webViewController!.runJavaScript(
      'updateGlobalMaterial(${jsonEncode(jsConfig)})',
    );
  }

  /// Sets the lighting configuration for the scene.
  ///
  /// Replaces any existing lights with the provided list of [LightingConfig]s.
  Future<void> setLights(List<LightingConfig> lightsList) async {
    value = value.copyWith(lights: lightsList);

    if (_webViewController == null) return;

    final List<Map<String, dynamic>> jsConfigs = lightsList.map((config) {
      final colorHex =
          '#${config.color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
      final Map<String, dynamic> jsConfig = {
        'type': config.type.name,
        'intensity': config.intensity,
        'color': colorHex,
        'castShadows': config.castShadows,
        'shadowBlur': config.shadowBlur,
      };

      if (config.direction != null) {
        jsConfig['direction'] = {
          'x': config.direction!.x,
          'y': config.direction!.y,
        };
      }
      return jsConfig;
    }).toList();

    await _webViewController!.runJavaScript(
      'updateLighting(${jsonEncode(jsConfigs)})',
    );
  }

  @Deprecated('Use setLights instead')
  Future<void> updateLighting(LightingConfig config) async {
    await setLights([config]);
  }

  /// Updates the scene-level image processing (exposure and contrast).
  ///
  /// [exposure]: The level of light exposure in the scene.
  /// [contrast]: The difference between light and dark areas.
  Future<void> updateSceneProcessing({
    double? exposure,
    double? contrast,
  }) async {
    value = value.copyWith(exposure: exposure, contrast: contrast);

    if (_webViewController == null) return;

    await _webViewController!.runJavaScript(
      'updateSceneProcessing(${value.exposure}, ${value.contrast})',
    );
  }

  /// Applies a material/shading mode to selected or unselected parts.
  ///
  /// [mode]: The shading mode to apply (wireframe, xray, etc.).
  /// [applyToSelected]: If true, applies to selected parts; if false, to unselected.
  Future<void> applyMaterialModeToSelection(
    ShadingMode mode, {
    bool applyToSelected = true,
  }) async {
    if (_webViewController == null) return;

    await _webViewController!.runJavaScript(
      'applyMaterialModeToSelection("${mode.name}", $applyToSelected)',
    );
  }
}
