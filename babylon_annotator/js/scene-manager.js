// ============================================================
// Scene Manager — Babylon.js initialization, model loading,
// camera framing, lighting, transforms, animations.
// ============================================================
'use strict';

let engine, scene, camera, guiTexture;
let activeAnimGroups = [];
let _modelPivot = null;    // single TransformNode that wraps the whole loaded model
let _lastModelSize = 1.0;  // bounding-sphere diameter of loaded model, used to range sliders

// ------------------------------------------------------------------
// INIT
// ------------------------------------------------------------------
function initScene() {
    const canvas = document.getElementById('renderCanvas');

    engine = new BABYLON.Engine(canvas, true, {
        antialias: true,
        preserveDrawingBuffer: true,
        stencil: true,
        adaptToDeviceRatio: true
    });

    scene = new BABYLON.Scene(engine);
    scene.clearColor = new BABYLON.Color4(0.05, 0.08, 0.16, 1);

    // ONE ArcRotateCamera — we NEVER replace it after model load.
    camera = new BABYLON.ArcRotateCamera('camera', -Math.PI / 2, Math.PI / 3, 5, BABYLON.Vector3.Zero(), scene);
    configureCamera(camera);
    camera.attachControl(canvas, true);

    // Three-point lighting rig (named so setBrightness can find them)
    const hemi = new BABYLON.HemisphericLight('hemiLight', new BABYLON.Vector3(0, 1, 0), scene);
    hemi.intensity = 0.6;

    const key = new BABYLON.DirectionalLight('keyLight', new BABYLON.Vector3(-1, -2, -1), scene);
    key.position = new BABYLON.Vector3(20, 40, 20);
    key.intensity = 0.8;

    const fill = new BABYLON.DirectionalLight('fillLight', new BABYLON.Vector3(1, -1, 1), scene);
    fill.position = new BABYLON.Vector3(-20, 20, -20);
    fill.intensity = 0.4;

    const rim = new BABYLON.DirectionalLight('rimLight', new BABYLON.Vector3(0, -1, 1), scene);
    rim.position = new BABYLON.Vector3(0, 20, -20);
    rim.intensity = 0.3;

    // Fullscreen GUI layer (persists across model loads)
    guiTexture = BABYLON.GUI.AdvancedDynamicTexture.CreateFullscreenUI('UI', true, scene);

    // Keep animation slider in sync with playback position
    engine.onEndFrameObservable.add(() => {
        if (!activeAnimGroups.length) return;
        const select = document.getElementById('animationSelect');
        const idx = parseInt(select.value) || 0;
        const group = activeAnimGroups[idx];
        if (group && group.isPlaying && group.animatables && group.animatables.length > 0) {
            const slider = document.getElementById('animSlider');
            const frame = group.animatables[0].masterFrame;
            if (!isNaN(frame)) slider.value = frame;
        }
    });

    engine.runRenderLoop(() => scene.render());
    window.addEventListener('resize', () => engine.resize());
}

// ------------------------------------------------------------------
// MODEL LOADING
// ------------------------------------------------------------------

/**
 * Load a local File object (.glb / .gltf).
 * Uses the Babylon `file:` protocol which accepts File objects directly —
 * no FileReader, no base64, no blob URL needed.
 */
async function loadModelFromFile(file) {
    if (!scene) return;
    updateStatus('Loading ' + file.name + '…');
    document.getElementById('dropZone').classList.add('fullscreen');
    _clearModel();

    const ext = '.' + file.name.split('.').pop().toLowerCase();
    try {
        // Babylon SceneLoader: rootUrl="file:", sceneFilename=File object
        const result = await BABYLON.SceneLoader.ImportMeshAsync('', 'file:', file, scene, null, ext);
        _onModelLoaded(result.meshes, file.name);
    } catch (e) {
        console.error('Load error:', e);
        updateStatus('Error loading file: ' + (e.message || e));
        document.getElementById('dropZone').classList.remove('fullscreen');
    }
}

/**
 * Load a model from a remote URL.
 * Splits the URL into rootUrl + filename so Babylon can resolve relative textures.
 */
async function loadModelByUrl(url) {
    if (!scene || !url) return;
    updateStatus('Loading from URL…');
    document.getElementById('dropZone').classList.add('fullscreen');
    _clearModel();

    // Split into rootUrl (directory) + filename
    const lastSlash = url.lastIndexOf('/');
    const rootUrl = url.substring(0, lastSlash + 1);
    const filename = url.substring(lastSlash + 1);
    const ext = '.' + (filename.split('.').pop().toLowerCase() || 'glb');

    try {
        const result = await BABYLON.SceneLoader.ImportMeshAsync('', rootUrl, filename, scene, null, ext);
        _onModelLoaded(result.meshes, filename);
    } catch (e) {
        console.error('URL load error:', e);
        updateStatus('Error: ' + (e.message || e));
        document.getElementById('dropZone').classList.remove('fullscreen');
    }
}

