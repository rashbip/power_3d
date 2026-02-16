# power3d

# Power3D

A premium, localized 3D model viewer for Flutter powered by Babylon.js.

## Features

- **Blazing Fast**: Uses Babylon.js for high-performance 3D rendering.
- **Multiple Sources**: Load models from Assets, Network, or local Files.
- **Lazy Loading**: Defer model download and rendering until explicitly triggered.
- **Custom Placeholders**: Show beautiful UI while models are loading or before they start.
- **State Management**: Built with Riverpod for robust and predictable state handling.
- **Cross-Platform**: Seamlessly works on Android and iOS via WebView.

## Quick Start

```dart
// Basic Asset Loading
Power3D.fromAsset('assets/models/heart.glb')

// Lazy Network Loading with Custom UI
Power3D.fromNetwork(
  'https://example.com/model.glb',
  lazy: true,
  placeholderBuilder: (context, notifier) {
    return Center(
      child: ElevatedButton(
        onPressed: () => notifier.initialize(),
        child: Text('Load 3D Model'),
      ),
    );
  },
)
```

## Performance & Storage

Power3D uses **CDN-hosted Babylon.js** (~2MB from cache) instead of bundling large files locally. This keeps your app size small. See [Babylon.js Optimization Guide](docs/babylonjs_optimization.md) for details.

## Documentation

For detailed usage, check out the [Usage Guide](docs/usage.md).
