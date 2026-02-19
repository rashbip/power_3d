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

    // Register update loop for slider
    engine.onEndFrameObservable.add(() => {
        if (activeAnimGroups && activeAnimGroups.length > 0) {
            const select = document.getElementById("animationSelect");
            const group = activeAnimGroups[select.value];
            if (group && group.isPlaying && group.animatables && group.animatables.length > 0) {
                const slider = document.getElementById("animSlider");
                slider.value = group.animatables[0].masterFrame;
            }
        }
    });

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
                setupAnimations();
                resolve(meshes);
            }, null, null, ".glb");
        };
        reader.readAsDataURL(file);
    });
}

async function loadModelByUrl(url) {
    if (!scene || !url) return;
    updateStatus("Loading model from URL...");
    
    scene.meshes.slice().forEach(m => {
        if (m.name !== "hotspot_mesh") m.dispose();
    });
    
    clearAllAnnotations();

    try {
        const meshes = await BABYLON.SceneLoader.ImportMeshAsync("", "", url, scene, null, ".glb");
        scene.createDefaultCameraOrLight(true, true, true);
        camera = scene.activeCamera;
        camera.attachControl(document.getElementById("renderCanvas"), true);
        updateStatus("Model Loaded from URL");
        setupAnimations();
        return meshes;
    } catch (e) {
        updateStatus("Error loading model: " + e.message);
        console.error(e);
    }
}

function randomizeBackground() {
    if (!scene) return;
    const r = Math.random();
    const g = Math.random();
    const b = Math.random();
    scene.clearColor = new BABYLON.Color4(r, g, b, 1);
    updateStatus(`Background changed to RGB(${Math.round(r*255)}, ${Math.round(g*255)}, ${Math.round(b*255)})`);
}

// Animation Controls
let activeAnimGroups = [];

function setupAnimations() {
    if (!scene) return;
    activeAnimGroups = scene.animationGroups;
    
    const panel = document.getElementById("animationPanel");
    const select = document.getElementById("animationSelect");
    
    if (activeAnimGroups.length > 0) {
        panel.classList.remove("hidden");
        select.innerHTML = "";
        activeAnimGroups.forEach((group, index) => {
            const option = document.createElement("option");
            option.value = index;
            option.text = group.name || `Animation ${index + 1}`;
            select.add(option);
        });
        
        // Update slider range based on first animation
        updateSliderRange(0);
    } else {
        panel.classList.add("hidden");
    }
}

function updateSliderRange(index) {
    const group = activeAnimGroups[index];
    if (!group) return;
    const slider = document.getElementById("animSlider");
    slider.min = group.from;
    slider.max = group.to;
    slider.value = group.from;
}

function playAnimation(index, loop = true) {
    const group = activeAnimGroups[index];
    if (group) group.play(loop);
}

function pauseAnimation(index) {
    const group = activeAnimGroups[index];
    if (group) group.pause();
}

function stopAnimation(index) {
    const group = activeAnimGroups[index];
    if (group) {
        group.stop();
        document.getElementById("animSlider").value = group.from;
    }
}

function scrubAnimation(index, frame) {
    const group = activeAnimGroups[index];
    if (group) {
        group.pause();
        group.goToFrame(frame);
    }
}

function setAnimationSpeed(index, speed) {
    const group = activeAnimGroups[index];
    if (group) group.speedRatio = speed;
}
