import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  @override
  void dispose() {
    _webViewController = null;
    super.dispose();
  }
}
