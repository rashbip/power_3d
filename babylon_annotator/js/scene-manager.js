// Scene Manager: Handles Babylon.js initialization and rendering
let engine, scene, camera, guiTexture;

function initScene() {
    const canvas = document.getElementById("renderCanvas");
    engine = new BABYLON.Engine(canvas, true);
    
    scene = new BABYLON.Scene(engine);
    scene.clearColor = new BABYLON.Color4(0.05, 0.08, 0.16, 1);

    camera = new BABYLON.ArcRotateCamera("camera", -Math.PI / 2, Math.PI / 2.5, 3, new BABYLON.Vector3(0, 0, 0), scene);
    camera.attachControl(canvas, true);
    camera.wheelPrecision = 50;

    const light = new BABYLON.HemisphericLight("light", new BABYLON.Vector3(0, 1, 0), scene);
    light.intensity = 0.7;

    const dirLight = new BABYLON.DirectionalLight("dir01", new BABYLON.Vector3(-1, -2, -1), scene);
    dirLight.position = new BABYLON.Vector3(20, 40, 20);
    dirLight.intensity = 0.5;

    guiTexture = BABYLON.GUI.AdvancedDynamicTexture.CreateFullscreenUI("UI");

    engine.runRenderLoop(() => {
        scene.render();
    });

    window.addEventListener("resize", () => {
        engine.resize();
    });

    return { scene, camera, guiTexture };
}

async function loadModelFromFile(file) {
    if (!scene) return;
    
    updateStatus("Loading " + file.name + "...");
    
    // Clear existing meshes (except hotspots)
    scene.meshes.slice().forEach(m => {
        if (m.name !== "hotspot_mesh") m.dispose();
    });
    
    clearAllAnnotations();

    const reader = new FileReader();
    return new Promise((resolve) => {
        reader.onload = async (e) => {
            const data = e.target.result;
            BABYLON.SceneLoader.ImportMesh("", "", data, scene, (meshes) => {
                scene.createDefaultCameraOrLight(true, true, true);
                camera = scene.activeCamera;
                camera.attachControl(document.getElementById("renderCanvas"), true);
                updateStatus("Model Loaded: " + file.name);
                resolve(meshes);
            }, null, null, ".glb");
        };
        reader.readAsDataURL(file);
    });
}
