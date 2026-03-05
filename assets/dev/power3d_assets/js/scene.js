// Scene initialization and management
function createScene(engine, canvas) {
    const scene = new BABYLON.Scene(engine);
    scene.clearColor = new BABYLON.Color4(0, 0, 0, 0);

    const camera = new BABYLON.ArcRotateCamera("camera", -Math.PI / 2, Math.PI / 2.5, 3, new BABYLON.Vector3(0, 0, 0), scene);
    camera.attachControl(canvas, true);
    
    // Lights will be managed dynamically via updateLighting
    return scene;
}

function initializeScene(canvas) {
    console.log("Power3D: initializeScene - starting engine...");
    const engine = new BABYLON.Engine(canvas, true, { preserveDrawingBuffer: true, stencil: true });
    console.log("Power3D: initializeScene - engine created. Creating scene...");
    const scene = createScene(engine, canvas);
    console.log("Power3D: initializeScene - scene created.");
    
    // Make globally accessible for other modules
    window.engine = engine;
    window.scene = scene;
    window.canvas = canvas;
    
    // Start render loop
    engine.runRenderLoop(function () {
        if (scene) {
            scene.render();
            reportCameraTelemetry();
        }
    });
    
    // Handle window resize
    window.addEventListener("resize", function () {
        engine.resize();
    });
    
    console.log("Power3D: initializeScene - completed.");
    return { engine, scene };
}

window.resetScene = resetScene;

function resetScene() {
    if (!window.scene) return;

    // 1. Stop all animations if module loaded
    if (typeof stopAllAnimations === 'function') {
        stopAllAnimations();
    }

    // 2. Clear selections and restore original states if module loaded
    if (typeof clearSelection === 'function') {
        clearSelection();
    }

    // 3. Unhide all parts if module loaded
    if (typeof unhideAll === 'function') {
        unhideAll();
    }

    // 4. Reset camera if module loaded
    if (typeof resetView === 'function') {
        resetView();
    }
    
    // 5. Notify Flutter that scene was reset
    sendMessageToFlutter({ type: 'status', message: 'reset' });
}
