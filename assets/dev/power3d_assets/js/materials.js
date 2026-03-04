// Material and Shading Mode management

function updateShadingMode(mode) {
    if (!window.scene) return;

    window.scene.meshes.forEach(mesh => {
        const mat = mesh.material;
        if (!mat) return;

        // Reset
        mat.wireframe = false;
        mat.pointsCloud = false;
        if (mat.debugMode !== undefined) mat.debugMode = 0;
        if (mat.unlit !== undefined) mat.unlit = false;
        if (mat.disableLighting !== undefined) mat.disableLighting = false;
        
        if (mesh._originalAlpha === undefined) {
            mesh._originalAlpha = mat.alpha;
        }
        mat.alpha = mesh._originalAlpha;
        
        // Restore texture if it was uvChecker
        if (mesh._isUVChecker && mesh._originalTexture !== undefined) {
            if (mat.albedoTexture !== undefined) mat.albedoTexture = mesh._originalTexture;
            else if (mat.diffuseTexture !== undefined) mat.diffuseTexture = mesh._originalTexture;
            mesh._isUVChecker = false;
        }

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
            case 'normals':
                if (mat.debugMode !== undefined) mat.debugMode = 1; // DEBUG_NORMALS
                break;
            case 'roughness':
                if (mat.debugMode !== undefined) mat.debugMode = 9; // DEBUG_ROUGHNESS
                break;
            case 'metallic':
                if (mat.debugMode !== undefined) mat.debugMode = 8; // DEBUG_METALLIC
                break;
            case 'uvChecker':
                if (!mesh._isUVChecker) {
                    mesh._originalTexture = mat.albedoTexture || mat.diffuseTexture || null;
                    const checker = new BABYLON.Texture("https://playground.babylonjs.com/textures/amiga.jpg", window.scene);
                    if (mat.albedoTexture !== undefined) mat.albedoTexture = checker;
                    else mat.diffuseTexture = checker;
                    mesh._isUVChecker = true;
                }
                break;
            case 'shaded':
            default:
                break;
        }
    });
}

function updateGlobalMaterial(config) {
    if (!window.scene) return;

    window.scene.meshes.forEach(mesh => {
        const mat = mesh.material;
        if (!mat) return;

        if (config.color) {
            const color = BABYLON.Color3.FromHexString(config.color);
            if (mat.albedoColor) mat.albedoColor = color;
            else if (mat.diffuseColor) mat.diffuseColor = color;
        }
        
        if (config.metallic !== null && config.metallic !== undefined) {
            if (mat.metallic !== undefined) mat.metallic = config.metallic;
        }
        
        if (config.roughness !== null && config.roughness !== undefined) {
            if (mat.roughness !== undefined) mat.roughness = config.roughness;
        }
        
        if (config.alpha !== null && config.alpha !== undefined) {
            mat.alpha = config.alpha;
            mesh._originalAlpha = config.alpha;
        }
        
        if (config.emissiveColor) {
            const eColor = BABYLON.Color3.FromHexString(config.emissiveColor);
            if (mat.emissiveColor) mat.emissiveColor = eColor;
        }

        if (config.doubleSided !== null && config.doubleSided !== undefined) {
            mat.backFaceCulling = !config.doubleSided;
        }
    });
}
