// Selection Bounding Box Visualization

function showBoundingBox(partNames, config = {}) {
    if (!window.scene || !Array.isArray(partNames)) return;
    
    const color = config.color ? hexToColor3(config.color) : new BABYLON.Color3(0, 1, 0);
    const lineWidth = config.lineWidth || 2;
    
    const utilLayer = BABYLON.UtilityLayerRenderer.DefaultKeepDepthUtilityLayer;
    
    partNames.forEach(partName => {
        const mesh = window.scene.getMeshByName(partName);
        if (!mesh) return;
        
        // Remove existing bounding box if present
        hideBoundingBox([partName]);
        
        // Create bounding box
        const gizmo = new BABYLON.BoundingBoxGizmo(color, utilLayer);
        gizmo.attachedMesh = mesh;
        
        // Store reference
        boundingBoxHelpers.set(partName, gizmo);
    });
}

function hideBoundingBox(partNames) {
    if (!Array.isArray(partNames)) return;
    
    partNames.forEach(partName => {
        const gizmo = boundingBoxHelpers.get(partName);
        if (gizmo) {
            gizmo.dispose();
            boundingBoxHelpers.delete(partName);
        }
    });
}
