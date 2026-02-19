// Camera controls and telemetry reporting
let lastCameraState = { alpha: 0, beta: 0, radius: 0 };

function reportCameraTelemetry(force = false) {
    if (window.scene && window.scene.activeCamera) {
        const cam = window.scene.activeCamera;
        // Only send if changed significantly to avoid spam, unless forced
        if (force ||
            Math.abs(cam.alpha - lastCameraState.alpha) > 0.001 ||
            Math.abs(cam.beta - lastCameraState.beta) > 0.001 ||
            Math.abs(cam.radius - lastCameraState.radius) > 0.01) {

            lastCameraState = { alpha: cam.alpha, beta: cam.beta, radius: cam.radius };
            sendMessageToFlutter({
                type: 'camera',
                alpha: cam.alpha,
                beta: cam.beta,
                radius: cam.radius
            });
        }
    }
}

function resetView() {
    if (window.scene && window.scene.activeCamera) {
        window.scene.activeCamera.restoreState();
        // If no state saved, just re-create default
        if (window.scene.meshes.length > 0) {
            window.scene.createDefaultCameraOrLight(true, true, true);
            if (window.scene.activeCamera) {
                window.scene.activeCamera.attachControl(window.canvas, true);
                applyInitialSettings(window.scene.activeCamera);
                reportCameraTelemetry(true);
            }
        }
    }
}

let rotationTimeout = null;

function toggleAutoRotate(enabled, speed = 1.0, direction = 'clockwise', stopAfterMs = null) {
    if (window.scene && window.scene.activeCamera) {
        const camera = window.scene.activeCamera;
        camera.useAutoRotationBehavior = enabled;

        if (enabled && camera.autoRotationBehavior) {
            camera.autoRotationBehavior.idleRotationSpeed = (direction === 'clockwise' ? 1 : -1) * (speed * 0.1);

            if (rotationTimeout) clearTimeout(rotationTimeout);
            if (stopAfterMs) {
                rotationTimeout = setTimeout(() => {
                    camera.useAutoRotationBehavior = false;
                    sendMessageToFlutter({ type: 'statusChange', key: 'autoRotate', value: false });
                }, stopAfterMs);
            }
        }
    }
}

function setLockPosition(locked) {
    if (window.scene && window.scene.activeCamera) {
        const camera = window.scene.activeCamera;
        camera.panningSensibility = locked ? 0 : 1000;
    }
}

function updateZoom(enabled, min = 1.0, max = 20.0) {
    if (window.scene && window.scene.activeCamera) {
        const camera = window.scene.activeCamera;
        if (!enabled) {
            camera.lowerRadiusLimit = camera.radius;
            camera.upperRadiusLimit = camera.radius;
        } else {
            camera.lowerRadiusLimit = min;
            camera.upperRadiusLimit = max;
        }
    }
}

function setCameraPosition(alpha, beta, radius) {
    if (window.scene && window.scene.activeCamera) {
        const camera = window.scene.activeCamera;
        if (alpha !== null && alpha !== undefined) camera.alpha = alpha;
        if (beta !== null && beta !== undefined) camera.beta = beta;
        if (radius !== null && radius !== undefined) camera.radius = radius;
        reportCameraTelemetry(true);
    }
}

function applyInitialSettings(camera) {
    // Default settings matching Power3DState defaults
    camera.lowerRadiusLimit = 1.0;
    camera.upperRadiusLimit = 20.0;
    camera.panningSensibility = 0; // Locked by default
}
