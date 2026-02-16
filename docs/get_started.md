# Getting Started with Power3D

Welcome to Power3D! This guide will help you get your first 3D model rendered in Flutter in minutes.

## 1. Installation

Add `power3d` to your `pubspec.yaml`:

```yaml
dependencies:
  power3d:
    path: ../ # If using local plugin, or use version from pub.dev
```

Run `flutter pub get`.

## 2. Platform Setup

Before running, ensure you have the necessary permissions:

- **Android**: Allow Internet and (optionally) Cleartext traffic in `AndroidManifest.xml`.
- **iOS**: Update `Info.plist` for network loading.

See the [Setup Guide](setup.md) for detailed steps.

## 3. Basic Usage

### Initialize the Power3D Widget

The simplest way to show a model is using one of the factory constructors:

```dart
import 'package:power3d/power3d.dart';

// In your build method
Power3D.fromAsset('assets/models/my_model.glb')
```

### Using a Controller

To interact with the model (rotate, screenshot, etc.), you'll need a `Power3DController`.

```dart
class My3DView extends StatefulWidget {
  @override
  State<My3DView> createState() => _My3DViewState();
}

class _My3DViewState extends State<My3DView> {
  final _controller = Power3DController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Power3D.fromNetwork(
        'https://example.com/model.glb',
        controller: _controller,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _controller.resetView(),
        child: Icon(Icons.refresh),
      ),
    );
  }
}
```

## 4. Next Steps

- Explore [Advanced Controls](controls.md) for rotation and zoom settings.
- Check the [API Reference](api_reference.md) for all available properties.
- Learn about [Optimization](babylonjs_optimization.md) for better performance.
