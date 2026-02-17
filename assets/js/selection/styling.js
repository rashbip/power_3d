// Selection Styling Logic

function updateUnselectedParts() {
    if (!window.scene || !selectionConfig.unselectedStyle) return;

    // If nothing is selected, restore all meshes to original state
    if (selectedMeshes.size === 0) {
        window.scene.meshes.forEach(mesh => {
            if (mesh.name && !mesh.name.startsWith('__')) {
                restoreMeshOriginalState(mesh);
            }
        });
        return;
    }

    // Apply unselected style to all non-selected meshes
    window.scene.meshes.forEach(mesh => {
        if (mesh.name && !mesh.name.startsWith('__')) {
             if (!selectedMeshes.has(mesh.name)) {
                applySelectionStyle(mesh, selectionConfig.unselectedStyle);
             }
        }
    });
}

function storeMeshOriginalState(mesh) {
    const partName = mesh.name;
    if (!originalMeshStates.has(partName)) {
        originalMeshStates.set(partName, {
            position: mesh.position.clone(),
            scaling: mesh.scaling.clone(),
            material: mesh.material ? {
                ambient: mesh.material.ambientColor?.clone(),
                diffuse: mesh.material.diffuseColor?.clone(),
                emissive: mesh.material.emissiveColor?.clone(),
            } : null
        });
    }
}

function restoreMeshOriginalState(mesh) {
    const partName = mesh.name;
    const originalState = originalMeshStates.get(partName);
    if (originalState) {
        // Restore transforms
        mesh.position.copyFrom(originalState.position);
        mesh.scaling.copyFrom(originalState.scaling);
        
        // Restore materials
        if (mesh.material && originalState.material) {
            if (mesh.material.ambientColor) mesh.material.ambientColor = originalState.material.ambient?.clone();
            if (mesh.material.diffuseColor) mesh.material.diffuseColor = originalState.material.diffuse?.clone();
            if (mesh.material.emissiveColor) mesh.material.emissiveColor = originalState.material.emissive?.clone();
        }
        
        originalMeshStates.delete(partName);
    }

    // Remove highlight layer if exists
    if (window.highlightLayer && mesh._highlightedBy) {
        window.highlightLayer.removeMesh(mesh);
        delete mesh._highlightedBy;
    }
}

function applySelectionStyle(mesh, style) {
    if (!style || !mesh.material) return;

    // Ensure we store original state BEFORE modifying
    storeMeshOriginalState(mesh);

    if (style.highlightColor) {
        const color = hexToColor3(style.highlightColor);
        if (mesh.material.emissiveColor) {
            mesh.material.emissiveColor = color;
        }
    }

    if (style.outlineColor && style.outlineWidth) {
        if (!window.highlightLayer) {
            window.highlightLayer = new BABYLON.HighlightLayer("highlightLayer", window.scene);
        }
        
        const outlineColor = hexToColor3(style.outlineColor);
        window.highlightLayer.addMesh(mesh, new BABYLON.Color3(outlineColor.r, outlineColor.g, outlineColor.b));
        mesh._highlightedBy = true;
    }
}

function applySelectionTransform(mesh, scale, shift) {
    const meshName = mesh.name;
    const originalState = originalMeshStates.get(meshName);
    
    if (!originalState) return;
    
    // Reset to original first (for realtime updates)
    mesh.position.copyFrom(originalState.position);
    mesh.scaling.copyFrom(originalState.scaling);
    
    // Apply new transforms
    if (scale !== 1.0) {
        mesh.scaling.scaleInPlace(scale);
    }

    if (shift && (shift.x !== 0 || shift.y !== 0 || shift.z !== 0)) {
        mesh.position.addInPlace(new BABYLON.Vector3(shift.x, shift.y, shift.z));
    }
}
