// Scene Manager: Handles Babylon.js initialization and rendering
let engine, scene, camera, guiTexture;

function initScene() {
    const canvas = document.getElementById("renderCanvas");
    // High precision engine for better texture stability
    engine = new BABYLON.Engine(canvas, true, { 
        antialias: true, 
        preserveDrawingBuffer: true, 
        stencil: true,
        adaptToDeviceRatio: true
    });
    
    scene = new BABYLON.Scene(engine);
    scene.clearColor = new BABYLON.Color4(0.05, 0.08, 0.16, 1);

    camera = new BABYLON.ArcRotateCamera("camera", -Math.PI / 2, Math.PI / 2.5, 3, new BABYLON.Vector3(0, 0, 0), scene);
    configureCamera(camera);
    camera.attachControl(canvas, true);

    const light = new BABYLON.HemisphericLight("hemiLight", new BABYLON.Vector3(0, 1, 0), scene);
    light.intensity = 0.5;

    const keyLight = new BABYLON.DirectionalLight("keyLight", new BABYLON.Vector3(-1, -2, -1), scene);
    keyLight.position = new BABYLON.Vector3(20, 40, 20);
    keyLight.intensity = 0.8;

    const fillLight = new BABYLON.DirectionalLight("fillLight", new BABYLON.Vector3(1, -1, 1), scene);
    fillLight.position = new BABYLON.Vector3(-20, 20, -20);
    fillLight.intensity = 0.4;

    const rimLight = new BABYLON.DirectionalLight("rimLight", new BABYLON.Vector3(0, -1, 1), scene);
    rimLight.position = new BABYLON.Vector3(0, 20, -20);
    rimLight.intensity = 0.3;

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
                scene.createDefaultCameraOrLight(true, false, true);
                camera = scene.activeCamera;
                configureCamera(camera);
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
    document.getElementById("dropZone").classList.add("fullscreen");

    try {
        const meshes = await BABYLON.SceneLoader.ImportMeshAsync("", "", url, scene, null, ".glb");
        scene.createDefaultCameraOrLight(true, false, true);
        camera = scene.activeCamera;
        configureCamera(camera);
        camera.attachControl(document.getElementById("renderCanvas"), true);
        
        updateStatus("Model Loaded from URL");
        setupAnimations();
        return meshes;
    } catch (e) {
        updateStatus("Error loading model: " + e.message);
        console.error(e);
    }
}

function configureCamera(cam) {
    cam.wheelPrecision = 50;
    cam.panningMouseButton = 1; // Middle button
    cam.panningSensibility = 1000;
    
    // Fix zoom clipping and texture stability
    cam.minZ = 0.01; // Slightly higher for better depth precision
    cam.maxZ = 10000;
    cam.useLogarithmicDepth = true;
    
    // Prevent camera from getting stuck inside objects
    cam.lowerRadiusLimit = 0.01;
}

function resetCamera() {
    if (!scene || !scene.meshes.length) return;
    scene.createDefaultCameraOrLight(true, false, true);
    camera = scene.activeCamera;
    configureCamera(camera);
    camera.attachControl(document.getElementById("renderCanvas"), true);
}

function randomizeBackground() {
    if (!scene) return;
    const r = Math.random();
    const g = Math.random();
    const b = Math.random();
    const color = new BABYLON.Color4(r, g, b, 1);
    scene.clearColor = color;
    
    // Convert to Hex for Picker
    const hex = "#" + [r,g,b].map(x => Math.round(x*255).toString(16).padStart(2, '0')).join('');
    document.getElementById("bgColorPicker").value = hex;
    
    updateStatus(`Background changed to RGB(${Math.round(r*255)}, ${Math.round(g*255)}, ${Math.round(b*255)})`);
}

function setBackgroundColor(hex) {
    if (!scene) return;
    scene.clearColor = BABYLON.Color4.FromHexString(hex + "FF");
}

function setBrightness(level) {
    if (!scene) return;
    
    const hemi = scene.getLightByName("hemiLight");
    if (hemi) hemi.intensity = level * 0.5;
    
    const key = scene.getLightByName("keyLight");
    if (key) key.intensity = level * 0.8;

    const fill = scene.getLightByName("fillLight");
    if (fill) fill.intensity = level * 0.4;

    const rim = scene.getLightByName("rimLight");
    if (rim) rim.intensity = level * 0.3;

    scene.environmentIntensity = level;
}

// Animation Controls
let activeAnimGroups = [];

function setupAnimations() {
    if (!scene) return;
    
    // Hide fullscreen dropzone when model is loaded
    document.getElementById("dropZone").classList.remove("fullscreen");
    
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
