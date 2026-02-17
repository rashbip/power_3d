// Selection Visibility Controls

function hideParts(partNames) {
    if (!window.scene || !Array.isArray(partNames)) return;
    
    partNames.forEach(partName => {
        const mesh = window.scene.getMeshByName(partName);
        if (mesh) {
            mesh.isVisible = false;
            visibilityState.set(partName, false);
        }
    });
}

function showParts(partNames) {
    if (!window.scene || !Array.isArray(partNames)) return;
    
    partNames.forEach(partName => {
        const mesh = window.scene.getMeshByName(partName);
        if (mesh) {
            mesh.isVisible = true;
            visibilityState.set(partName, true);
        }
    });
}

function hideSelected() {
    const partsArray = Array.from(selectedMeshes);
    hideParts(partsArray);
}

function hideUnselected() {
    if (!window.scene) return;
    
    const unselectedParts = [];
    window.scene.meshes.forEach(mesh => {
        if (mesh.name && !mesh.name.startsWith('__') && !selectedMeshes.has(mesh.name)) {
            unselectedParts.push(mesh.name);
        }
    });
    
    hideParts(unselectedParts);
}

function unhideAll() {
    if (!window.scene) return;
    
    const allParts = [];
    window.scene.meshes.forEach(mesh => {
        if (mesh.name && !mesh.name.startsWith('__')) {
            allParts.push(mesh.name);
        }
    });
    
    showParts(allParts);
}
