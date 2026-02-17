import 'dart:math' as math;
import 'package:flutter/material.dart';

enum Power3DSource {
  asset,
  network,
  file,
}

enum RotationDirection { clockwise, counterClockwise }

enum LightType { hemispheric, directional, point }

enum ShadingMode {
  shaded,
  wireframe,
  pointCloud,
  xray,
  unlit,
  normals,
  uvChecker,
  roughness,
  metallic,
}

class MaterialConfig {
  final Color? color;
  final double? metallic;
  final double? roughness;
  final double? alpha;
  final Color? emissiveColor;
  final bool? doubleSided;

  const MaterialConfig({
    this.color,
    this.metallic,
    this.roughness,
    this.alpha,
    this.emissiveColor,
    this.doubleSided,
  });

  MaterialConfig copyWith({
    Color? color,
    double? metallic,
    double? roughness,
    double? alpha,
    Color? emissiveColor,
    bool? doubleSided,
  }) {
    return MaterialConfig(
      color: color ?? this.color,
      metallic: metallic ?? this.metallic,
      roughness: roughness ?? this.roughness,
      alpha: alpha ?? this.alpha,
      emissiveColor: emissiveColor ?? this.emissiveColor,
      doubleSided: doubleSided ?? this.doubleSided,
    );
  }
}

class SelectionStyle {
  final Color? highlightColor;
  final Color? outlineColor;
  final double? outlineWidth;

  const SelectionStyle({
    this.highlightColor,
    this.outlineColor,
    this.outlineWidth,
  });

  SelectionStyle copyWith({
    Color? highlightColor,
    Color? outlineColor,
    double? outlineWidth,
  }) {
    return SelectionStyle(
      highlightColor: highlightColor ?? this.highlightColor,
      outlineColor: outlineColor ?? this.outlineColor,
      outlineWidth: outlineWidth ?? this.outlineWidth,
    );
  }
}

class SelectionShift {
  final double x;
  final double y;
  final double z;

  const SelectionShift({this.x = 0, this.y = 0, this.z = 0});

  SelectionShift copyWith({double? x, double? y, double? z}) {
    return SelectionShift(x: x ?? this.x, y: y ?? this.y, z: z ?? this.z);
  }
}

class SelectionConfig {
  final bool enabled;
  final bool multipleSelection;
  final SelectionStyle? selectionStyle;
  final SelectionStyle? unselectedStyle;
  final double scaleSelection;
  final SelectionShift? selectionShift;

  const SelectionConfig({
    this.enabled = false,
    this.multipleSelection = false,
    this.selectionStyle,
    this.unselectedStyle,
    this.scaleSelection = 1.0,
    this.selectionShift,
  });

  SelectionConfig copyWith({
    bool? enabled,
    bool? multipleSelection,
    SelectionStyle? selectionStyle,
    SelectionStyle? unselectedStyle,
    double? scaleSelection,
    SelectionShift? selectionShift,
  }) {
    return SelectionConfig(
      enabled: enabled ?? this.enabled,
      multipleSelection: multipleSelection ?? this.multipleSelection,
      selectionStyle: selectionStyle ?? this.selectionStyle,
      unselectedStyle: unselectedStyle ?? this.unselectedStyle,
      scaleSelection: scaleSelection ?? this.scaleSelection,
      selectionShift: selectionShift ?? this.selectionShift,
    );
  }
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

  // Lighting & Scene
  final List<LightingConfig> lights;
  final double exposure;
  final double contrast;

  // Materials & Shading
  final ShadingMode shadingMode;
  final MaterialConfig? globalMaterial;

  // Selection & Object Parts
  final SelectionConfig selectionConfig;
  final List<String> selectedParts;
  final List<String> availableParts;

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
    this.lights = const [LightingConfig()],
    this.exposure = 1.0,
    this.contrast = 1.0,
    this.shadingMode = ShadingMode.shaded,
    this.globalMaterial,
    this.selectionConfig = const SelectionConfig(),
    this.selectedParts = const [],
    this.availableParts = const [],
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
    List<LightingConfig>? lights,
    double? exposure,
    double? contrast,
    ShadingMode? shadingMode,
    MaterialConfig? globalMaterial,
    SelectionConfig? selectionConfig,
    List<String>? selectedParts,
    List<String>? availableParts,
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
      lights: lights ?? this.lights,
      exposure: exposure ?? this.exposure,
      contrast: contrast ?? this.contrast,
      shadingMode: shadingMode ?? this.shadingMode,
      globalMaterial: globalMaterial ?? this.globalMaterial,
      selectionConfig: selectionConfig ?? this.selectionConfig,
      selectedParts: selectedParts ?? this.selectedParts,
      availableParts: availableParts ?? this.availableParts,
    );
  }
}

class LightingConfig {
  final LightType type;
  final double intensity;
  final Color color;
  final math.Point<double>? direction;
  final bool castShadows;
  final double shadowBlur;

  const LightingConfig({
    this.type = LightType.hemispheric,
    this.intensity = 0.7,
    this.color = Colors.white,
    this.direction,
    this.castShadows = false,
    this.shadowBlur = 10.0,
  });

  LightingConfig copyWith({
    LightType? type,
    double? intensity,
    Color? color,
    math.Point<double>? direction,
    bool? castShadows,
    double? shadowBlur,
  }) {
    return LightingConfig(
      type: type ?? this.type,
      intensity: intensity ?? this.intensity,
      color: color ?? this.color,
      direction: direction ?? this.direction,
      castShadows: castShadows ?? this.castShadows,
      shadowBlur: shadowBlur ?? this.shadowBlur,
    );
  }
}
