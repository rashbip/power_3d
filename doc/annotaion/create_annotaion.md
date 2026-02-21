# Babylon Annotator Guide

The **Babylon Annotator** is a precision tool for placing interactive hotspots on 3D models. It allows you to define points of interest with metadata and export/import them for use in your applications.

---

## 1. Getting Started

### Loading a Model

- **Drag & Drop**: Drag any `.glb` or `.gltf` file directly onto the viewport.
- **File Picker**: Click the central drop zone to browse your local files.
- **URL**: Paste a direct link to a GLB file in the "Load from URL" field and click **Go**.

### Navigation

- **Rotate**: Left-click and drag.
- **Zoom**: Use the mouse scroll wheel.
- **Pan**: Right-click and drag.
- **Sensitivity**: Use the **Mouse Sensitivity** slider in the sidebar to adjust how fast the camera responds to your movements. lower values are better for precise work.
- **Reset View**: Click **Reset View** in the annotation list panel to snap the camera back to its default framing.

---

## 2. Creating Annotations

1. Click the **Create New Annotation** button in the sidebar.
2. **Click the Model**: Hover over the 3D surface and click. A white **Preview Dot** will appear instantly.
3. **Fill the Details**:
   - **Title**: The main label for the hotspot.
   - **Description**: Detailed information shown in tooltips.
   - **Constraints**: Set min/max visibility distances (useful for complex interiors).
4. Click **Add**. The preview dot turns blue (or your selected color) and appears in the sidebar list.

---

## 3. Managing Annotations

### Selection & Sync

- **Sidebar to 3D**: Clicking an annotation in the list will highlight it in the 3D view and scroll the list to it.
- **3D to Sidebar**: Clicking a marker directly in the 3D viewport will select and scroll to its corresponding list item.
- **Focus (🎯)**: Click the target icon on a list item to smoothly animate the camera back to the exact viewpoint where the annotation was originally placed.

### Editing (✏️)

- Click the **Edit Icon** on any existing annotation to modify its title, description, or visibility settings.
- Click **Update** to save your changes.

### Deleting (🗑)

- **Individual**: Click the trash icon on a list item to remove it.
- **Clear All**: Use the red trash button at the top of the list to wipe all annotations (confirmation required).

---

## 4. Import & Export

The annotator supports both **JSON** and **CSV** formats.

### Exporting

- **JSON**: Click the **JSON** button to copy the complete data structure (including IDs and barycentric coordinates) to your clipboard.
- **CSV**: Click the **CSV** button for a spreadsheet-compatible format of your data.

### Importing (📥)

- Click the **Import Icon** (📥) next to "Reset View".
- Select a valid `.json` or `.csv` file.
- **Precision Recovery**: The tool uses barycentric coordinates to reconstruct the exact world position on the surface, ensuring markers stay perfectly pinned even if the model is transformed.

---

## 5. Visual Controls

### Model Transform

- **Marker Size**: Adjust the size of the hotspot dots from tiny points to large indicators.
- **Model Scale**: Resize the model itself for better viewing.
- **Position (X/Y/Z)**: Move the model within the 3D space.

### Environment

- **Brightness**: Adjust the light intensity on the model.
- **Background**: Change the background color or use the **Randomize** button for quick contrast testing.
