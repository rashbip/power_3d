# Environment Builder

The `environmentBuilder` allows you to render a Flutter widget behind your 3D model. With `EnvironmentConfig`, you can easily sync this background with camera movements without manual math.

## Easy Setup with EnvironmentConfig

Use `EnvironmentConfig` to automatically apply transforms (zoom, rotation, parallax) to your background.

```dart
Power3D.fromAsset(
  'assets/model.glb',
  environmentConfig: const EnvironmentConfig(
    syncRotation: true,         // Pans horizontally with camera
    syncVerticalRotation: true, // Pans vertically with camera
    syncZoom: true,             // Scales with zoom
    rotationSensitivity: 1.5,   // Optional: adjust speed
  ),
  environmentBuilder: (context, state) {
    return Image.asset('assets/space_bg.jpg', fit: BoxFit.cover);
  },
)
```

### Configuration Options

| Property               | Description                                                        |
| :--------------------- | :----------------------------------------------------------------- |
| `syncRotation`         | If true, background pans horizontally as camera Alpha changes.     |
| `syncVerticalRotation` | If true, background pans vertically as camera Beta changes.        |
| `syncZoom`             | If true, background scales automatically as camera Radius changes. |
| `autoRotate`           | If true, background rotates independently (obj stays steady).      |
| `autoRotationSpeed`    | Speed factor for the independent background rotation.              |
| `rotationSensitivity`  | Adjusts how far the background pans horizontally.                  |
| `zoomSensitivity`      | Adjusts how much the background scales.                            |

## Manual Control

If you need full control, the `environmentBuilder` provides the `Power3DState` containing raw telemetry:

- `state.cameraAlpha`: Horizontal rotation in radians.
- `state.cameraBeta`: Vertical rotation in radians.
- `state.cameraRadius`: Distance from the object (zoom level).

```dart
environmentBuilder: (context, state) {
  return Transform.scale(
    scale: 5.0 / state.cameraRadius,
    child: MyWidget(),
  );
}
```

> [!IMPORTANT]
> The environment widget is automatically wrapped in an `IgnorePointer`, so it will not intercept touch events intended for the 3D viewer.
