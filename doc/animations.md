# Animation System

Power3D provides a robust framework for managing skeletal and property animations in your 3D models. You can list available animations, control playback of multiple tracks, and tune speed or looping in real-time.

## Fetching Animations

Use `getAnimationsList()` to trigger an inventory of all animations embedded in the model. The results are stored in the controller's state.

```dart
await controller.getAnimationsList();

// Access them via the state
for (var animation in controller.value.animations) {
  print('Found animation: $animation');
}
```

---

## Playback Control

You can control specific animations by name. By default, Power3D allows multiple animations to play simultaneously.

### Basic Playback
```dart
// Play an animation with default settings
controller.playAnimation('Walk');

// Play with custom parameters
controller.playAnimation(
  'Run', 
  loop: true, 
  speed: 1.5,
);
```

### Pausing and Stopping
```dart
// Pause - maintains current frame
controller.pauseAnimation('Walk');

// Stop - resets to first frame
controller.stopAnimation('Walk');

// Timed pause (useful for specific transitions)
controller.pauseAfter('BlastOff', Duration(seconds: 2));
```

---

## Global and Batch Actions

If your model has many synchronized parts, you might want to control everything at once.

```dart
// Start all detected animations
controller.startAllAnimations();

// Stop everything immediately
controller.stopAllAnimations();

// Enable/Disable simultaneous playback
controller.setPlayMultiple(false); // Only one animation at a time
```

---

## Animation Configuration

| Action | Dart Method | Description |
|--------|-------------|-------------|
| **Play** | `playAnimation(name, ...)` | Starts playback. |
| **Pause** | `pauseAnimation(name)` | Freezes the animation on the current frame. |
| **Stop** | `stopAnimation(name)` | Halts animation and resets progress. |
| **Speed** | `setAnimationSpeed(name, ratio)`| Adjusts playback speed (e.g., `0.5` for slow-mo, `2.0` for fast). |
| **Loop** | `setAnimationLoop(name, bool)`| Toggles whether the animation repeats. |

---

## Best Practices

- **Scan on Load**: Use the `onModelLoaded` callback to refresh your animation list as soon as a new model is ready.
- **Naming**: Animation names are case-sensitive and come directly from the GLTF/GLB file metadata.
- **Speed Ratios**: A speed of `1.0` is the original recorded speed. Values below `0` may cause reverse playback depending on the model's export settings.
