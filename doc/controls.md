# Power3D Controls Documentation

Power3D provides advanced camera and rotation controls to customize the viewer experience.

## Camera Controls

### Position Locking

By default, the 3D object is locked in the center of the view. You can unlock it to allow users to pan the object.

```dart
// Lock position (Default)
controller.setLockPosition(true);

// Unlock position (Allows panning)
controller.setLockPosition(false);
```

### Zoom Controls

Zooming is enabled by default. You can toggle it and set distance limits.

```dart
controller.updateZoom(
  enabled: true,
  min: 1.0,
  max: 20.0,
);
```

## Rotation Controls

You can customize the auto-rotation behavior with speed, direction, and an optional stop timer.

```dart
controller.updateRotation(
  enabled: true,
  speed: 2.0, // Multiplier (Default 1.0)
  direction: RotationDirection.counterClockwise,
  stopAfter: Duration(seconds: 5), // Automatically stops after 5s
);
```

## Screenshot Handling

Screenshots now require a mandatory save path. The plugin handles the base64 conversion and file saving for you.

```dart
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

final directory = await getApplicationDocumentsDirectory();
final path = p.join(directory.path, 'my_model_shot.png');

await controller.takeScreenshot(path);
```
