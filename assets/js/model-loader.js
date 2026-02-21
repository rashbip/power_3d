// Model loading utilities
async function loadModel(data, fileName, type) {
    try {
        sendMessageToFlutter({ type: 'status', message: 'loading', fileName: fileName });

        if (!window.scene) throw new Error("Viewer not ready");

        window.scene.meshes.slice().forEach(m => m.dispose());

        // Clear annotation markers whenever the scene is reset for a new model
        if (typeof clearAnnotationsFromFlutter === 'function') {
            clearAnnotationsFromFlutter();
        }

        let sceneFilename = data;

        // For Base64 binary data, convert to Blob URL
        if (type === 'base64') {
            const binaryString = atob(data);
            const bytes = new Uint8Array(binaryString.length);
            for (let i = 0; i < binaryString.length; i++) {
                bytes[i] = binaryString.charCodeAt(i);
            }
            const blob = new Blob([bytes], { type: 'application/octet-stream' });
            sceneFilename = URL.createObjectURL(blob);
        }

        const extension = (fileName && fileName.includes('.'))
            ? fileName.substring(fileName.lastIndexOf(".")).toLowerCase()
            : ".glb";

        console.log(`[JS] Loading ${fileName} with extension ${extension}`);

        const result = await BABYLON.SceneLoader.ImportMeshAsync("", "", sceneFilename, window.scene, null, extension);

        // Clean up Blob URL if created
        if (type === 'base64') {
            URL.revokeObjectURL(sceneFilename);
        }
        
        if (result.meshes.length > 0) {
            window.scene.createDefaultCameraOrLight(true, true, true);
            if (window.scene.activeCamera) {
                window.scene.activeCamera.attachControl(window.canvas, true);
                applyInitialSettings(window.scene.activeCamera);
                reportCameraTelemetry(true);
            }
        }

        sendMessageToFlutter({ type: 'status', message: 'loaded', fileName: fileName });
        
        // Initialize selection and send parts list
        initializeSelection();
        sendPartsListToFlutter();
    } catch (e) {
        console.error("Load Error:", e);
        sendMessageToFlutter({ type: 'error', message: e.message || "Failed to load 3D model" });
    }
}

async function takeScreenshot() {
    if (window.engine && window.scene) {
        BABYLON.Tools.CreateScreenshot(window.engine, window.scene.activeCamera, { precision: 1 }, function (data) {
            sendMessageToFlutter({ type: 'screenshot', data: data });
        });
    }
}
