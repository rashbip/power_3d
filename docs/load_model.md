# Loading Models

Power3D provides several ways to load your 3D models, depending on where they are stored.

## Loading from Assets

To load a model bundled with your application assets:

1. Add the model to your `pubspec.yaml`:

   ```yaml
   flutter:
     assets:
       - assets/models/robot.glb
   ```

2. Use `Power3D.fromAsset`:
   ```dart
   Power3D.fromAsset('assets/models/robot.glb')
   ```

## Loading from Network

Fetch models directly from a URL:

```dart
Power3D.fromNetwork(
  'https://models.babylonjs.com/boombox.glb',
  onMessage: (msg) => print("Message from viewer: $msg"),
)
```

> [!NOTE]
> For network models, ensure you've configured platform-specific permissions. See [Setup Guide](setup.md).

## Loading from Local Files

Load models from the device's storage:

```dart
import 'dart:io';

final file = File('/storage/emulated/0/Download/car.glb');
Power3D.fromFile(file)
```

## Lazy Loading

By default, the 3D viewer initializes as soon as the widget is built. Use `lazy: true` to defer initialization until manually triggered via the controller.

```dart
Power3D.fromNetwork(
  url,
  lazy: true,
  controller: myController,
)

// Later...
myController.initialize();
```

## Custom Loading and Error UI

You can completely customize the look and feel during the loading process or when an error occurs.

### Custom Loading UI

The `loadingUi` callback provides access to the `Power3DController`, allowing you to show progress or status messages.

```dart
Power3D.fromAsset(
  'assets/heavy_model.glb',
  loadingUi: (context, controller) {
    return Center(
      child: Column(
        children: [
          CircularProgressIndicator(),
          Text("Loading model..."),
        ],
      ),
    );
  },
)
```

### Custom Error Widget

```dart
Power3D.fromNetwork(
  'https://invalid.url/model.glb',
  errorWidget: Center(
    child: Text("Failed to load 3D model. Please check your connection."),
  ),
)
```
