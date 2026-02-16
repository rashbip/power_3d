# Power3D Usage Guide

Power3D is a flexible 3D model viewer for Flutter. It uses Babylon.js behind the scenes to provide a rich, interactive experience.

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  power3d:
    path: ../power3d
```

## Named Constructors

The easiest way to use Power3D is through its named constructors.

### `Power3D.fromAsset`
Loads a model from your application assets.

```dart
Power3D.fromAsset(
  'assets/my_model.glb',
  fileName: 'custom_name.glb', // Optional: Helps identifies the loader type
)
```

### `Power3D.fromNetwork`
Fetches a model from a URL.

```dart
Power3D.fromNetwork(
  'https://example.com/model.glb',
  lazy: true, // Optional: Wait for manual initialization
)
```

### `Power3D.fromFile`
Loads a model from a local file.

```dart
Power3D.fromFile(File('/path/to/model.glb'))
```

## Lazy Loading & Placeholders

Lazy loading allows you to prepare the viewer without immediately downloading or rendering the model. This is perfect for lists or complex pages.

```dart
Power3D.fromNetwork(
  'https://example.com/car.glb',
  lazy: true,
  placeholderBuilder: (context, notifier) {
    return Column(
      children: [
        Text('Tap to preview car'),
        ElevatedButton(
          onPressed: () => notifier.initialize(),
          child: Text('LOAD'),
        ),
      ],
    );
  },
)
```

## State Management

Power3D uses Riverpod for state management. You can access the `Power3DManager` through the `placeholderBuilder` or by using a `ConsumerWidget`.

### Power3DStatus
- `initial`: Viewer is ready but not yet loading.
- `loading`: Model is being fetched or parsed.
- `loaded`: Model is visible and interactive.
- `error`: Something went wrong.

## Error Handling

Power3D provides a built-in error UI with a retry mechanism. You can customize this by listening to messages or checking the state.
