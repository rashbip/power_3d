# Object Parts Feature Documentation

## Overview
The objectParts feature enables fine-grained control over individual components of a 3D model, allowing developers to easily manage and manipulate different parts of a model independently.

## Key Components

### Power3DPart

```dart
class Power3DPart {
  final String id;
  final String name;
  final Map<String, dynamic> metadata;
}
```

**Properties:**
- `id`: Unique identifier for the part (e.g., "engine")
- `name`: Human-friendly name of the part (e.g., "Car Engine")
- `metadata`: Additional properties related to the part

### Power3DState

The Power3DState class has been extended with the following properties:
- `List<Power3DPart> parts`: Returns a list of all parts contained in the 3D model
- `String? selectedPartId`: Contains the ID of the currently selected part or null if no part is selected

## Usage

### Getting Parts List
```dart
// Get the number of parts in the model
int partCount = power3DController.state.parts.length;

// Get specific part information
Power3DPart engine = power3DController.state.parts
    .firstWhere((part) => part.id == "engine");

print("Part name: ${engine.name}");
print("Part metadata: ${engine.metadata}");
```

### Getting Parts with Specific Properties
```dart
// Get all parts with a specific property
List<Power3DPart> getPartsWithMaterial(String material) {
  return power3DController.state.parts.where((part) => 
      part.metadata['material'] == material).toList();
}
```

### Handling Parts in the UI
```dart
ListView.builder(
  itemCount: power3DController.state.parts.length,
  itemBuilder: (context, index) {
    Power3DPart part = power3DController.state.parts[index];
    
    return ListTile(
      title: Text(part.name),
      subtitle: Text("ID: ${part.id}"),
      trailing: IconButton(
        icon: Icon(Icons.edit),
        onPressed: () {
          // Select a specific part
          power3DController.selectPart(part.id);
        },
      ),
    );
  },
);

// In your controller
void selectPart(String partId) {
  _controller.value = _controller.value.copyWith(
    selectedPartId: partId,
  );
}
```

## Best Practices

1. **Check for Empty Parts:**
Always verify that a model has parts before accessing them:
```dart
if (power3DController.state.parts.isNotEmpty) {
  // Access parts
}
```

2. **Update Parts Safely:**
Use the copyWith method to modify parts safely:
```dart
Power3DState updatedState = power3DController.state.copyWith(
  parts: power3DController.state.parts.map((part) {
    if (part.id == "engine") {
      // Modify engine metadata
      return part.copyWith(
        metadata: {
          ...part.metadata,
          'temperature': 500
        }
      );
    }
    return part;
  }).toList(),
);
```

3. **Combine with Other Features:**
Take advantage of the integration between object parts and other features:
```dart
void highlightPart(String partId) {
  power3DController.state.parts.firstWhere((part) => part.id == partId);
  
  // Change material of the part
  power3DController.changeMaterial(MaterialConfig(
    color: Colors.red,
    metallic: 0.8,
    roughness: 0.2,
  ));
  
  // Set this as the global material for simplicity
  power3DController.applyGlobalMaterial();
}
```
