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
      lastScreenshot: lastScreenshot ?? this.lastScreenshot,
    );
  }
}
