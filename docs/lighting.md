# Lighting System

Power3D provides a professional-grade lighting system with support for multiple light sources, dynamic shadows, and scene-level image processing.

## LightingConfig

The `LightingConfig` class defines individual light sources in your scene.

### Properties

| Property          | Type             | Default        | Description                                        |
| :---------------- | :--------------- | :------------- | :------------------------------------------------- |
| **`type`**        | `LightType`      | `hemispheric`  | Light type (hemispheric, directional, point).      |
| **`intensity`**   | `double`         | `0.7`          | Light strength/brightness.                         |
| **`color`**       | `Color`          | `Colors.white` | Light color.                                       |
| **`direction`**   | `Point<double>?` | `null`         | Direction vector (for Directional light).          |
| **`castShadows`** | `bool`           | `false`        | Enable shadow generation (Directional/Point only). |
| **`shadowBlur`**  | `double`         | `10.0`         | Shadow blur kernel size.                           |

## Multiple Lights

You can now define multiple light sources for complex scenes:

```dart
Power3D.fromAsset(
  'assets/model.glb',
  lights: [
    LightingConfig(
      type: LightType.directional,
      intensity: 1.0,
      color: Colors.white,
      castShadows: true,
    ),
    LightingConfig(
      type: LightType.point,
      intensity: 0.4,
      color: Colors.blueAccent,
    ),
  ],
)
```

## Shadows

Enable realistic shadows for directional and point lights:

```dart
LightingConfig(
  type: LightType.directional,
  intensity: 1.2,
  castShadows: true,
  shadowBlur: 32.0, // Higher = softer shadows
)
```

**Note:** Hemispheric lights cannot cast shadows.

## Scene Processing

Control overall scene brightness and contrast:

```dart
Power3D.fromAsset(
  'assets/model.glb',
  exposure: 1.5,  // Increase overall brightness
  contrast: 1.2,  // Enhance contrast
)
```

## Dynamic Updates

Use the controller to update lighting at runtime:

```dart
// Update all lights
_controller.setLights([
  LightingConfig(type: LightType.point, intensity: 2.0),
]);

// Update scene processing
_controller.updateSceneProcessing(
  exposure: 2.0,
  contrast: 1.5,
);
```

### Light Types

1. **Hemispheric Light**: Ambient light from a hemisphere. Perfect for outdoor scenes. Cannot cast shadows.
2. **Directional Light**: Parallel light rays from infinity (like sunlight). Can cast shadows.
3. **Point Light**: Omnidirectional light from a point (like a light bulb). Can cast shadows.
