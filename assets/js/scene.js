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
    const engine = new BABYLON.Engine(canvas, true, { preserveDrawingBuffer: true, stencil: true });
    const scene = createScene(engine, canvas);
    
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
    
    return { engine, scene };
}
