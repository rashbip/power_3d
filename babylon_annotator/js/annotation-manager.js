// Annotation Manager: Handles hotspot data and markers
let annotations = [];
let hotspotMarkers = new Map();

function addAnnotation(ann) {
    annotations.push(ann);
    createHotspotMarker(ann);
    updateAnnotationListUI();
    document.getElementById("downloadBtn").disabled = false;
}

function deleteAnnotation(idx) {
    const id = annotations[idx].id;
    
    // Remove markers
    const markers = hotspotMarkers.get(id);
    if (markers) {
        markers.label.dispose();
        markers.sphere.dispose();
        hotspotMarkers.delete(id);
    }
    
    annotations.splice(idx, 1);
    updateAnnotationListUI();
    if (annotations.length === 0) {
        document.getElementById("downloadBtn").disabled = true;
    }
}

function clearAllAnnotations() {
    annotations = [];
    hotspotMarkers.forEach(m => {
        m.label.dispose();
        m.sphere.dispose();
    });
    hotspotMarkers.clear();
    updateAnnotationListUI();
    document.getElementById("downloadBtn").disabled = true;
}

function createHotspotMarker(ann) {
    if (!guiTexture || !scene) return;

    // 2D Label
    const label = new BABYLON.GUI.Rectangle(ann.id);
    label.width = "20px";
    label.height = "20px";
    label.cornerRadius = 10;
    label.color = "white";
    label.thickness = 2;
    label.background = "#38bdf8";
    guiTexture.addControl(label);

    const pos = new BABYLON.Vector3(ann.worldPosition[0], ann.worldPosition[1], ann.worldPosition[2]);
    label.linkWithMesh(scene.getMeshByName(ann.meshName));

    // 3D Sphere marker
    const sphere = BABYLON.MeshBuilder.CreateSphere("hotspot_mesh", {diameter: 0.05}, scene);
    sphere.position = pos;
    const mat = new BABYLON.StandardMaterial("hotspot_mat", scene);
    mat.emissiveColor = new BABYLON.Color3(0.2, 0.7, 1);
    sphere.material = mat;

    hotspotMarkers.set(ann.id, { label, sphere });
}

function exportAnnotations() {
    if (annotations.length === 0) return;
    const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(annotations, null, 2));
    const downloadAnchorNode = document.createElement('a');
    downloadAnchorNode.setAttribute("href",     dataStr);
    downloadAnchorNode.setAttribute("download", "annotations.json");
    document.body.appendChild(downloadAnchorNode);
    downloadAnchorNode.click();
    downloadAnchorNode.remove();
}
