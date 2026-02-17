// Selection Bounding Box Visualization

// Helper to get or create a utility layer for gizmos
function getGizmoLayer() {
    if (!window.scene) return null;
    
    if (!window._gizmoLayer || window._gizmoLayer.originalScene !== window.scene) {
        // Dispose old layer if it exists
        if (window._gizmoLayer) {
            window._gizmoLayer.dispose();
        }
        // Create new utility layer for the current scene
        window._gizmoLayer = new BABYLON.UtilityLayerRenderer(window.scene);
    }
    return window._gizmoLayer;
}

function showBoundingBox(partIdentifiers, config = {}) {
    if (!window.scene || !Array.isArray(partIdentifiers)) return;
    
    const gizmoLayer = getGizmoLayer();
    if (!gizmoLayer) return;
    
    const color = config.color ? hexToColor3(config.color) : new BABYLON.Color3(0, 1, 0);
    const lineWidth = config.lineWidth || 2;
    
    partIdentifiers.forEach(id => {
        // Try to find mesh by name first, then by uniqueId
        let mesh = window.scene.getMeshByName(id);
        if (!mesh) {
            const numericId = parseInt(id);
            if (!isNaN(numericId)) {
                mesh = window.scene.getMeshByUniqueId(numericId);
            }
        }
        
        if (!mesh) return;
        
        // Remove existing bounding box if present
        hideBoundingBox([id]);
        
        // Create bounding box - explicitly pass color and our managed gizmo layer
        const gizmo = new BABYLON.BoundingBoxGizmo(color, gizmoLayer);
        gizmo.attachedMesh = mesh;
        
        // Store reference by the identifier passed in
        boundingBoxHelpers.set(id, gizmo);
    });
}

function hideBoundingBox(partIdentifiers) {
    if (!Array.isArray(partIdentifiers)) return;
    
    partIdentifiers.forEach(id => {
        const gizmo = boundingBoxHelpers.get(id);
        if (gizmo) {
            gizmo.dispose();
            boundingBoxHelpers.delete(id);
        }
    });
}
