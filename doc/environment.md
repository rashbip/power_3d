# Environment (Background)

Power3D allows you to render a Flutter widget behind the 3D model. This is useful for creating consistent backgrounds, gradients, or overlays.

## Usage

Use the `environmentBuilder` property to provide a widget that will be placed in a `Stack` behind the 3D viewer.

```dart
Power3D.fromAsset(
  'assets/model.glb',
  environmentBuilder: (context, state) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.black],
        ),
      ),
    );
  },
)
```

### Accessing State
The `environmentBuilder` provides the current `Power3DState`, allowing you to react to loading status or camera movements if needed.

```dart
environmentBuilder: (context, state) {
  if (state.status == Power3DStatus.loading) {
     return Center(child: CircularProgressIndicator());
  }
  
  // You can also use state.cameraAlpha, state.cameraBeta etc. 
  // for manual parallax effects if desired.
  return MyBackgroundWidget();
}
```

### Important Notes
- The background widget is wrapped in an `IgnorePointer` by default to ensure touch events reach the 3D viewer.
- The background is only shown when the 3D model is loaded (`Power3DStatus.loaded`).
