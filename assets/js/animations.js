// Animations management for Babylon.js
let animationConfigs = new Map();

function initAnimations() {
    if (!window.scene) return;
    getAnimationsList();
}

function getAnimationsList() {
    if (!window.scene) return;

    const animations = window.scene.animationGroups.map(ag => {
        return {
            name: ag.name,
            isPlaying: ag.isPlaying,
            speed: ag.speedRatio,
            loop: ag.loopAnimation
        };
    });

    sendMessageToFlutter({
        type: 'animationsList',
        animations: animations
    });
}

function playAnimation(name, loop = true, speed = 1.0) {
    if (!window.scene) return;

    const ag = window.scene.getAnimationGroupByName(name);
    if (ag) {
        // If playMultiple is false, stop others
        if (!window.playMultiple) {
            stopAllAnimations();
        }

        ag.reset();
        ag.play(loop);
        ag.speedRatio = speed;
        
        // Report change
        sendAnimationStatus(ag);
    }
}

function pauseAnimation(name) {
    if (!window.scene) return;
    const ag = window.scene.getAnimationGroupByName(name);
    if (ag) {
        ag.pause();
        sendAnimationStatus(ag);
    }
}

function stopAnimation(name) {
    if (!window.scene) return;
    const ag = window.scene.getAnimationGroupByName(name);
    if (ag) {
        ag.stop();
        sendAnimationStatus(ag);
    }
}

function setAnimationSpeed(name, speed) {
    if (!window.scene) return;
    const ag = window.scene.getAnimationGroupByName(name);
    if (ag) {
        ag.speedRatio = speed;
        sendAnimationStatus(ag);
    }
}

function stopAllAnimations() {
    if (!window.scene) return;
    window.scene.animationGroups.forEach(ag => {
        ag.stop();
        sendAnimationStatus(ag);
    });
}

function startAllAnimations() {
    if (!window.scene) return;
    window.scene.animationGroups.forEach(ag => {
        ag.play(true);
        sendAnimationStatus(ag);
    });
}

function sendAnimationStatus(ag) {
    sendMessageToFlutter({
        type: 'animationStatus',
        animation: {
            name: ag.name,
            isPlaying: ag.isPlaying,
            speed: ag.speedRatio,
            loop: ag.loopAnimation
        }
    });
}

// Add event listeners to animation groups if needed for playback finished events
function setupAnimationListeners() {
    if (!window.scene) return;
    window.scene.animationGroups.forEach(ag => {
        ag.onAnimationGroupEndObservable.add(() => {
            sendAnimationStatus(ag);
        });
        ag.onAnimationGroupPauseObservable.add(() => {
             sendAnimationStatus(ag);
        });
        ag.onAnimationGroupPlayObservable.add(() => {
             sendAnimationStatus(ag);
        });
    });
}
