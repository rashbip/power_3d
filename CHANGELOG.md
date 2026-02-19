# 1.5.0

## Features
* **Full Texture Management**: A comprehensive system to inspect and modify engine textures.
  * **`getTexturesList()`**: Retrieve metadata for all image and procedural textures.
  * **Asynchronous Extraction**: High-performance, message-based fetching of raw Base64 texture data.
  * **Real-time Editing**: Modify `level` (brightness), `uScale`, `vScale`, and offsets on the fly.
  * **Direct Export**: `exportTexture()` saves engine textures directly to the local file system.
* **Animation System**: Complete framework for controlling 3D model animations.
  * **Playback Control**: Play, pause, stop, and resume animations by name.
  * **Advanced Tuning**: Global and per-animation speed control and looping toggles.
  * **Batch Actions**: Start or stop all animations simultaneously.
  * **Timed Events**: Automatically pause animations after a specified duration.
* **Modular Controller Architecture**: Refactored `Power3DController` into specialized extensions (`View`, `Selection`, `Material`, `Texture`, `Animation`) using the `part`/`part of` pattern for better maintainability and reduced file size.
* **Enhanced Widget Lifecycle**: Added `onModelLoaded` callback to `Power3D` widget for reliable post-load scene configuration.

## Stability & Improvements
* **Texture Extraction Robustness**: Implemented a safer pixel-copying loop in JavaScript to handle HDR (Float32) textures and dimension mismatches (fixes `RangeError`).
* **Memory & Lifecycle Safety**: Added disposal guards to `Power3DController` to prevent "used after being disposed" errors during rapid screen transitions.
* **Performance**: Optimized the bridge communication for large data transfers between WebView and Dart.

## Documentation
* New **[Texture Management Guide](./doc/textures.md)**.
* Updated API reference with new controller methods and widget callbacks.

---

# 1.1.0

## Features
* **Selection System Overhaul**: Complete replacement of the basic selection system with a professional-grade modular system.
  * **Inspector-Style Hierarchy**: Reorganized hierarchy view into "Nodes" and "Materials" sections, matching Babylon.js Inspector.
  * **Advanced Node Identification**: Automatic detection of `Meshes`, `Cameras`, `Lights`, and `Transform Nodes` with dedicated icons.
  * **Interactive Bounding Boxes**: New `BoundingBoxStyle` support (`cube`, `sphere`, `simple`) and adjustable line thickness.
  * **GLTF Metadata & Extras**: Specialized `getNodeExtras` function to extract raw data and GLTF extras from any scene node or material.
  * **Robust Identification**: Migrated selection system to use `uniqueId.toString()` as primary key, resolving duplicate naming issues.
  * **Visibility Controls**: New batch and individual controls for hiding/showing parts, including "Hide Selected" and "Show All".
  * **Selection Styling**: Independent material modes (wireframe, xray, etc.) for selected vs unselected parts.
* **Modular Example Suite**: Replaced the monolithic selection example with four focused, high-performance examples in the example app.

## Bug Fixes
* **3D Stability**: Fixed a major crash `(Uncaught TypeError: Cannot read properties of undefined)` caused by improper `UtilityLayerRenderer` initialization in WebView.
* **Selection Reliability**: Fixed issue where "unnamed" or duplicate nodes could not be selected.
* **Material Lookup**: Fixed materials not being found when requested by unique identifier.
* **Deprecation Fixes**: Migrated `Color.value` to `Color.toARGB32()` to remain compatible with the latest Flutter stable releases.
* **Lazy Loading**: Fixed transition bugs when switching Power3D from `lazy: true` to `false`.

## Documentation
* Comprehensive update to `doc/advanced_selection.md` and basic selection guides.
* New implementation plans and walkthroughs for contributors.

---

# 1.0.0

* Initial release of Power3D.
* Support for loading 3D models (GLB/GLTF) from assets, network, and files.
* Advanced camera controls: auto-rotation, zoom limits, and position locking.
* Interactive object selection and highlighting.
* Comprehensive lighting configuration with support for multiple lights.
* Screenshot capture functionality.
* Built-in and customizable loading/error widgets.
