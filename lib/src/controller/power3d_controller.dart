import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path/path.dart' as p;
import 'dart:async';
import '../models/power3d_model.dart';

part 'view_extension.dart';
part 'selection_extension.dart';
part 'material_extension.dart';
part 'texture_extension.dart';
part 'animation_extension.dart';
part 'annotation_extension.dart';

/// Controller for programmatically managing the [Power3D] viewer.
///
/// Use this to load models, change materials, capture screenshots,
/// manage lighting, and control the camera.
class Power3DController extends ValueNotifier<Power3DState> {
  /// Creates a new [Power3DController] with initial state.
  Power3DController() : super(Power3DState.initial());

  InAppWebViewController? _webViewController;

  bool _isDisposed = false;
  final Map<String, Completer<String?>> _textureCompleters = {};
  String? _pendingScreenshotPath;
  Function(String partName, bool selected)? _onPartSelectedCallback;
  /// Triggered when an annotation's 'Learn More' or 'Details' button is clicked.
  /// Relayed from the JavaScript bridge.
  Function(String id, Map<String, dynamic> data)? onAnnotationMoreCallback;

  /// A customizable hook for resolving non-string annotation styles.
  static Future<void> Function(Power3DController controller, dynamic style)? globalStyleResolver;

  Future<void> Function(dynamic style)? _onResolveStyle;
  Future<void> Function(dynamic style)? get onResolveStyle => _onResolveStyle;
  set onResolveStyle(Future<void> Function(dynamic style)? hook) {
    if (_onResolveStyle == hook) return;
    _onResolveStyle = hook;
    
    // If we just got a hook and there's a pending non-string style (enum/object), resolve it!
    if (hook != null && value.annotationStyle != null && value.annotationStyle is! String) {
      setAnnotationStyle(value.annotationStyle);
    }
  }

  /// Internal method to set the WebView controller.
  /// This should only be used by the Power3D widget.
  @internal
  void setWebViewController(InAppWebViewController controller) {
    _webViewController = controller;
  }

  /// Internal initialization logic that synchronizes the default [Power3DState] 
  /// with the underlying Babylon.js engine once the WebView is ready.
  /// 
  /// This applies initial lighting, materials, shading modes, and 
  /// selection configurations.
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

    // Apply initial annotations
    if (value.annotations != null) {
      debugPrint(
        'Power3D: initialize - applying ${value.annotations!.length} chars of annotation data',
      );
      setAnnotations(value.annotations!);
    }
    if (value.annotationStyle != null) {
      setAnnotationStyle(value.annotationStyle!, force: true);
    }

    // Sync camera position
    unawaited(
      _webViewController?.evaluateJavascript(
        source:
            'setCameraPosition(${value.cameraAlpha}, ${value.cameraBeta}, ${value.cameraRadius})',
      ),
    );

    // Apply initial zoom sensitivity
    unawaited(updateZoomSensitivity(value.zoomSensitivity));
  }

  /// Loads a 3D model into the scene.
  /// 
  /// The [data] parameter specifies the source (Asset, Network, or File).
  /// For large models, this method handles Base64 encoding for local files
  /// and direct URL loading for network sources.
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

      await _webViewController!.evaluateJavascript(
        source: 'loadModel("$encodedData", "$fileName", "$type")',
      );
    } catch (e) {
      value = value.copyWith(
        status: Power3DStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// The primary communication bridge that receives raw JSON messages 
  /// from the JavaScript engine and translates them into [Power3DState] updates.
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
          // Sync camera position
          unawaited(
            _webViewController?.evaluateJavascript(
              source:
                  'setCameraPosition(${value.cameraAlpha}, ${value.cameraBeta}, ${value.cameraRadius})',
            ),
          );
          // Initialize animations
          unawaited(
            _webViewController?.evaluateJavascript(source: 'initAnimations()'),
          );
        } else if (data['message'] == 'reset') {
          value = value.copyWith(
            selectedParts: [],
            hiddenParts: [],
            boundingBoxParts: [],
          );
          // Refresh animations list to sync isPlaying status
          unawaited(getAnimationsList());
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
      } else if (data['type'] == 'textureData') {
        final id = data['uniqueId'].toString();
        final base64Data = data['data'];
        if (_textureCompleters.containsKey(id)) {
          _textureCompleters[id]!.complete(base64Data);
          _textureCompleters.remove(id);
        }
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
      } else if (data['type'] == 'animationsList') {
        final List<Power3DAnimation> animations = (data['animations'] as List)
            .map((e) => Power3DAnimation.fromJson(e))
            .toList();
        value = value.copyWith(animations: animations);
      } else if (data['type'] == 'animationStatus') {
        final updatedAnim = Power3DAnimation.fromJson(data['animation']);
        final newAnimations = value.animations.map((a) {
          return a.name == updatedAnim.name ? updatedAnim : a;
        }).toList();
        value = value.copyWith(animations: newAnimations);
      } else if (data['type'] == 'annotationMore') {
        final id = data['id'].toString();
        final Map<String, dynamic> annotationData = Map<String, dynamic>.from(
          data['data'],
        );
        onAnnotationMoreCallback?.call(id, annotationData);
      }
    } catch (e) {
      // Ignore parse errors from JS
    }
  }

  /// Internal helper to update value safely checking disposal status.
  @override
  set value(Power3DState newValue) {
    if (_isDisposed) return;
    super.value = newValue;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _webViewController = null;
    for (var completer in _textureCompleters.values) {
      if (!completer.isCompleted) completer.complete(null);
    }
    _textureCompleters.clear();
    super.dispose();
  }

  /// Gets the data for a specific annotation by its [id].
  Future<Map<String, dynamic>?> getAnnotationData(String id) async {
    if (!value.isInitialized || _webViewController == null) return null;
    try {
      final String? result = await _webViewController!.evaluateJavascript(
        source: 'getAnnotationData("$id")',
      );
      if (result != null && result.isNotEmpty && result != "null") {
        return jsonDecode(result);
      }
    } catch (e) {
      debugPrint('Power3DController: Error getting annotation data: $e');
    }
    return null;
  }
}