// ------------------------------------------------------------------
// INTERNAL HELPERS
// ------------------------------------------------------------------

function _clearModel() {
    // Dispose the pivot (which removes all parented model meshes) then clean remaining
    if (_modelPivot) {
        _modelPivot.dispose(true, false); // disposeChildren=true, doNotRecurse=false
        _modelPivot = null;
    }
    // Safety pass: any stray non-hotspot meshes
    scene.meshes.slice().forEach(m => {
        if (m.name !== 'hotspot_mesh') m.dispose();
    });
    // Also dispose stray TransformNodes from the GLB node hierarchy
    // (GLB __root__ nodes, named nodes, etc.) — but NOT system nodes like camera parents
    scene.transformNodes.slice().forEach(n => {
        if (!n.name.startsWith('GUITexture') && !n.name.startsWith('BackgroundHelper')) {
            n.dispose();
        }
    });
    clearAllAnnotations();
}

function _onModelLoaded(meshes, name) {
    // Create a single pivot TransformNode so scala/position is one operation
    _modelPivot = new BABYLON.TransformNode('__modelPivot__', scene);
    _modelPivot.position = BABYLON.Vector3.Zero();

    // Re-parent every root-level node (mesh or transformNode) to the pivot
    // so we have a single handle for the whole model.
    const allSceneNodes = [...scene.meshes, ...scene.transformNodes].filter(
        n => n !== _modelPivot && !n.parent && n.name !== 'hotspot_mesh'
    );
    allSceneNodes.forEach(n => (n.parent = _modelPivot));

    _frameCameraOnMeshes(meshes);
    _updateTransformSliders();
    setupAnimations();
    document.getElementById('dropZone').classList.remove('fullscreen');
    updateStatus('Loaded: ' + name);
}

/**
 * Compute the world bounding box of all renderable meshes and
 * adjust our persistent ArcRotateCamera to frame them nicely.
 * We NEVER create a new camera here.
 */
function _frameCameraOnMeshes(meshes) {
    const renderable = meshes.filter(m => m.getTotalVertices && m.getTotalVertices() > 0);
    if (!renderable.length) return;

    renderable.forEach(m => m.refreshBoundingInfo());

    let min = new BABYLON.Vector3(Infinity, Infinity, Infinity);
    let max = new BABYLON.Vector3(-Infinity, -Infinity, -Infinity);

    renderable.forEach(m => {
        const bd = m.getBoundingInfo();
        min = BABYLON.Vector3.Minimize(min, bd.boundingBox.minimumWorld);
        max = BABYLON.Vector3.Maximize(max, bd.boundingBox.maximumWorld);
    });

    const center   = BABYLON.Vector3.Center(min, max);
    const diagonal = BABYLON.Vector3.Distance(min, max);
    const radius   = Math.max(diagonal * 0.75, 0.1);

    _lastModelSize = diagonal || 1.0;

    camera.target = center;
    camera.radius = radius;
    camera.alpha  = -Math.PI / 2;
    camera.beta   = Math.PI / 3;

    camera.minZ           = radius * 0.001;
    camera.maxZ           = radius * 100;
    camera.lowerRadiusLimit = radius * 0.01;
}

function configureCamera(cam) {
    cam.wheelPrecision          = 50;
    cam.angularSensibilityX     = 1000;
    cam.angularSensibilityY     = 1000;
    cam.panningSensibility      = 1000;
    cam.panningMouseButton      = 1;
    cam.minZ                    = 0.001;
    cam.maxZ                    = 100000;
    cam.lowerRadiusLimit        = 0.001;
    cam.useLogarithmicDepth     = true;
}

/**
 * Adjust camera speeds (zoom, rotate, pan).
 * value: 0.1 (slow) to 2.0 (fast).
 */
function setCameraSensitivity(value) {
    if (!camera) return;
    camera.wheelPrecision      = 50 / value;
    camera.angularSensibilityX = 1000 / value;
    camera.angularSensibilityY = 1000 / value;
    camera.panningSensibility  = 1000 / value;
}

// ------------------------------------------------------------------
// CAMERA
// ------------------------------------------------------------------

