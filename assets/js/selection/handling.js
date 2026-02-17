// Selection Handling Logic

function handleMeshSelection(mesh) {
    const identifier = mesh.uniqueId.toString(); // Use uniqueId as primary identifier
    
    if (selectedMeshes.has(identifier)) {
        // Deselect if already selected
        unselectPart(identifier);
    } else {
        // Clear previous selection if not in multiple mode
        if (!selectionConfig.multipleSelection) {
            clearSelection();
        }
        selectPart(identifier);
    }

    // Notify Flutter
    sendMessageToFlutter({
        type: 'partSelected',
        partName: identifier, // Now sending uniqueId for better reliability
        meshName: mesh.name,   // Keep mesh name for convenience
        selected: selectedMeshes.has(identifier)
    });
}

function selectPart(identifier) {
    if (!window.scene) return;
    
    // Try to find mesh by uniqueId first, then by name
    let mesh = null;
    const numericId = parseInt(identifier);
    if (!isNaN(numericId)) {
        mesh = window.scene.getMeshByUniqueId(numericId);
    }
    
    if (!mesh) {
        mesh = window.scene.getMeshByName(identifier);
    }
    
    if (!mesh) return;

    const idKey = mesh.uniqueId.toString();

    // Clear previous selections if not in multiple mode and we're selecting a new part
    if (!selectionConfig.multipleSelection && !selectedMeshes.has(idKey)) {
        clearSelection();
    }

    selectedMeshes.add(idKey);

    // Apply selection style (this will also store original state)
    applySelectionStyle(mesh, selectionConfig.selectionStyle);
    
    // Apply transformations
    applySelectionTransform(mesh, selectionConfig.scaleSelection, selectionConfig.selectionShift);

    // Update unselected meshes
    updateUnselectedParts();
}

function unselectPart(identifier) {
    if (!window.scene) return;
    
    let mesh = null;
    const numericId = parseInt(identifier);
    if (!isNaN(numericId)) {
        mesh = window.scene.getMeshByUniqueId(numericId);
    }
    
    if (!mesh) {
        mesh = window.scene.getMeshByName(identifier);
    }
    
    if (!mesh) return;

    const idKey = mesh.uniqueId.toString();
    selectedMeshes.delete(idKey);

    // Restore original state using unified logic
    restoreMeshOriginalState(mesh);

    updateUnselectedParts();
}

function clearSelection() {
    // We can't just clear the set because we need to restore each part
    const identifiers = Array.from(selectedMeshes);
    selectedMeshes.clear();
    
    identifiers.forEach(identifier => {
        let mesh = null;
        const numericId = parseInt(identifier);
        if (!isNaN(numericId)) {
            mesh = window.scene.getMeshByUniqueId(numericId);
        }
        
        if (!mesh) {
            mesh = window.scene.getMeshByName(identifier);
        }

        if (mesh) restoreMeshOriginalState(mesh);
    });

    // This will restore all other meshes that had unselected style because size is now 0
    updateUnselectedParts();
}
