// Selection Core Configuration and State
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
let visibilityState = new Map(); // Track hidden/shown parts
let boundingBoxHelpers = new Map(); // Track bounding box visualizations
let partMaterialModes = new Map(); // Track material modes per part

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

function enableSelectionMode(config) {
    selectionConfig = { ...selectionConfig, ...config };
    
    // Reapply styles and transforms to all selected parts (for realtime updates)
    if (window.scene) {
        selectedMeshes.forEach(partName => {
            const mesh = window.scene.getMeshByName(partName);
            if (mesh) {
                // Reapply style
                applySelectionStyle(mesh, selectionConfig.selectionStyle);
                // Reapply transform
                applySelectionTransform(mesh, selectionConfig.scaleSelection, selectionConfig.selectionShift);
            }
        });
        
        // Update unselected parts styling
        updateUnselectedParts();
    }
}