function resetCamera() {
    const renderable = scene.meshes.filter(
        m => m.name !== 'hotspot_mesh' && m.getTotalVertices && m.getTotalVertices() > 0
    );
    if (renderable.length) {
        _frameCameraOnMeshes(renderable);
    } else {
        camera.target = BABYLON.Vector3.Zero();
        camera.radius = 5;
        camera.alpha = -Math.PI / 2;
        camera.beta = Math.PI / 3;
    }
}

// ------------------------------------------------------------------
// BACKGROUND & LIGHTING
// ------------------------------------------------------------------

function randomizeBackground() {
    if (!scene) return;
    const r = Math.random(), g = Math.random(), b = Math.random();
    scene.clearColor = new BABYLON.Color4(r, g, b, 1);
    const hex = '#' + [r, g, b].map(x => Math.round(x * 255).toString(16).padStart(2, '0')).join('');
    document.getElementById('bgColorPicker').value = hex;
    updateStatus(`Background: RGB(${Math.round(r*255)}, ${Math.round(g*255)}, ${Math.round(b*255)})`);
}

function setBackgroundColor(hex) {
    if (!scene) return;
    if (hex.length === 7) {
        scene.clearColor = BABYLON.Color4.FromHexString(hex + 'ff');
    }
}

function setBrightness(level) {
    if (!scene) return;
    const lights = { hemiLight: 0.6, keyLight: 0.8, fillLight: 0.4, rimLight: 0.3 };
    Object.entries(lights).forEach(([name, base]) => {
        const l = scene.getLightByName(name);
        if (l) l.intensity = base * level;
    });
}

// ------------------------------------------------------------------
// MODEL TRANSFORMS
// ------------------------------------------------------------------

function setModelScale(scale) {
    if (_modelPivot) {
        _modelPivot.scaling.setAll(scale);
    }
}

function setModelPosition(x, y, z) {
    if (_modelPivot) {
        _modelPivot.position.set(x, y, z);
    }
}

function resetModelTransform() {
    if (_modelPivot) {
        _modelPivot.scaling.setAll(1.0);
        _modelPivot.position.setAll(0);
    }
    document.getElementById('modelScaleSlider').value = 1.0;
    document.getElementById('modelPosX').value = 0;
    document.getElementById('modelPosY').value = 0;
    document.getElementById('modelPosZ').value = 0;
}

/**
 * Update the HTML slider ranges to match the real model dimensions.
 * Called automatically after every model load.
 * Also callable from UI layer if needed.
 */
function _updateTransformSliders() {
    const size = _lastModelSize;
    const posRange = Math.max(size * 1.5, 0.5);
    const posStep  = parseFloat((posRange / 100).toPrecision(2));

    ['modelPosX', 'modelPosY', 'modelPosZ'].forEach(id => {
        const el = document.getElementById(id);
        el.min   = -posRange;
        el.max   =  posRange;
        el.step  = posStep;
        el.value = 0;
    });

    // Scale: allow shrinking down to 1% and growing to 10x
    const scaleEl = document.getElementById('modelScaleSlider');
    scaleEl.min   = 0.01;
    scaleEl.max   = 10;
    scaleEl.step  = 0.01;
    scaleEl.value = 1.0;
}

// ------------------------------------------------------------------
// ANIMATIONS
// ------------------------------------------------------------------

function setupAnimations() {
    activeAnimGroups = scene.animationGroups || [];
    const panel = document.getElementById('animationPanel');
    const select = document.getElementById('animationSelect');

    if (activeAnimGroups.length > 0) {
        panel.classList.remove('hidden');
        select.innerHTML = '';
        activeAnimGroups.forEach((group, index) => {
            const opt = document.createElement('option');
            opt.value = index;
            opt.text = group.name || ('Animation ' + (index + 1));
            select.add(opt);
        });
        // Stop all on load (let user press Play)
        activeAnimGroups.forEach(g => g.stop());
        updateSliderRange(0);
    } else {
        panel.classList.add('hidden');
    }
}

function updateSliderRange(index) {
    const group = activeAnimGroups[index];
    if (!group) return;
    const slider = document.getElementById('animSlider');
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
        const slider = document.getElementById('animSlider');
        slider.value = group.from;
    }
}

function scrubAnimation(index, frame) {
    const group = activeAnimGroups[index];
    if (group) {
        group.pause();
        group.goToFrame(parseFloat(frame));
    }
}

function setAnimationSpeed(index, speed) {
    const group = activeAnimGroups[index];
    if (group) group.speedRatio = speed;
}
