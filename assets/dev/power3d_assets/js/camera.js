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

function transitionCamera(alpha, beta, radius, target, durationMs = 500) {
    if (window.scene && window.scene.activeCamera) {
        const camera = window.scene.activeCamera;
        
        // Simple Babylon.js Animation
        const animAlpha = new BABYLON.Animation("animAlpha", "alpha", 30, BABYLON.Animation.ANIMATIONTYPE_FLOAT, BABYLON.Animation.ANIMATIONLOOPMODE_CONSTANT);
        const animBeta = new BABYLON.Animation("animBeta", "beta", 30, BABYLON.Animation.ANIMATIONTYPE_FLOAT, BABYLON.Animation.ANIMATIONLOOPMODE_CONSTANT);
        const animRadius = new BABYLON.Animation("animRadius", "radius", 30, BABYLON.Animation.ANIMATIONTYPE_FLOAT, BABYLON.Animation.ANIMATIONLOOPMODE_CONSTANT);
        const animTarget = new BABYLON.Animation("animTarget", "target", 30, BABYLON.Animation.ANIMATIONTYPE_VECTOR3, BABYLON.Animation.ANIMATIONLOOPMODE_CONSTANT);

        animAlpha.setKeys([{ frame: 0, value: camera.alpha }, { frame: 30, value: alpha }]);
        animBeta.setKeys([{ frame: 0, value: camera.beta }, { frame: 30, value: beta }]);
        animRadius.setKeys([{ frame: 0, value: camera.radius }, { frame: 30, value: radius }]);
        animTarget.setKeys([{ frame: 0, value: camera.target }, { frame: 30, value: new BABYLON.Vector3(target.x, target.y, target.z) }]);

        scene.beginDirectAnimation(camera, [animAlpha, animBeta, animRadius, animTarget], 0, 30, false, 1.0, () => {
            reportCameraTelemetry(true);
        });
    }
}

function applyInitialSettings(camera) {
    // Default settings matching Power3DState defaults
    camera.lowerRadiusLimit = 1.0;
    camera.upperRadiusLimit = 20.0;
    camera.panningSensibility = 0; // Locked by default
    // Default zoom sensitivity: higher number = slower zoom
    camera.wheelPrecision = 50;
    camera.pinchPrecision = 200;
}

/// Controls how sensitive the zoom interaction is.
/// [sensitivity]: A value from 0.0 to 1.0. Lower = faster, higher = slower.
/// Internally mapped to wheelPrecision and pinchPrecision (range: 5 to 500).
function updateZoomSensitivity(sensitivity) {
    if (window.scene && window.scene.activeCamera) {
        const camera = window.scene.activeCamera;
        // Map 0.0-1.0 sensitivity to precision range (5 fast -> 500 slow)
        const minPrec = 5;
        const maxPrec = 500;
        const precision = minPrec + (maxPrec - minPrec) * sensitivity;
        camera.wheelPrecision = precision;
        camera.pinchPrecision = precision * 4; // pinch needs a higher value
    }
}
