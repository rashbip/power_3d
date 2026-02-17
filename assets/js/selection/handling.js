// Selection Handling Logic

function handleMeshSelection(mesh) {
    const meshName = mesh.name;
    
    if (selectedMeshes.has(meshName)) {
        // Deselect if already selected
        unselectPart(meshName);
    } else {
        // Clear previous selection if not in multiple mode
        if (!selectionConfig.multipleSelection) {
            clearSelection();
        }
        selectPart(meshName);
    }

    // Notify Flutter
    sendMessageToFlutter({
        type: 'partSelected',
        partName: meshName,
        selected: selectedMeshes.has(meshName)
    });
}

function selectPart(partName) {
    if (!window.scene) return;
    
    const mesh = window.scene.getMeshByName(partName);
    if (!mesh) return;

    // Clear previous selections if not in multiple mode and we're selecting a new part
    if (!selectionConfig.multipleSelection && !selectedMeshes.has(partName)) {
        clearSelection();
    }

    selectedMeshes.add(partName);

    // Apply selection style (this will also store original state)
    applySelectionStyle(mesh, selectionConfig.selectionStyle);
    
    // Apply transformations
    applySelectionTransform(mesh, selectionConfig.scaleSelection, selectionConfig.selectionShift);

    // Update unselected meshes
    updateUnselectedParts();
}

function unselectPart(partName) {
    if (!window.scene) return;
    
    const mesh = window.scene.getMeshByName(partName);
    if (!mesh) return;

    selectedMeshes.delete(partName);

    // Restore original state using unified logic
    restoreMeshOriginalState(mesh);

    updateUnselectedParts();
}

function clearSelection() {
    // We can't just clear the set because we need to restore each part
    const partsToUnselect = Array.from(selectedMeshes);
    selectedMeshes.clear();
    
    partsToUnselect.forEach(partName => {
        const mesh = window.scene.getMeshByName(partName);
        if (mesh) restoreMeshOriginalState(mesh);
    });

    // This will restore all other meshes that had unselected style because size is now 0
    updateUnselectedParts();
}
