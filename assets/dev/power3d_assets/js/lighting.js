// Light management and shadow generation
let shadowGenerators = {};

function updateLighting(configs) {
    if (!window.scene) return;

    // Dispose old managed lights and shadows
    window.scene.lights.slice().forEach(l => {
        if (l.name.startsWith("managedLight_")) l.dispose();
    });
    Object.values(shadowGenerators).forEach(g => g.dispose());
    shadowGenerators = {};

    configs.forEach((config, index) => {
        const name = `managedLight_${index}`;
        const type = config.type;
        const intensity = config.intensity;
        const color = config.color;
        let light;

        if (type === 'hemispheric') {
            light = new BABYLON.HemisphericLight(name, new BABYLON.Vector3(0, 1, 0), window.scene);
        } else if (type === 'directional') {
            light = new BABYLON.DirectionalLight(name, new BABYLON.Vector3(0, -1, 1), window.scene);
        } else if (type === 'point') {
            light = new BABYLON.PointLight(name, new BABYLON.Vector3(0, 10, 0), window.scene);
        }

        if (light) {
            light.intensity = intensity;
            if (color) {
                light.diffuse = BABYLON.Color3.FromHexString(color);
            }

            if (config.direction && (light instanceof BABYLON.DirectionalLight)) {
                light.direction = new BABYLON.Vector3(config.direction.x, config.direction.y, 1);
            }

            // Shadow Handling
            if (config.castShadows && (light instanceof BABYLON.DirectionalLight || light instanceof BABYLON.PointLight)) {
                const generator = new BABYLON.ShadowGenerator(1024, light);
                generator.useBlurExponentialShadowMap = true;
                generator.blurKernel = config.shadowBlur || 32;
                
                // Add all existing meshes to shadow caster list
                window.scene.meshes.forEach(m => {
                    generator.addShadowCaster(m);
                    m.receiveShadows = true;
                });
                
                shadowGenerators[name] = generator;
            }
        }
    });
}

function updateSceneProcessing(exposure, contrast) {
    if (!window.scene) return;
    window.scene.imageProcessingConfiguration.isEnabled = true;
    window.scene.imageProcessingConfiguration.exposure = exposure;
    window.scene.imageProcessingConfiguration.contrast = contrast;
}
