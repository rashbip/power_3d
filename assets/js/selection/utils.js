// Selection Utilities

function hexToColor3(hex) {
    if (hex.startsWith('#')) {
        hex = hex.substring(1);
    }
    if (hex.length === 8) {
        hex = hex.substring(2); // Remove alpha
    }
    return BABYLON.Color3.FromHexString('#' + hex);
}

function getPartsList() {
    if (!window.scene) return [];
    
    const parts = window.scene.meshes
        .filter(m => m.name && !m.name.startsWith('__'))
        .map(m => m.name);
    
    return parts;
}

// Send parts list to Flutter
function sendPartsListToFlutter() {
    const parts = getPartsList();
    sendMessageToFlutter({
        type: 'partsList',
        parts: parts
    });
}
