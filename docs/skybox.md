# Skybox (360 Backgrounds)

Power3D supports native 360-degree backgrounds using Babylon.js `PhotoDome`. This is the recommended way to create immersive environments.

## Native Skybox

To use a native 360 skybox, use the `skyboxPath` and `skyboxSource` parameters.

```dart
Power3D.fromAsset(
  'assets/model.glb',
  skyboxPath: 'assets/skybox_360.jpg',
  skyboxSource: Power3DSource.asset,
)
```

The native skybox:
- Automatically wraps around the scene.
- Correctily maps to 3D space.
- Responds natively to camera rotation.

## Comparison: Skybox vs Environment Builder

| Feature | `skyboxPath` (Native) | `environmentBuilder` (Flutter) |
| :--- | :--- | :--- |
| **Best For** | 360 panoramic images. | 2D UI, parallax layers, custom widgets. |
| **Performance** | High (GPU accelerated). | Moderate (Flutter pixel buffer). |
| **Interaction** | Fixed to 3D world. | Reactive to camera via `EnvironmentConfig`. |
| **Flexibility** | Static image. | Dynamic Flutter widgets. |

## Combining Both

You can use a native skybox for the distant environment and the `environmentBuilder` for near-field UI or special parallax effects that sit between the viewer and the skybox.

```dart
Power3D.fromAsset(
  'assets/model.glb',
  skyboxPath: 'assets/space_360.jpg',
  environmentBuilder: (context, state) {
    return MyAnimatedNebulaLayer(); // Adds Flutter animations on top of the skybox
  },
)
```

## Skybox Source Types
Native skyboxes support all source types:
- `Power3DSource.asset`: Bundled images.
- `Power3DSource.network`: Remote URLs.
- `Power3DSource.file`: Local file paths.
