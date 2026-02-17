import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Source of the 3D model.
enum Power3DSource {
  /// Loaded from Flutter assets.
  asset,

  /// Loaded from a network URL.
  network,

  /// Loaded from a local file path.
  file,
}

/// Directions for automatic rotation of the model.
enum RotationDirection {
  /// Clockwise rotation.
  clockwise,

  /// Counter-clockwise rotation.
  counterClockwise,
}

/// Types of lights supported in the scene.
enum LightType {
  /// Ambient light that illuminates all objects equally from a specific direction.
  hemispheric,

  /// Parallel light rays (like sunlight).
  directional,

  /// Light that radiates from a single point in all directions.
  point,
}

/// Shading and rendering modes for the 3D scene.
enum ShadingMode {
  /// Standard shaded rendering with lighting.
  shaded,

  /// Show the underlying mesh wireframe.
  wireframe,

  /// Render only the vertices of the mesh.
  pointCloud,

  /// Semi-transparent X-ray style rendering.
  xray,

  /// Render with flat colors, ignoring lighting.
  unlit,

  /// Visualize surface normals.
  normals,

  /// Show a UV checkerboard pattern for texture alignment.
  uvChecker,

  /// Visualize the roughness property of materials.
  roughness,

  /// Visualize the metallic property of materials.
  metallic,
}

/// Configuration for overriding material properties of the model.
class MaterialConfig {
  /// Base color of the material.
  final Color? color;

  /// Metallic property (0.0 to 1.0).
  final double? metallic;

  /// Roughness property (0.0 to 1.0).
  final double? roughness;

  /// Transparency level (0.0 to 1.0).
  final double? alpha;

  /// Emissive (glowing) color of the material.
  final Color? emissiveColor;

  /// Whether to render both sides of the mesh polygons.
  final bool? doubleSided;

  /// Creates a new material configuration.
  const MaterialConfig({
    this.color,
    this.metallic,
    this.roughness,
    this.alpha,
    this.emissiveColor,
    this.doubleSided,
  });

  /// Creates a copy of this configuration with the given fields replaced.
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

/// Visual style for selected or unselected parts of the model.
class SelectionStyle {
  /// Color used to highlight the selected part.
  final Color? highlightColor;

  /// Color of the outline around the selected part.
  final Color? outlineColor;

  /// Width of the outline.
  final double? outlineWidth;

  /// Creates a new selection style.
  const SelectionStyle({
    this.highlightColor,
    this.outlineColor,
    this.outlineWidth,
  });

  /// Creates a copy of this style with the given fields replaced.
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

/// Positional offset for selected parts.
class SelectionShift {
  /// X-axis offset.
  final double x;

  /// Y-axis offset.
  final double y;

  /// Z-axis offset.
  final double z;

  /// Creates a new selection shift.
  const SelectionShift({this.x = 0, this.y = 0, this.z = 0});

  /// Creates a copy of this shift with the given fields replaced.
  SelectionShift copyWith({double? x, double? y, double? z}) {
    return SelectionShift(x: x ?? this.x, y: y ?? this.y, z: z ?? this.z);
  }
}

/// Configuration for the object parts selection system.
class SelectionConfig {
  /// Whether selection is enabled.
  final bool enabled;

  /// Whether multiple parts can be selected simultaneously.
  final bool multipleSelection;

  /// Style applied to selected parts.
  final SelectionStyle? selectionStyle;

  /// Style applied to parts that are NOT selected.
  final SelectionStyle? unselectedStyle;

  /// Scaling factor applied to selected parts.
  final double scaleSelection;

  /// Positional shift applied to selected parts.
  final SelectionShift? selectionShift;

  /// Creates a new selection configuration.
  const SelectionConfig({
    this.enabled = false,
    this.multipleSelection = false,
    this.selectionStyle,
    this.unselectedStyle,
    this.scaleSelection = 1.0,
    this.selectionShift,
  });

  /// Creates a copy of this configuration with the given fields replaced.
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

/// Data structure representing a 3D model source.
class Power3DData {
  /// Path or URL to the model file.
  final String path;

  /// Source type (asset, network, or file).
  final Power3DSource source;

  /// Custom name for the file (optional).
  final String? fileName;

  /// Creates a new model data structure.
  const Power3DData({
    required this.path,
    required this.source,
    this.fileName,
  });

  /// Returns the file extension of the model path.
  String get extension => path.split('.').last.toLowerCase();
}

/// Loading status of the 3D model.
enum Power3DStatus {
  /// Initial state, no model loading started.
  initial,

  /// Model is currently being downloaded or loaded into the scene.
  loading,

  /// Model has been successfully loaded.
  loaded,

  /// An error occurred during loading.
  error,
}

/// State of the Power3D viewer.
class Power3DState {
  /// Current loading status.
  final Power3DStatus status;

  /// Error message if status is [Power3DStatus.error].
  final String? errorMessage;

  /// Name of the currently loaded model.
  final String? currentModelName;

  /// Whether the Babylon.js engine is initialized.
  final bool isInitialized;

  /// Whether the camera is currently auto-rotating.
  final bool autoRotate;

  /// Speed of camera rotation.
  final double rotationSpeed;

  /// Direction of camera rotation.
  final RotationDirection rotationDirection;

  /// Time after which auto-rotation should automatically stop.
  final Duration? rotationStopAfter;

  /// Whether camera zooming is enabled.
  final bool enableZoom;

  /// Maximum allowed zoom level.
  final double maxZoom;

  /// Minimum allowed zoom level.
  final double minZoom;

  /// Whether the camera position (panning) is locked.
  final bool isPositionLocked;

  /// Horizontal angle (Alpha) of the camera in radians.
  final double cameraAlpha;

  /// Vertical angle (Beta) of the camera in radians.
  final double cameraBeta;

  /// Distance (Radius) of the camera from the target.
  final double cameraRadius;

  /// Base64 encoded string of the last captured screenshot.
  final String? lastScreenshot;

  /// List of lights currently active in the scene.
  final List<LightingConfig> lights;

  /// Scene exposure level.
  final double exposure;

  /// Scene contrast level.
  final double contrast;

  /// Current shading mode.
  final ShadingMode shadingMode;

  /// Global material override applied to the entire model.
  final MaterialConfig? globalMaterial;

  /// Configuration for the selection system.
  final SelectionConfig selectionConfig;

  /// List of names of currently selected parts.
  final List<String> selectedParts;

  /// List of names of all selectable parts in the model.
  final List<String> availableParts;

  /// Creates a new state object.
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

  /// Initial state helper.
  factory Power3DState.initial() =>
      const Power3DState(status: Power3DStatus.initial);

  /// Creates a copy of this state with the given fields replaced.
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

/// Configuration for a light source in the scene.
class LightingConfig {
  /// Type of light.
  final LightType type;

  /// Intensity of the light (usually 0.0 to 1.0+).
  final double intensity;

  /// Color of the light.
  final Color color;

  /// Direction of the light (for [LightType.directional]).
  final math.Point<double>? direction;

  /// Whether this light casts shadows.
  final bool castShadows;

  /// Blur level for the shadows.
  final double shadowBlur;

  /// Creates a new lighting configuration.
  const LightingConfig({
    this.type = LightType.hemispheric,
    this.intensity = 0.7,
    this.color = Colors.white,
    this.direction,
    this.castShadows = false,
    this.shadowBlur = 10.0,
  });

  /// Creates a copy of this lighting configuration with the given fields replaced.
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
