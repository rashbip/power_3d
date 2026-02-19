// Annotation Manager: Handles hotspot data and markers
let annotations = [];
let hotspotMarkers = new Map();

function addAnnotation(ann) {
    annotations.push(ann);
    createHotspotMarker(ann);
    updateAnnotationListUI();
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
}

function clearAllAnnotations() {
    annotations = [];
    hotspotMarkers.forEach(m => {
        m.label.dispose();
        m.sphere.dispose();
    });
    hotspotMarkers.clear();
    updateAnnotationListUI();
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

    const pos = new BABYLON.Vector3(ann.internal_worldPosition[0], ann.internal_worldPosition[1], ann.internal_worldPosition[2]);
    label.linkWithMesh(scene.getMeshByName(ann.surface.meshName));

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
    
    // Clean up for export: remove internal helper fields
    const exportData = annotations.map(ann => {
        const { internal_worldPosition, ...rest } = ann;
        return rest;
    });

    const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(exportData, null, 2));
    const downloadAnchorNode = document.createElement('a');
    downloadAnchorNode.setAttribute("href",     dataStr);
    downloadAnchorNode.setAttribute("download", "annotations.json");
    document.body.appendChild(downloadAnchorNode);
    downloadAnchorNode.click();
    downloadAnchorNode.remove();
}

function copyAnnotationsAsJson() {
    if (annotations.length === 0) return;
    const exportData = annotations.map(ann => {
        const { internal_worldPosition, ...rest } = ann;
        return rest;
    });
    const json = JSON.stringify(exportData, null, 2);
    navigator.clipboard.writeText(json).then(() => {
        if (typeof updateStatus === "function") updateStatus("JSON copied to clipboard!");
    });
}

function copyAnnotationsAsCsv() {
    if (annotations.length === 0) return;
    
    // Flattened headers for CSV
    const headers = [
        "id", "surface_meshName", "surface_triangleIndex", "surface_barycentric",
        "placement_normal", "placement_offset", "placement_billboard",
        "visibility_minDistance", "visibility_maxDistance", "visibility_hideWhenOccluded",
        "ui_title", "ui_description", "ui_more",
        "camera_orbit", "camera_target", "camera_transitionDuration",
        "meta_version", "meta_createdAt"
    ];

    const rows = annotations.map(ann => {
        return [
            ann.id,
            ann.surface.meshName,
            ann.surface.triangleIndex,
            `"${ann.surface.barycentric.join(',')}"`,
            `"${ann.placement.normal.join(',')}"`,
            ann.placement.offset,
            ann.placement.billboard,
            ann.visibility.minDistance,
            ann.visibility.maxDistance,
            ann.visibility.hideWhenOccluded,
            `"${(ann.ui.title || "").replace(/"/g, '""')}"`,
            `"${(ann.ui.description || "").replace(/"/g, '""')}"`,
            `"${(ann.ui.more || "").replace(/"/g, '""')}"`,
            `"${ann.camera.orbit.join(',')}"`,
            `"${ann.camera.target.join(',')}"`,
            ann.camera.transitionDuration,
            ann.meta.version,
            ann.meta.createdAt
        ].join(",");
    });

    const csvContent = [headers.join(","), ...rows].join("\n");
    navigator.clipboard.writeText(csvContent).then(() => {
        if (typeof updateStatus === "function") updateStatus("CSV copied to clipboard!");
    });
}
