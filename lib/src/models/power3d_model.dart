enum Power3DSource {
  asset,
  network,
  file,
}

enum RotationDirection { clockwise, counterClockwise }

class Power3DData {
  final String path;
  final Power3DSource source;
  final String? fileName;

  const Power3DData({
    required this.path,
    required this.source,
    this.fileName,
  });

  String get extension => path.split('.').last.toLowerCase();
}

enum Power3DStatus {
  initial,
  loading,
  loaded,
  error,
}

class Power3DState {
  final Power3DStatus status;
  final String? errorMessage;
  final String? currentModelName;
  final bool isInitialized;

  // Rotation Controls
  final bool autoRotate;
  final double rotationSpeed;
  final RotationDirection rotationDirection;
  final Duration? rotationStopAfter;

  // Zoom Controls
  final bool enableZoom;
  final double maxZoom;
  final double minZoom;

  // Position Controls
  final bool isPositionLocked;

  // Camera Telemetry
  final double cameraAlpha;
  final double cameraBeta;
  final double cameraRadius;

  // Skybox Properties (Native Babylon.js PhotoDome)
  final String? skyboxPath;
  final Power3DSource? skyboxSource;

  final String? lastScreenshot;

  const Power3DState({
    required this.status,
    this.errorMessage,
    this.currentModelName,
    this.isInitialized = false,
    this.autoRotate = false,
    this.rotationSpeed = 1.0,
    this.rotationDirection = RotationDirection.clockwise,
    this.rotationStopAfter,
    this.enableZoom = true,
    this.maxZoom = 20.0,
    this.minZoom = 1.0,
    this.isPositionLocked = true,
    this.cameraAlpha = -1.57, // Default Alpha
    this.cameraBeta = 1.25, // Default Beta
    this.cameraRadius = 3.0, // Default Radius
    this.skyboxPath,
    this.skyboxSource,
    this.lastScreenshot,
  });

  factory Power3DState.initial() =>
      const Power3DState(status: Power3DStatus.initial);

  Power3DState copyWith({
    Power3DStatus? status,
    String? errorMessage,
    String? currentModelName,
    bool? isInitialized,
    bool? autoRotate,
    double? rotationSpeed,
    RotationDirection? rotationDirection,
    Duration? rotationStopAfter,
    bool? enableZoom,
    double? maxZoom,
    double? minZoom,
    bool? isPositionLocked,
    double? cameraAlpha,
    double? cameraBeta,
    double? cameraRadius,
    String? skyboxPath,
    Power3DSource? skyboxSource,
    String? lastScreenshot,
  }) {
    return Power3DState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      currentModelName: currentModelName ?? this.currentModelName,
      isInitialized: isInitialized ?? this.isInitialized,
      autoRotate: autoRotate ?? this.autoRotate,
      rotationSpeed: rotationSpeed ?? this.rotationSpeed,
      rotationDirection: rotationDirection ?? this.rotationDirection,
      rotationStopAfter: rotationStopAfter ?? this.rotationStopAfter,
      enableZoom: enableZoom ?? this.enableZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      minZoom: minZoom ?? this.minZoom,
      isPositionLocked: isPositionLocked ?? this.isPositionLocked,
      cameraAlpha: cameraAlpha ?? this.cameraAlpha,
      cameraBeta: cameraBeta ?? this.cameraBeta,
      cameraRadius: cameraRadius ?? this.cameraRadius,
      skyboxPath: skyboxPath ?? this.skyboxPath,
      skyboxSource: skyboxSource ?? this.skyboxSource,
      lastScreenshot: lastScreenshot ?? this.lastScreenshot,
    );
  }
}
class EnvironmentConfig {
  /// Whether the background should rotate horizontally relative to the 3D camera.
  final bool syncRotation;

  /// Whether the background should scale based on 3D camera zoom (radius).
  final bool syncZoom;

  /// Whether the background should rotate vertically relative to 3D camera.
  final bool syncVerticalRotation;

  /// Sensitivity factor for horizontal rotation sync.
  final double rotationSensitivity;

  /// Sensitivity factor for zoom sync.
  final double zoomSensitivity;

  /// Sensitivity factor for vertical rotation sync.
  final double verticalSensitivity;

  /// Whether the background rotates independently (animation).
  /// This is separate from the 3D object's auto-rotation.
  final bool autoRotate;

  /// Speed factor for background independent rotation.
  final double autoRotationSpeed;

  const EnvironmentConfig({
    this.syncRotation = false,
    this.syncZoom = false,
    this.syncVerticalRotation = false,
    this.rotationSensitivity = 1.0,
    this.zoomSensitivity = 1.0,
    this.verticalSensitivity = 1.0,
    this.autoRotate = false,
    this.autoRotationSpeed = 1.0,
  });

  /// Default configuration (no automatic effects).
  static const EnvironmentConfig none = EnvironmentConfig();

  /// A skybox-like preset that pans with the camera horizontal/vertical movements.
  static const EnvironmentConfig skybox = EnvironmentConfig(
    syncRotation: true,
    syncVerticalRotation: true,
  );

  /// A preset where the background zooms along with the 3D object.
  static const EnvironmentConfig zoomSync = EnvironmentConfig(syncZoom: true);
}
