import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path/path.dart' as p;
import '../models/power3d_model.dart';

class Power3DController extends ValueNotifier<Power3DState> {
  Power3DController() : super(Power3DState.initial());

  WebViewController? _webViewController;

  /// Internal method to set the WebView controller.
  /// This should only be used by the Power3D widget.
  @internal
  void setWebViewController(WebViewController controller) {
    _webViewController = controller;
  }

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
  }

  /// Updates the shading mode of the scene.
  Future<void> setShadingMode(ShadingMode mode) async {
    value = value.copyWith(shadingMode: mode);
    if (_webViewController == null) return;
    await _webViewController!.runJavaScript(
      'updateShadingMode("${mode.name}")',
    );
  }

  /// Updates the global material properties for all meshes in the scene.
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
      'color': ?colorHex,
      'metallic': ?config.metallic,
      'roughness': ?config.roughness,
      'alpha': ?config.alpha,
      'emissiveColor': ?emissiveHex,
      'doubleSided': ?config.doubleSided,
    };

    await _webViewController!.runJavaScript(
      'updateGlobalMaterial(${jsonEncode(jsConfig)})',
    );
  }

  /// Updates the list of lights in the scene.
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


  Future<void> resetView() async {
    await _webViewController?.runJavaScript('resetView()');
  }

  /// Updates the auto-rotation behavior.
  /// [enabled]: Whether auto-rotation is active.
  /// [speed]: Rotation speed (default 1.0).
  /// [direction]: Clockwise or Counter-Clockwise.
  /// [stopAfter]: Optional duration after which to stop rotation.
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

  /// Updates zoom limits and behavior.
  /// [enabled]: Whether zooming is allowed.
  /// [min]: Minimum zoom distance.
  /// [max]: Maximum zoom distance.
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

  /// Register a callback for part selection events
  void onPartSelected(Function(String partName, bool selected) callback) {
    _onPartSelectedCallback = callback;
  }

  /// Get list of available parts/meshes in the loaded model
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

  /// Select a specific part by name
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

  /// Unselect a specific part by name
  Future<void> unselectPart(String partName) async {
    if (_webViewController == null) return;

    await _webViewController!.runJavaScript('unselectPart("$partName")');

    final newSelected = List<String>.from(value.selectedParts);
    newSelected.remove(partName);
    value = value.copyWith(selectedParts: newSelected);
  }

  /// Clear all selections
  Future<void> clearSelection() async {
    if (_webViewController == null) return;

    await _webViewController!.runJavaScript('clearSelection()');
    value = value.copyWith(selectedParts: []);
  }

  /// Update selection configuration
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

  @override
  void dispose() {
    _webViewController = null;
    super.dispose();
  }
}
