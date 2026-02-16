enum Power3DSource {
  asset,
  network,
  file,
}

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
  final bool autoRotate;
  final String? lastScreenshot;

  const Power3DState({
    required this.status,
    this.errorMessage,
    this.currentModelName,
    this.isInitialized = false,
    this.autoRotate = false,
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
    String? lastScreenshot,
  }) {
    return Power3DState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      currentModelName: currentModelName ?? this.currentModelName,
      isInitialized: isInitialized ?? this.isInitialized,
      autoRotate: autoRotate ?? this.autoRotate,
      lastScreenshot: lastScreenshot ?? this.lastScreenshot,
    );
  }
}
