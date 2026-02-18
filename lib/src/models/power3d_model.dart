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

/// Styles for the bounding box visualization.
enum BoundingBoxStyle {
  /// Standard wireframe cube with scale handles.
  cube,

  /// Wireframe sphere encompassing the bounds.
  sphere,

  /// Simple wireframe box without handles.
  simple,
}

/// Configuration for bounding box visualization.
class BoundingBoxConfig {
  /// Color of the bounding box lines.
  final Color color;

  /// Width of the bounding box lines.
  final double lineWidth;

  /// Visual style of the bounding box.
  final BoundingBoxStyle style;

  /// Whether to show dimensions/measurements.
  final bool showDimensions;

  /// Creates a new bounding box configuration.
  const BoundingBoxConfig({
    this.color = Colors.green,
    this.lineWidth = 1.0,
    this.style = BoundingBoxStyle.cube,
    this.showDimensions = false,
  });

  /// Creates a copy of this configuration with the given fields replaced.
  BoundingBoxConfig copyWith({
    Color? color,
    double? lineWidth,
    BoundingBoxStyle? style,
    bool? showDimensions,
  }) {
    return BoundingBoxConfig(
      color: color ?? this.color,
      lineWidth: lineWidth ?? this.lineWidth,
      style: style ?? this.style,
      showDimensions: showDimensions ?? this.showDimensions,
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

  /// List of available animations in the model.
  final List<Power3DAnimation> animations;

  /// Whether multiple animations can be played simultaneously.
  final bool playMultiple;

  /// List of names of hidden parts.
  final List<String> hiddenParts;

  /// List of names of parts with visible bounding boxes.
  /// List of bounding boxes currently shown.
  final List<String> boundingBoxParts;

  /// Hierarchical structure of parts (JSON list of nodes).
  final List<dynamic>? partsHierarchy;

  /// List of available textures in the scene.
  final List<Power3DTexture> textures;

  /// Creates a new [Power3DState].
  const Power3DState({
    this.isInitialized = false,
    this.status = Power3DStatus.initial,
    this.errorMessage,
    this.currentModelName,
    this.shadingMode = ShadingMode.shaded,
    this.globalMaterial,
    this.lights = const [],
    this.exposure = 1.0,
    this.contrast = 1.0,
    this.autoRotate = false,
    this.rotationSpeed = 1.0,
    this.rotationDirection = RotationDirection.counterClockwise,
    this.rotationStopAfter,
    this.isPositionLocked = false,
    this.enableZoom = true,
    this.minZoom = 0.5,
    this.maxZoom = 20.0,
    this.cameraAlpha = -1.57,
    this.cameraBeta = 1.25,
    this.cameraRadius = 3.0,
    this.lastScreenshot,
    this.selectionConfig = const SelectionConfig(),
    this.selectedParts = const [],
    this.availableParts = const [],
    this.animations = const [],
    this.playMultiple = false,
    this.partsHierarchy,
    this.hiddenParts = const [],
    this.boundingBoxParts = const [],
    this.textures = const [],
  });

  /// Initial state representation.
  factory Power3DState.initial() => const Power3DState();

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
    List<Power3DAnimation>? animations,
    bool? playMultiple,
    List<String>? hiddenParts,
    List<String>? boundingBoxParts,
    List<dynamic>? partsHierarchy,
    List<Power3DTexture>? textures,
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
      animations: animations ?? this.animations,
      playMultiple: playMultiple ?? this.playMultiple,
      hiddenParts: hiddenParts ?? this.hiddenParts,
      boundingBoxParts: boundingBoxParts ?? this.boundingBoxParts,
      partsHierarchy: partsHierarchy ?? this.partsHierarchy,
      textures: textures ?? this.textures,
    );
  }
}

/// Metadata representing a texture in the 3D scene.
class Power3DTexture {
  /// Unique identifier for the texture.
  final String uniqueId;

  /// Name of the texture or filename.
  final String name;

  /// The class name of the texture in Babylon.js.
  final String className;

  /// Whether this is a render target texture.
  final bool isRenderTarget;

  /// The brightness/intensity level of the texture.
  final double level;

  /// URL of the texture if available.
  final String? url;

  /// Horizontal scale/tiling.
  final double uScale;

  /// Vertical scale/tiling.
  final double vScale;

  /// Horizontal offset.
  final double uOffset;

  /// Vertical offset.
  final double vOffset;

  /// Creates a new texture metadata object.
  const Power3DTexture({
    required this.uniqueId,
    required this.name,
    required this.className,
    this.isRenderTarget = false,
    this.level = 1.0,
    this.url,
    this.uScale = 1.0,
    this.vScale = 1.0,
    this.uOffset = 0.0,
    this.vOffset = 0.0,
  });

  /// Creates a [Power3DTexture] from a JSON map.
  factory Power3DTexture.fromJson(Map<String, dynamic> json) {
    return Power3DTexture(
      uniqueId: json['uniqueId'] ?? '',
      name: json['name'] ?? '',
      className: json['className'] ?? '',
      isRenderTarget: json['isRenderTarget'] ?? false,
      level: (json['level'] as num?)?.toDouble() ?? 1.0,
      url: json['url'],
      uScale: (json['uScale'] as num?)?.toDouble() ?? 1.0,
      vScale: (json['vScale'] as num?)?.toDouble() ?? 1.0,
      uOffset: (json['uOffset'] as num?)?.toDouble() ?? 0.0,
      vOffset: (json['vOffset'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Request object to update texture properties.
class TextureUpdate {
  /// Optional brightness/intensity level.
  final double? level;

  /// Optional horizontal scale.
  final double? uScale;

  /// Optional vertical scale.
  final double? vScale;

  /// Optional horizontal offset.
  final double? uOffset;

  /// Optional vertical offset.
  final double? vOffset;

  /// Creates a texture update request.
  const TextureUpdate({
    this.level,
    this.uScale,
    this.vScale,
    this.uOffset,
    this.vOffset,
  });

  /// Converts the update to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      if (level != null) 'level': level,
      if (uScale != null) 'uScale': uScale,
      if (vScale != null) 'vScale': vScale,
      if (uOffset != null) 'uOffset': uOffset,
      if (vOffset != null) 'vOffset': vOffset,
    };
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

/// Represents the state of an animation in the 3D model.
class Power3DAnimation {
  /// Name of the animation.
  final String name;

  /// Whether the animation is currently playing.
  final bool isPlaying;

  /// Current playback speed.
  final double speed;

  /// Whether the animation is set to loop.
  final bool loop;

  /// Creates a new animation state object.
  const Power3DAnimation({
    required this.name,
    this.isPlaying = false,
    this.speed = 1.0,
    this.loop = true,
  });

  /// Creates a [Power3DAnimation] from a JSON map.
  factory Power3DAnimation.fromJson(Map<String, dynamic> json) {
    return Power3DAnimation(
      name: json['name'] ?? '',
      isPlaying: json['isPlaying'] ?? false,
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      loop: json['loop'] ?? true,
    );
  }

  /// Creates a copy of this animation state with the given fields replaced.
  Power3DAnimation copyWith({
    String? name,
    bool? isPlaying,
    double? speed,
    bool? loop,
  }) {
    return Power3DAnimation(
      name: name ?? this.name,
      isPlaying: isPlaying ?? this.isPlaying,
      speed: speed ?? this.speed,
      loop: loop ?? this.loop,
    );
  }
}
