part of 'power3d_controller.dart';

/// Camera and View extension for [Power3DController].
extension ViewExtension on Power3DController {
  /// Resets the camera to its default position and orientation.
  Future<void> resetView() async {
    await _webViewController?.evaluateJavascript(source: 'resetView()');
  }

  /// Resets the entire scene to its initial state.
  /// Stops animations, clears selections, unhides parts, and resets camera.
  Future<void> resetScene() async {
    await _webViewController?.evaluateJavascript(source: 'resetScene()');
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

    await _webViewController?.evaluateJavascript(
      source:
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
    await _webViewController?.evaluateJavascript(
      source: 'setLockPosition($locked)',
    );
  }

  /// Updates the camera zoom limits and behavior.
  ///
  /// [enabled]: Whether zooming interaction is allowed.
  /// [min]: Minimum zoom distance allowed.
  /// [max]: Maximum zoom distance allowed.
  /// [sensitivity]: How sensitive the zoom is (0.0 = fastest, 1.0 = slowest).
  Future<void> updateZoom({
    bool? enabled,
    double? min,
    double? max,
    double? sensitivity,
  }) async {
    value = value.copyWith(
      enableZoom: enabled,
      minZoom: min,
      maxZoom: max,
      zoomSensitivity: sensitivity,
    );
    await _webViewController?.evaluateJavascript(
      source:
          'updateZoom(${value.enableZoom}, ${value.minZoom}, ${value.maxZoom})',
    );
    if (sensitivity != null) {
      await updateZoomSensitivity(sensitivity);
    }
  }

  /// Controls how sensitive the pinch-to-zoom and scroll-wheel interactions are.
  ///
  /// [sensitivity]: A value from 0.0 (fastest) to 1.0 (slowest). Default is 0.5.
  Future<void> updateZoomSensitivity(double sensitivity) async {
    final clamped = sensitivity.clamp(0.0, 1.0);
    value = value.copyWith(zoomSensitivity: clamped);
    await _webViewController?.evaluateJavascript(
      source: 'updateZoomSensitivity($clamped)',
    );
  }

  /// Takes a screenshot of the current 3D view and saves it to [savePath].
  /// Note: [savePath] must include the file name and extension (e.g. 'path/to/shot.png').
  Future<void> takeScreenshot(String savePath) async {
    _pendingScreenshotPath = savePath;
    await _webViewController?.evaluateJavascript(source: 'takeScreenshot()');
  }

  /// Sets the camera position and orientation.
  Future<void> setCameraPosition({
    double? alpha,
    double? beta,
    double? radius,
  }) async {
    final newState = value.copyWith(
      cameraAlpha: alpha,
      cameraBeta: beta,
      cameraRadius: radius,
    );
    value = newState;
    await _webViewController?.evaluateJavascript(
      source:
          'setCameraPosition(${newState.cameraAlpha}, ${newState.cameraBeta}, ${newState.cameraRadius})',
    );
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
}
