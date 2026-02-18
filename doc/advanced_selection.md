# Advanced Selection Features

Power3D now provides comprehensive selection capabilities including hierarchical part trees, visibility controls, bounding box visualization, and per-selection material modes.

---

## Overview

The advanced selection system extends the basic selection features with:

- **Hierarchical Parts Tree**: View parts in their scene graph structure or categorized by naming
- **Visibility Controls**: Hide/show individual parts or groups
- **Bounding Box Visualization**: Display wireframe bounding boxes around parts
- **Material Modes for Selection**: Apply different shading modes to selected vs unselected parts
- **Node Extras Extraction**: Access GLTF metadata and extras from nodes

---

## Hierarchy Support

### Get Parts Hierarchy

Retrieve the hierarchical structure of parts in two modes:

```dart
// Scene graph mode (default) - uses parent-child relationships
final hierarchy = await controller.getPartsHierarchy(useCategorization: false);

// Categorization mode - parses names like "Category.PartName"
final hierarchy = await controller.getPartsHierarchy(useCategorization: true);
```

The hierarchy is returned as a nested map:

```dart
{
  "name": "root",
  "children": [
    {
      "name": "Fascia",
      "type": "category",
      "children": [
        {
          "name": "Brachial_fascia.r",
          "displayName": "Brachial fascia.r",
          "type": "mesh",
          "children": []
        }
      ]
    }
  ]
}
```

### Get Node Extras

Extract metadata and custom GLTF extras from a part:

```dart
final extras = await controller.getNodeExtras('partName');
// Returns:
// {
//   "name": "LeftVentricle",
//   "id": "mesh_123",
//   "uniqueId": 456,
//   "metadata": {...},
//   "extras": {
//     "label": "Left Ventricle",
//     "description": "The left ventricle pumps oxygenated blood...",
//     "category": "Cardiac Chambers",
//     "colorHighlight": "#ff4444"
//   }
// }
```

---

## Visibility Controls

### Hide/Show Parts

Control the visibility of individual parts or groups:

```dart
// Hide specific parts
await controller.hideParts(['part1', 'part2']);

// Show specific parts
await controller.showParts(['part1', 'part2']);

// Hide all selected parts
await controller.hideSelected();

// Hide all unselected parts (show only selected)
await controller.hideUnselected();

// Show all parts
await controller.unhideAll();
```

### Track Visibility State

The visibility state is automatically tracked:

```dart
controller.addListener(() {
  final hiddenParts = controller.value.hiddenParts;
  print('Hidden parts: $hiddenParts');
});
```

---

## Bounding Box Visualization

### Show Bounding Boxes

Display wireframe bounding boxes around parts:

```dart
// Show bounding boxes with default config
await controller.showBoundingBox(['part1', 'part2']);

// Show with custom configuration
await controller.showBoundingBox(
  ['part1', 'part2'],
  config: const BoundingBoxConfig(
    color: Colors.greenAccent,
    lineWidth: 2.5,
    showDimensions: false,
  ),
);

// Hide bounding boxes
await controller.hideBoundingBox(['part1', 'part2']);
```

### BoundingBoxConfig

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `color` | `Color` | `Colors.green` | Color of the bounding box lines |
| `lineWidth` | `double` | `1.0` | Width of the bounding box lines |
| `style` | `BoundingBoxStyle` | `cube` | Visual style: `cube`, `sphere`, or `simple` |
| `showDimensions` | `bool` | `false` | Whether to show dimension measurements |

### BoundingBoxStyle

- **`cube`**: Standard box with small adjustment handles.
- **`simple`**: A clean wireframe box without any handles.
- **`sphere`**: A wireframe sphere encompassing the selection.

---

## Material Modes for Selection

Apply different material/shading modes to selected or unselected parts independently:

```dart
// Apply wireframe to selected parts only
await controller.applyMaterialModeToSelection(
  ShadingMode.wireframe,
  applyToSelected: true,
);

// Apply x-ray to unselected parts
await controller.applyMaterialModeToSelection(
  ShadingMode.xray,
  applyToSelected: false,
);

// Reset all to default shading
await controller.setShadingMode(ShadingMode.shaded);
```

