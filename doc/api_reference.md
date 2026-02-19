# API Reference

Detailed technical reference for the `power3d` plugin.

## Power3D Widget

The main widget for displaying 3D models.

| Property | Type | Description |
| :--- | :--- | :--- |
| `controller` | `Power3DController?` | Managed state and actions for the viewer. |
| `initialModel` | `Power3DData?` | The model to load on initialization. |
| `onMessage` | `Function(String)?` | Callback for messages from the underlying JS. |
| `lazy` | `bool` | If true, the viewer won't initialize until `controller.initialize()` is called. |
| `loadingUi` | `Widget Function(...)` | Custom widget to show during loading state. |
| `errorWidget` | `Widget?` | Custom widget to show on error state. |
| `environmentBuilder` | `Widget Function(...)` | Custom background widget behind the 3D model. |
| `lightingConfig` | `LightingConfig?` | Initial lighting configuration (intensity, color, type). |

### Constructors
- `Power3D.fromAsset(path, ...)`
- `Power3D.fromNetwork(url, ...)`
- `Power3D.fromFile(file, ...)`

---

## Power3DController

A `ValueNotifier<Power3DState>` that provides methods to control the 3D viewer.

### Properties
- `value`: Current `Power3DState` (status, rotation, zoom, lighting, etc.).

### Methods

#### `loadModel(Power3DData data)`
Loads a new model into the viewer.

#### `exportTexture(String textureId, String path)`
Saves a texture directly to the local file system.

#### `getAnimationsList()`
Fetches the list of all available animations in the model.

#### `playAnimation(String name, {bool loop, double speed})`
Starts playback of a specific animation.

#### `pauseAnimation(String name)`
Pauses a running animation.

#### `stopAnimation(String name)`
Stops an animation and resets it.

#### `setAnimationSpeed(String name, double speed)`
Sets the playback speed ratio for an animation.

#### `stopAllAnimations()` / `startAllAnimations()`
Batch controls for all model animations.

---
#### `resetView()`
Resets the camera to its initial orientation and zoom.

#### `updateLighting(LightingConfig config)`
Updates the scene lighting in real-time.

#### `updateRotation({bool? enabled, double? speed, RotationDirection? direction, Duration? stopAfter})`
Updates the auto-rotation behavior.

#### `setLockPosition(bool locked)`
Locks or unlocks object panning.

#### `updateZoom({bool? enabled, double? min, double? max})`
Updates zoom limits and toggles zooming.

#### `takeScreenshot()`
Captures the current view and returns a base64 string.

---

## Power3DState

| Property | Type | Description |
| :--- | :--- | :--- |
| `status` | `Power3DStatus` | `initial`, `loading`, `loaded`, `error`. |
| `errorMessage` | `String?` | Error description if status is `error`. |
| `autoRotate` | `bool` | Whether auto-rotation is active. |
| `isPositionLocked`| `bool` | Whether panning is disabled. |
| `enableZoom` | `bool` | Whether zooming is enabled. |
| `lightingConfig` | `LightingConfig` | Current lighting configuration. |
| `lastScreenshot` | `String?` | Base64 data of the last captured screenshot. |
