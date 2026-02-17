// Selection Visibility Controls

function hideParts(identifiers) {
    if (!window.scene || !Array.isArray(identifiers)) return;
    
    identifiers.forEach(identifier => {
        let mesh = null;
        const numericId = parseInt(identifier);
        if (!isNaN(numericId)) {
            mesh = window.scene.getMeshByUniqueId(numericId);
        }
        
        if (!mesh) {
            mesh = window.scene.getMeshByName(identifier);
        }

        if (mesh) {
            mesh.isVisible = false;
            visibilityState.set(mesh.uniqueId.toString(), false);
        }
    });
}

function showParts(identifiers) {
    if (!window.scene || !Array.isArray(identifiers)) return;
    
    identifiers.forEach(identifier => {
        let mesh = null;
        const numericId = parseInt(identifier);
        if (!isNaN(numericId)) {
            mesh = window.scene.getMeshByUniqueId(numericId);
        }
        
        if (!mesh) {
            mesh = window.scene.getMeshByName(identifier);
        }

        if (mesh) {
            mesh.isVisible = true;
            visibilityState.set(mesh.uniqueId.toString(), true);
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
        if (mesh.name && !mesh.name.startsWith('__')) {
            const idKey = mesh.uniqueId.toString();
            if (!selectedMeshes.has(idKey)) {
                unselectedParts.push(idKey);
            }
        }
    });
    
    hideParts(unselectedParts);
}

function unhideAll() {
    if (!window.scene) return;
    
    const allParts = [];
    window.scene.meshes.forEach(mesh => {
        if (mesh.name && !mesh.name.startsWith('__')) {
            allParts.push(mesh.uniqueId.toString());
        }
    });
    
    showParts(allParts);
}
