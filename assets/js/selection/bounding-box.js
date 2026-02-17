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
    const lineWidth = config.lineWidth || 1;
    const style = config.style || 'cube';
    
    partIdentifiers.forEach(id => {
        let mesh = window.scene.getMeshByName(id);
        if (!mesh) {
            const numericId = parseInt(id);
            if (!isNaN(numericId)) {
                mesh = window.scene.getMeshByUniqueId(numericId);
            }
        }
        
        if (!mesh) return;
        
        // Remove existing
        hideBoundingBox([id]);
        
        if (style === 'cube' || style === 'simple') {
            const gizmo = new BABYLON.BoundingBoxGizmo(color, gizmoLayer);
            gizmo.attachedMesh = mesh;
            
            // Adjust line thickness (Babylon doesn't have direct thickness for this gizmo easily, 
            // but we can scale the handles)
            if (style === 'simple') {
                gizmo.scaleBoxSize = 0;
                gizmo.rotationSphereSize = 0;
            } else {
                // User said handles look like cubes, let's make them smaller and sleeker
                gizmo.scaleBoxSize = 0.05;
                gizmo.rotationSphereSize = 0.05;
            }
            
            boundingBoxHelpers.set(id, gizmo);
        } else if (style === 'sphere') {
            // Create a wireframe sphere around the mesh
            const bounds = mesh.getHierarchyBoundingVectors();
            const center = bounds.min.add(bounds.max).scale(0.5);
            const size = bounds.max.subtract(bounds.min);
            const radius = size.length() * 0.5;
            
            const sphere = BABYLON.MeshBuilder.CreateSphere("bb_" + id, {
                diameter: radius * 2,
                segments: 16
            }, window.scene);
            
            sphere.position = center;
            
            const mat = new BABYLON.StandardMaterial("bb_mat_" + id, window.scene);
            mat.diffuseColor = color;
            mat.emissiveColor = color;
            mat.wireframe = true;
            mat.disableLighting = true;
            sphere.material = mat;
            
            // Make it non-pickable
            sphere.isPickable = false;
            
            boundingBoxHelpers.set(id, sphere);
        }
    });
}

function hideBoundingBox(partIdentifiers) {
    if (!Array.isArray(partIdentifiers)) return;
    
    partIdentifiers.forEach(id => {
        const helper = boundingBoxHelpers.get(id);
        if (helper) {
            if (helper.dispose) {
                helper.dispose();
            }
            boundingBoxHelpers.delete(id);
        }
    });
}
