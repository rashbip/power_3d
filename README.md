# Power3D

A powerful, industry-level Flutter plugin for rendering 3D models using Babylon.js. Designed for ease of use, extensibility, and seamless integration into any architecture.

## Features

- **🚀 Architecture Agnostic**: Uses a Controller pattern, compatible with Riverpod, Bloc, Provider, GetX, or plain `setState`.
- **📦 Versatile Loading**: Load models from Assets, Network, or local Files.
- **🎮 Advanced Controls**: 
    - Auto-rotation with custom speed and direction.
    - Automatic stop timer for rotation.
    - Zoom limits (min/max) and toggles.
    - Position locking (enable/disable panning).
- **📸 Managed Screenshots**: Capture and automatically save screenshots to a specified path.
- **🎨 Customizable UI**: Provide your own loading and error widgets.

## Quick Start

### 1. Add dependency
```yaml
dependencies:
  power3d: ^1.0.0
```

### 2. Basic Setup (Android)
Ensure your app supports cleartext traffic if loading models from URLs. See [Setup Guide](doc/setup.md).

### 3. Usage

```dart
import 'package:power3d/power3d.dart';

// 1. Create a controller
final controller = Power3DController();

// 2. Add the widget
Power3D.fromAsset(
  'assets/my_model.glb',
  controller: controller,
);

// 3. Control the view
void rotate() {
  controller.updateRotation(
    enabled: true,
    speed: 1.5,
    stopAfter: Duration(seconds: 5),
  );
}
```

## Documentation

- [Setup & Permissions](docs/setup.md)
- [Camera & Rotation Controls](docs/controls.md)
- [API Reference](docs/api_reference.md)

## Example

Check the `example` folder for a complete demonstration of all features.
