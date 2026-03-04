// Selection Material Modes

/**
 * Apply material/shading mode to selected or unselected parts
 * @param {string} mode - wireframe, xray, pointCloud, etc.
 * @param {boolean} applyToSelected - If true, apply to selected parts; if false, apply to unselected
 */
function applyMaterialModeToSelection(mode, applyToSelected = true) {
    if (!window.scene) return;
    
    window.scene.meshes.forEach(mesh => {
        if (mesh.name && mesh.name.startsWith('__')) return;
        if (!mesh.material) return;
        
        const idKey = mesh.uniqueId.toString();
        const isSelected = selectedMeshes.has(idKey);
        const shouldApply = applyToSelected ? isSelected : !isSelected;
        
        if (shouldApply) {
            applyMaterialModeToMesh(mesh, mode);
            partMaterialModes.set(idKey, mode);
        }
    });
}

function applyMaterialModeToMesh(mesh, mode) {
    const mat = mesh.material;
    if (!mat) return;
    
    // Reset
    mat.wireframe = false;
    mat.pointsCloud = false;
    if (mat.unlit !== undefined) mat.unlit = false;
    if (mat.disableLighting !== undefined) mat.disableLighting = false;
    
    if (mesh._originalAlpha === undefined) {
        mesh._originalAlpha = mat.alpha;
    }
    mat.alpha = mesh._originalAlpha;
    
    switch (mode) {
        case 'wireframe':
            mat.wireframe = true;
            break;
        case 'pointCloud':
            mat.pointsCloud = true;
            break;
        case 'xray':
            mat.alpha = 0.2;
            break;
        case 'unlit':
            if (mat.unlit !== undefined) mat.unlit = true;
            if (mat.disableLighting !== undefined) mat.disableLighting = true;
            break;
        case 'shaded':
        default:
            // Already reset above
            break;
    }
}
