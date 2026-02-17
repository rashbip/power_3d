// Selection and Object Parts management
let selectionConfig = {
    enabled: false,
    multipleSelection: false,
    selectionStyle: null,
    unselectedStyle: null,
    scaleSelection: 1.0,
    selectionShift: { x: 0, y: 0, z: 0 }
};

let selectedMeshes = new Set();
let originalMeshStates = new Map(); // Store original transforms and materials

// Initialize selection on canvas click
function initializeSelection() {
    if (!window.canvas || !window.scene) return;

    window.canvas.addEventListener('pointerdown', (evt) => {
        if (!selectionConfig.enabled) return;
        
        const pickResult = window.scene.pick(
            window.scene.pointerX,
            window.scene.pointerY
        );

        if (pickResult.hit && pickResult.pickedMesh) {
            handleMeshSelection(pickResult.pickedMesh);
        }
    });
}

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

function enableSelectionMode(config) {
    selectionConfig = { ...selectionConfig, ...config };
}

function getPartsList() {
    if (!window.scene) return [];
    
    const parts = window.scene.meshes
        .filter(m => m.name && !m.name.startsWith('__'))
        .map(m => m.name);
    
    return parts;
}

function selectPart(partName) {
    if (!window.scene) return;
    
    const mesh = window.scene.getMeshByName(partName);
    if (!mesh) return;

    // Store original state if not already stored
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

    selectedMeshes.add(partName);

    // Apply selection style
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

    // Restore original state
    const originalState = originalMeshStates.get(partName);
    if (originalState) {
        mesh.position = originalState.position.clone();
        mesh.scaling = originalState.scaling.clone();
        
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

    updateUnselectedParts();
}

function clearSelection() {
    const partsToUnselect = Array.from(selectedMeshes);
    partsToUnselect.forEach(partName => unselectPart(partName));
}

function updateUnselectedParts() {
    if (!window.scene || !selectionConfig.unselectedStyle) return;

    window.scene.meshes.forEach(mesh => {
        if (mesh.name && !selectedMeshes.has(mesh.name)) {
            applySelectionStyle(mesh, selectionConfig.unselectedStyle);
        }
    });
}

function applySelectionStyle(mesh, style) {
    if (!style || !mesh.material) return;

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
    if (scale !== 1.0) {
        mesh.scaling.scaleInPlace(scale);
    }

    if (shift && (shift.x !== 0 || shift.y !== 0 || shift.z !== 0)) {
        mesh.position.addInPlace(new BABYLON.Vector3(shift.x, shift.y, shift.z));
    }
}

function hexToColor3(hex) {
    if (hex.startsWith('#')) {
        hex = hex.substring(1);
    }
    if (hex.length === 8) {
        hex = hex.substring(2); // Remove alpha
    }
    return BABYLON.Color3.FromHexString('#' + hex);
}

// Send parts list to Flutter
function sendPartsListToFlutter() {
    const parts = getPartsList();
    sendMessageToFlutter({
        type: 'partsList',
        parts: parts
    });
}
