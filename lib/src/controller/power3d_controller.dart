import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path/path.dart' as p;
import '../models/power3d_model.dart';

/// Controller for programmatically managing the [Power3D] viewer.
///
/// Use this to load models, change materials, capture screenshots,
/// manage lighting, and control the camera.
class Power3DController extends ValueNotifier<Power3DState> {
  /// Creates a new [Power3DController] with initial state.
  Power3DController() : super(Power3DState.initial());

  WebViewController? _webViewController;

  /// Internal method to set the WebView controller.
  /// This should only be used by the Power3D widget.
  @internal
  void setWebViewController(WebViewController controller) {
    _webViewController = controller;
  }

  /// Initializes the controller and applies initial state to the scene.
  ///
  /// This is called automatically by the [Power3D] widget.
  void initialize() {
    if (value.isInitialized) return;
    value = value.copyWith(isInitialized: true);

    // Apply initial lighting
    setLights(value.lights);
    updateSceneProcessing(exposure: value.exposure, contrast: value.contrast);

    // Apply initial materials/shading
    setShadingMode(value.shadingMode);
    if (value.globalMaterial != null) {
      setGlobalMaterial(value.globalMaterial!);
    }

    // Apply selection configuration
    updateSelectionConfig(value.selectionConfig);
  }

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
  Future<void> setLights(List<LightingConfig> lights) async {
    value = value.copyWith(lights: lights);

    if (_webViewController == null) return;

    final List<Map<String, dynamic>> jsConfigs = lights.map((config) {
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

  /// Loads a 3D model from the specified [data] source.
  ///
  /// Supports assets, network URLs, and local files.
  Future<void> loadModel(Power3DData data) async {
    if (!value.isInitialized || _webViewController == null) return;

    value = value.copyWith(
      status: Power3DStatus.loading,
      currentModelName: data.fileName ?? p.basename(data.path),
    );

    try {
      String? encodedData;
      String type = 'url';
      String fileName = data.fileName ?? p.basename(data.path);

      switch (data.source) {
        case Power3DSource.asset:
          final byteData = await rootBundle.load(data.path);
          final bytes = byteData.buffer.asUint8List();
          encodedData = base64Encode(bytes);
          type = 'base64';
          break;
        case Power3DSource.network:
          encodedData = data.path;
          type = 'url';
          break;
        case Power3DSource.file:
          final file = File(data.path);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            encodedData = base64Encode(bytes);
            type = 'base64';
          } else {
            throw Exception("File not found: ${data.path}");
          }
          break;
      }

      await _webViewController!.runJavaScript(
        'loadModel("$encodedData", "$fileName", "$type")',
      );
    } catch (e) {
      value = value.copyWith(
        status: Power3DStatus.error,
        errorMessage: e.toString(),
      );
    }
  }


  /// Resets the camera to its default position and orientation.
  Future<void> resetView() async {
    await _webViewController?.runJavaScript('resetView()');
  }

  /// Updates the auto-rotation behavior of the camera.
  ///
  /// [enabled]: Whether auto-rotation is active.
  /// [speed]: Rotation speed multiplier (default 1.0).
  /// [direction]: Clockwise or Counter-Clockwise rotation.
  /// [stopAfter]: Optional duration after which to automatically stop rotation.
  Future<void> updateRotation({
    bool? enabled,
    double? speed,
    RotationDirection? direction,
    Duration? stopAfter,
  }) async {
    final newState = value.copyWith(
      autoRotate: enabled,
      rotationSpeed: speed,
      rotationDirection: direction,
      rotationStopAfter: stopAfter,
    );
    value = newState;

    final dirStr = newState.rotationDirection == RotationDirection.clockwise
        ? 'clockwise'
        : 'counterClockwise';
    final stopMs = newState.rotationStopAfter?.inMilliseconds;

    await _webViewController?.runJavaScript(
      'toggleAutoRotate(${newState.autoRotate}, ${newState.rotationSpeed}, "$dirStr", $stopMs)',
    );
  }

  @Deprecated('Use updateRotation instead')
  Future<void> toggleAutoRotate(bool enabled) async {
    await updateRotation(enabled: enabled);
  }

  /// Locks or unlocks the object's position (panning).
  /// If [locked], the object can be rotated and zoomed but not moved.
  Future<void> setLockPosition(bool locked) async {
    value = value.copyWith(isPositionLocked: locked);
    await _webViewController?.runJavaScript('setLockPosition($locked)');
  }

  /// Updates the camera zoom limits and behavior.
  ///
  /// [enabled]: Whether zooming interaction is allowed.
  /// [min]: Minimum zoom distance allowed.
  /// [max]: Maximum zoom distance allowed.
  Future<void> updateZoom({bool? enabled, double? min, double? max}) async {
    value = value.copyWith(enableZoom: enabled, minZoom: min, maxZoom: max);
    await _webViewController?.runJavaScript(
      'updateZoom(${value.enableZoom}, ${value.minZoom}, ${value.maxZoom})',
    );
  }

  String? _pendingScreenshotPath;

  /// Takes a screenshot of the current 3D view and saves it to [savePath].
  /// Note: [savePath] must include the file name and extension (e.g. 'path/to/shot.png').
  Future<void> takeScreenshot(String savePath) async {
    _pendingScreenshotPath = savePath;
    await _webViewController?.runJavaScript('takeScreenshot()');
  }

  /// Internal message handler for communication from the JavaScript layer.
  @internal
  void handleWebViewMessage(String message) {
    try {
      final data = jsonDecode(message);
      if (data['type'] == 'status') {
        if (data['message'] == 'loaded') {
          value = value.copyWith(status: Power3DStatus.loaded);
          // Re-apply materials and shading after model load
          setShadingMode(value.shadingMode);
          if (value.globalMaterial != null) {
            setGlobalMaterial(value.globalMaterial!);
          }
          // Re-apply selection configuration
          updateSelectionConfig(value.selectionConfig);
        } else if (data['message'] == 'loading') {
          value = value.copyWith(status: Power3DStatus.loading);
        }
      } else if (data['type'] == 'statusChange') {
        // Internal status updates from JS (e.g. rotation stopped)
        final key = data['key'];
        final val = data['value'];
        if (key == 'autoRotate') {
          value = value.copyWith(autoRotate: val);
        }
      } else if (data['type'] == 'error') {
        value = value.copyWith(
          status: Power3DStatus.error,
          errorMessage: data['message'],
        );
      } else if (data['type'] == 'camera') {
        value = value.copyWith(
          cameraAlpha: (data['alpha'] as num).toDouble(),
          cameraBeta: (data['beta'] as num).toDouble(),
          cameraRadius: (data['radius'] as num).toDouble(),
        );
      } else if (data['type'] == 'screenshot') {
        final String base64Data = data['data'];
        value = value.copyWith(lastScreenshot: base64Data);

        if (_pendingScreenshotPath != null) {
          _saveScreenshotToFile(base64Data, _pendingScreenshotPath!);
          _pendingScreenshotPath = null;
        }
      } else if (data['type'] == 'partSelected') {
        final String partName = data['partName'];
        final bool selected = data['selected'];

        _onPartSelectedCallback?.call(partName, selected);

        final newSelected = List<String>.from(value.selectedParts);
        if (selected) {
          if (!newSelected.contains(partName)) newSelected.add(partName);
        } else {
          newSelected.remove(partName);
        }
        value = value.copyWith(selectedParts: newSelected);
      } else if (data['type'] == 'partsList') {
        final List<String> parts = (data['parts'] as List).cast<String>();
        value = value.copyWith(availableParts: parts);
      }
    } catch (e) {
      // Ignore parse errors from JS
    }
  }

  Future<void> _saveScreenshotToFile(String base64Data, String path) async {
    try {
      final String data = base64Data.contains(',')
          ? base64Data.split(',')[1]
          : base64Data;
      final bytes = base64Decode(data);
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      debugPrint('Screenshot saved to: $path');
    } catch (e) {
      debugPrint('Failed to save screenshot: $e');
    }
  }

  // ===== Selection & Object Parts =====

  Function(String partName, bool selected)? _onPartSelectedCallback;

  /// Registers a callback for part selection events.
  ///
  /// The callback is triggered whenever a part is selected or deselected.
  void onPartSelected(Function(String partName, bool selected) callback) {
    _onPartSelectedCallback = callback;
  }

  /// Retrieves the list of available mesh part names from the currently loaded model.
  Future<List<String>> getPartsList() async {
    if (_webViewController == null) return [];

    try {
      final result = await _webViewController!.runJavaScriptReturningResult(
        'JSON.stringify(getPartsList())',
      );
      final partsJson = result.toString().replaceAll('"', '');
      if (partsJson == 'null' || partsJson.isEmpty) return [];

      final parts = (jsonDecode(partsJson) as List).cast<String>();
      value = value.copyWith(availableParts: parts);
      return parts;
    } catch (e) {
      debugPrint('Failed to get parts list: $e');
      return [];
    }
  }

  /// Focuses and selects a specific part by its mesh [partName].
  Future<void> selectPart(String partName) async {
    if (_webViewController == null) return;

    await _webViewController!.runJavaScript('selectPart("$partName")');

    final newSelected = List<String>.from(value.selectedParts);
    if (!newSelected.contains(partName)) {
      if (!value.selectionConfig.multipleSelection) {
        newSelected.clear();
      }
      newSelected.add(partName);
      value = value.copyWith(selectedParts: newSelected);
    }
  }

  /// Deselects a specific part by its mesh [partName].
  Future<void> unselectPart(String partName) async {
    if (_webViewController == null) return;

    await _webViewController!.runJavaScript('unselectPart("$partName")');

    final newSelected = List<String>.from(value.selectedParts);
    newSelected.remove(partName);
    value = value.copyWith(selectedParts: newSelected);
  }

  /// Clears all currently selected model parts.
  Future<void> clearSelection() async {
    if (_webViewController == null) return;

    await _webViewController!.runJavaScript('clearSelection()');
    value = value.copyWith(selectedParts: []);
  }

  /// Updates the global selection configuration, including styles and behavior.
  Future<void> updateSelectionConfig(SelectionConfig config) async {
    value = value.copyWith(selectionConfig: config);

    if (_webViewController == null) return;

    final Map<String, dynamic> jsConfig = {
      'enabled': config.enabled,
      'multipleSelection': config.multipleSelection,
      'scaleSelection': config.scaleSelection,
      'selectionShift': {
        'x': config.selectionShift?.x ?? 0,
        'y': config.selectionShift?.y ?? 0,
        'z': config.selectionShift?.z ?? 0,
      },
    };

    if (config.selectionStyle != null) {
      jsConfig['selectionStyle'] = {
        if (config.selectionStyle!.highlightColor != null)
          'highlightColor':
              '#${config.selectionStyle!.highlightColor!.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        if (config.selectionStyle!.outlineColor != null)
          'outlineColor':
              '#${config.selectionStyle!.outlineColor!.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        if (config.selectionStyle!.outlineWidth != null)
          'outlineWidth': config.selectionStyle!.outlineWidth,
      };
    }

    if (config.unselectedStyle != null) {
      jsConfig['unselectedStyle'] = {
        if (config.unselectedStyle!.highlightColor != null)
          'highlightColor':
              '#${config.unselectedStyle!.highlightColor!.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        if (config.unselectedStyle!.outlineColor != null)
          'outlineColor':
              '#${config.unselectedStyle!.outlineColor!.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        if (config.unselectedStyle!.outlineWidth != null)
          'outlineWidth': config.unselectedStyle!.outlineWidth,
      };
    }

    await _webViewController!.runJavaScript(
      'enableSelectionMode(${jsonEncode(jsConfig)})',
    );
  }

  // ===== Hierarchy \u0026 Node Extras =====

  /// Retrieves the hierarchical structure of parts in the model.
  ///
  /// [useCategorization]: If true, uses naming conventions like "Category.PartName".
  /// If false (default), uses the GLTF scene graph parent-child relationships.
  Future<List<dynamic>> getPartsHierarchy({
    bool useCategorization = false,
  }) async {
    if (_webViewController == null) return [];

    try {
      final result = await _webViewController!.runJavaScriptReturningResult(
        'JSON.stringify(getPartsHierarchy($useCategorization))',
      );

      String resultString = result.toString();
      // WebView results are often wrapped in extra quotes and escaped
      if (resultString.startsWith('"') && resultString.endsWith('"')) {
        try {
          // Decode the outer string wrapper
          final decoded = jsonDecode(resultString);
          resultString = decoded.toString();
        } catch (e) {
          // If decoding fails, fallback to removing leading/trailing quotes if they exist
          resultString = resultString
              .substring(1, resultString.length - 1)
              .replaceAll('\\"', '"');
        }
      }

      if (resultString == 'null' || resultString.isEmpty) return [];

      final hierarchy = jsonDecode(resultString) as List<dynamic>;
      value = value.copyWith(partsHierarchy: hierarchy);
      return hierarchy;
    } catch (e) {
      debugPrint('Failed to get parts hierarchy: $e');
      return [];
    }
  }

  /// Gets extras data from a specific node/part (label, description, category, etc.).
  ///
  /// Returns a map containing metadata and GLTF extras if available.
  Future<Map<String, dynamic>> getNodeExtras(String partName) async {
    if (_webViewController == null) return {};

    try {
      final result = await _webViewController!.runJavaScriptReturningResult(
        'JSON.stringify(getNodeExtras("$partName"))',
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

      if (resultString == 'null' || resultString.isEmpty) return {};

      return jsonDecode(resultString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Failed to get node extras: $e');
      return {};
    }
  }

  // ===== Visibility Controls =====

  /// Hides the specified parts from view.
  Future<void> hideParts(List<String> partNames) async {
    if (_webViewController == null) return;

    await _webViewController!.runJavaScript(
      'hideParts(${jsonEncode(partNames)})',
    );

    final newHidden = List<String>.from(value.hiddenParts);
    for (final name in partNames) {
      if (!newHidden.contains(name)) newHidden.add(name);
    }
    value = value.copyWith(hiddenParts: newHidden);
  }

  /// Shows the specified parts (makes them visible).
  Future<void> showParts(List<String> partNames) async {
    if (_webViewController == null) return;

    await _webViewController!.runJavaScript(
      'showParts(${jsonEncode(partNames)})',
    );

    final newHidden = List<String>.from(value.hiddenParts);
    newHidden.removeWhere((name) => partNames.contains(name));
    value = value.copyWith(hiddenParts: newHidden);
  }

  /// Hides all currently selected parts.
  Future<void> hideSelected() async {
    if (_webViewController == null) return;

    await _webViewController!.runJavaScript('hideSelected()');

    final newHidden = List<String>.from(value.hiddenParts);
    for (final name in value.selectedParts) {
      if (!newHidden.contains(name)) newHidden.add(name);
    }
    value = value.copyWith(hiddenParts: newHidden);
  }

  /// Hides all parts except the currently selected ones.
  Future<void> hideUnselected() async {
    if (_webViewController == null) return;

    await _webViewController!.runJavaScript('hideUnselected()');

    final unselected = value.availableParts
        .where((name) => !value.selectedParts.contains(name))
        .toList();
    value = value.copyWith(hiddenParts: unselected);
  }

  /// Shows all parts (unhides everything).
  Future<void> unhideAll() async {
    if (_webViewController == null) return;

    await _webViewController!.runJavaScript('unhideAll()');
    value = value.copyWith(hiddenParts: []);
  }

  // ===== Bounding Box Visualization =====

  /// Shows bounding boxes around the specified parts.
  ///
  /// [partNames]: List of part names to show bounding boxes for.
  /// [config]: Optional configuration for appearance (color, line width, etc.).
  Future<void> showBoundingBox(
    List<String> partNames, {
    BoundingBoxConfig? config,
  }) async {
    if (_webViewController == null) return;

    config ??= const BoundingBoxConfig();

    final String colorHex =
        '#${config.color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

    final Map<String, dynamic> jsConfig = {
      'color': colorHex,
      'lineWidth': config.lineWidth,
      'style': config.style.name,
    };

    await _webViewController!.runJavaScript(
      'showBoundingBox(${jsonEncode(partNames)}, ${jsonEncode(jsConfig)})',
    );

    final newBoxes = List<String>.from(value.boundingBoxParts);
    for (final name in partNames) {
      if (!newBoxes.contains(name)) newBoxes.add(name);
    }
    value = value.copyWith(boundingBoxParts: newBoxes);
  }

  /// Hides bounding boxes for the specified parts.
  Future<void> hideBoundingBox(List<String> partNames) async {
    if (_webViewController == null) return;

    await _webViewController!.runJavaScript(
      'hideBoundingBox(${jsonEncode(partNames)})',
    );

    final newBoxes = List<String>.from(value.boundingBoxParts);
    newBoxes.removeWhere((name) => partNames.contains(name));
    value = value.copyWith(boundingBoxParts: newBoxes);
  }

  // ===== Material Modes for Selection =====

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

  @override
  void dispose() {
    _webViewController = null;
    super.dispose();
  }
}
