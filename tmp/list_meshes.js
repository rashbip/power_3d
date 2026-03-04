const BABYLON = require('babylonjs');
require('babylonjs-loaders');
const fs = require('fs');
const path = require('path');

async function listMeshes(modelPath) {
    const data = fs.readFileSync(modelPath);
    const scene = new BABYLON.Scene(new BABYLON.NullEngine());
    
    try {
        const result = await BABYLON.SceneLoader.ImportMeshAsync("", "", "data:" + data.toString('base64'), scene, null, ".glb");
        console.log("Meshes found in " + path.basename(modelPath) + ":");
        result.meshes.forEach(m => {
            console.log("- " + m.name + (m.getTotalVertices() > 0 ? " (Renderable)" : " (Structure)"));
        });
    } catch (e) {
        console.error("Error loading model:", e);
    }
}

const model = process.argv[2] || 'd:\\Plugin\\flutter\\power3d\\example\\assets\\shoulder.glb';
listMeshes(model).then(() => process.exit());
