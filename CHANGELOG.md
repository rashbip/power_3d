# 1.1.0

## Features
* **Advanced Selection System**: Complete overhaul with hierarchy support, visibility controls, and bounding boxes
  * Hierarchical parts tree with scene graph and categorization modes
  * Node extras extraction (GLTF metadata access)
  * Visibility controls: hide/show parts, hide selected/unselected, unhide all
  * Bounding box visualization with customizable colors and line widths
  * Per-selection material modes: apply different shading to selected vs unselected parts
  * New `BoundingBoxConfig` model for configuring bounding box appearance
  * State tracking for `hiddenParts`, `boundingBoxParts`, and `partsHierarchy`
* **Advanced Selection Example**: Comprehensive example with tabs for hierarchy, visibility, extras, and material modes

## Bug Fixes
* Fixed realtime transform updates not applying correctly when selection config changes
* Fixed unselected parts colors not resetting after clearing selection
* Fixed multi-selection toggle not being respected when clicking parts from Flutter

## Documentation
* Added `doc/advanced_selection.md` with comprehensive examples and API documentation
* Updated `doc/selection_and_parts.md` with latest best practices

---

# 1.0.0

* Initial release of Power3D.
* Support for loading 3D models (GLB/GLTF) from assets, network, and files.
* Advanced camera controls: auto-rotation, zoom limits, and position locking.
* Interactive object selection and highlighting.
* Comprehensive lighting configuration with support for multiple lights.
* Screenshot capture functionality.
* Built-in and customizable loading/error widgets.