Supported modes:
- `ShadingMode.shaded` - Default lit rendering
- `ShadingMode.wireframe` - Show mesh wireframe
- `ShadingMode.xray` - Semi-transparent rendering
- `ShadingMode.pointCloud` - Show vertices only
- `ShadingMode.unlit` - Flat colors without lighting
- `ShadingMode.normals` - Visualize surface normals
- `ShadingMode.roughness` - Show roughness values
- `ShadingMode.metallic` - Show metallic values
- `ShadingMode.uvChecker` - UV mapping visualization

---

## Complete Example

```dart
class AdvancedSelectionDemo extends StatefulWidget {
  @override
  State<AdvancedSelectionDemo> createState() => _AdvancedSelectionDemoState();
}

class _AdvancedSelectionDemoState extends State<AdvancedSelectionDemo> {
  late Power3DController controller;
  Map<String, dynamic>? hierarchy;

  @override
  void initState() {
    super.initState();
    controller = Power3DController();

    // Configure selection
    controller.updateSelectionConfig(SelectionConfig(
      enabled: true,
      multipleSelection: true,
      scaleSelection: 1.15,
      selectionShift: const SelectionShift(y: 0.2),
      selectionStyle: SelectionStyle(
        highlightColor: Colors.blueAccent.withValues(alpha: 0.7),
        outlineColor: Colors.blue,
        outlineWidth: 2.5,
      ),
    ));

    // Load hierarchy when model loads
    controller.addListener(() {
      if (controller.value.status == Power3DStatus.loaded) {
        _loadHierarchy();
      }
    });
  }

  Future<void> _loadHierarchy() async {
    final h = await controller.getPartsHierarchy();
    setState(() => hierarchy = h);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Power3D.fromAsset(
              'assets/model.glb',
              controller: controller,
            ),
          ),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, state, _) {
        return Column(
          children: [
            // Visibility controls
            ElevatedButton(
              onPressed: state.selectedParts.isEmpty
                  ? null
                  : () => controller.hideSelected(),
              child: const Text('Hide Selected'),
            ),
            ElevatedButton(
              onPressed: () => controller.unhideAll(),
              child: const Text('Show All'),
            ),
            
            // Bounding boxes
            CheckboxListTile(
              title: const Text('Show Bounding Boxes'),
              value: state.boundingBoxParts.isNotEmpty,
              onChanged: (v) {
                if (v!) {
                  controller.showBoundingBox(state.selectedParts);
                } else {
                  controller.hideBoundingBox(state.boundingBoxParts);
                }
              },
            ),
            
            // Material modes
            ElevatedButton(
              onPressed: () => controller.applyMaterialModeToSelection(
                ShadingMode.wireframe,
                applyToSelected: true,
              ),
              child: const Text('Wireframe Selected'),
            ),
          ],
        );
      },
    );
  }
}
```

---

## State Tracking

The controller automatically tracks advanced selection state:

```dart
controller.value.hiddenParts;       // List<String> - Hidden part names
controller.value.boundingBoxParts;  // List<String> - Parts with visible bounding boxes
controller.value.partsHierarchy;    // Map<String, dynamic>? - Hierarchical structure
```

---

## Best Practices

1. **Load Hierarchy After Model**: Always fetch the hierarchy after the model has fully loaded
2. **Categorize Intelligently**: Use naming conventions like `Category.SubCategory.PartName` for automatic categorization
3. **Performance**: Be mindful when showing many bounding boxes simultaneously
4. **Material Modes**: Reset to `ShadingMode.shaded` before applying new modes to avoid conflicts
5. **Visibility State**: Track `hiddenParts` to maintain UI state consistency

---

## See Also

- [selection_and_parts.md](./selection_and_parts.md) - Basic selection features
- [Advanced Selection Example](../example/lib/options/advanced_selection_example.dart) - Complete working example
