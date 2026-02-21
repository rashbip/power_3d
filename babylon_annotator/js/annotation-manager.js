// ============================================================
// Annotation Manager — hotspot data, 3D sphere markers,
// 2D GUI labels, export (JSON / CSV).
// ============================================================
'use strict';

let annotations = [];
let hotspotMarkers = new Map(); // id → { sphere, label }
let previewMarker = null;       // temporary { sphere, label } for a point not yet added

// ------------------------------------------------------------------
// CRUD
// ------------------------------------------------------------------

function addAnnotation(ann) {
    annotations.push(ann);
    _createHotspotMarker(ann);
    updateAnnotationListUI();
}

function deleteAnnotation(idx) {
    const ann = annotations[idx];
    if (!ann) return;
    _disposeMarker(ann.id);
    annotations.splice(idx, 1);
    updateAnnotationListUI();
}

function clearAllAnnotations() {
    hotspotMarkers.forEach((_, id) => _disposeMarker(id));
    annotations = [];
    clearPreviewPoint();
    updateAnnotationListUI();
}

function _disposeMarker(id) {
    const m = hotspotMarkers.get(id);
    if (!m) return;
    if (m.label) m.label.dispose();
    if (m.sphere) {
        if (m.sphere.material) m.sphere.material.dispose();
        m.sphere.dispose();
    }
    hotspotMarkers.delete(id);
}

// ------------------------------------------------------------------
// PREVIEW MARKER
// ------------------------------------------------------------------

function setPreviewPoint(posArray) {
    if (!guiTexture || !scene) return;
    const pos = new BABYLON.Vector3(posArray[0], posArray[1], posArray[2]);

    if (!previewMarker) {
        // Create new preview marker components
        const sphere = BABYLON.MeshBuilder.CreateSphere('preview_dot', { diameter: 0.045, segments: 8 }, scene);
        sphere.isPickable = false;
        sphere.renderingGroupId = 1;

        const mat = new BABYLON.StandardMaterial('preview_mat', scene);
        mat.emissiveColor = new BABYLON.Color3(1, 1, 1); // white preview
        mat.disableLighting = true;
        sphere.material = mat;

        const label = new BABYLON.GUI.Rectangle('preview_label');
        label.width = '24px';
        label.height = '24px';
        label.cornerRadius = 12;
        label.color = 'white';
        label.thickness = 2;
        label.background = '#94a3b8'; // greyish/slate
        guiTexture.addControl(label);
        label.linkWithMesh(sphere);
        label.linkOffsetYInPixels = -22;

        const text = new BABYLON.GUI.TextBlock('ptext');
        text.text = '?';
        text.color = 'white';
        text.fontSize = 11;
        text.fontWeight = 'bold';
        label.addControl(text);

        previewMarker = { sphere, label };
    }

    // Move to the clicked position
    if (previewMarker.sphere) previewMarker.sphere.position = pos;
}

function clearPreviewPoint() {
    if (previewMarker) {
        if (previewMarker.label) previewMarker.label.dispose();
        if (previewMarker.sphere) {
            if (previewMarker.sphere.material) previewMarker.sphere.material.dispose();
            previewMarker.sphere.dispose();
        }
        previewMarker = null;
    }
}

// ------------------------------------------------------------------
// HOTSPOT VISUALS
// ------------------------------------------------------------------

function _createHotspotMarker(ann) {
    if (!guiTexture || !scene) return;

    const pos = new BABYLON.Vector3(
        ann.internal_worldPosition[0],
        ann.internal_worldPosition[1],
        ann.internal_worldPosition[2]
    );

    // --- 3D sphere (placed exactly at the picked surface point) ---
    const sphere = BABYLON.MeshBuilder.CreateSphere('hotspot_mesh', { diameter: 0.04, segments: 8 }, scene);
    sphere.position = pos;
    sphere.isPickable = false;
    sphere.renderingGroupId = 1; // always on top of model

    const mat = new BABYLON.StandardMaterial('hotspot_mat_' + ann.id, scene);
    mat.emissiveColor = new BABYLON.Color3(0.22, 0.75, 1.0);
    mat.disableLighting = true;
    sphere.material = mat;

    // Gentle pulse animation
    const pulseAnim = new BABYLON.Animation(
        'pulse_' + ann.id, 'scaling', 30,
        BABYLON.Animation.ANIMATIONTYPE_VECTOR3,
        BABYLON.Animation.ANIMATIONLOOPMODE_CYCLE
    );
    pulseAnim.setKeys([
        { frame: 0,  value: new BABYLON.Vector3(1, 1, 1) },
        { frame: 15, value: new BABYLON.Vector3(1.3, 1.3, 1.3) },
        { frame: 30, value: new BABYLON.Vector3(1, 1, 1) }
    ]);
    sphere.animations = [pulseAnim];
    scene.beginAnimation(sphere, 0, 30, true);

    // --- 2D GUI label linked to the sphere ---
    const label = new BABYLON.GUI.Rectangle('label_' + ann.id);
    label.width = '24px';
    label.height = '24px';
    label.cornerRadius = 12;
    label.color = 'white';
    label.thickness = 2;
    label.background = '#0ea5e9';
    label.hoverCursor = 'pointer';
    guiTexture.addControl(label);

    // linkWithMesh positions the label in 3D space at the sphere location
    label.linkWithMesh(sphere);
    label.linkOffsetYInPixels = -22; // float above the sphere

    const text = new BABYLON.GUI.TextBlock('ltext_' + ann.id);
    text.text = String(ann.id);
    text.color = 'white';
    text.fontSize = 11;
    text.fontWeight = 'bold';
    label.addControl(text);

    // ID for reverse-picking
    sphere.metadata = { id: ann.id };

    hotspotMarkers.set(ann.id, { sphere, label });
}

/**
 * Update the visual state (color/scaling) of a 3D marker when selected.
 */
function updateMarkerSelection(id, isSelected) {
    const m = hotspotMarkers.get(id);
    if (!m) return;

    if (isSelected) {
        m.label.background = '#f59e0b'; // orange highlight
        m.label.scaleX = 1.3;
        m.label.scaleY = 1.3;
        m.label.zIndex = 10;
        if (m.sphere.material) {
            m.sphere.material.emissiveColor = new BABYLON.Color3(1.0, 0.6, 0.0);
        }
    } else {
        m.label.background = '#0ea5e9'; // default blue
        m.label.scaleX = 1.0;
        m.label.scaleY = 1.0;
        m.label.zIndex = 0;
        if (m.sphere.material) {
            m.sphere.material.emissiveColor = new BABYLON.Color3(0.22, 0.75, 1.0);
        }
    }
}

// ------------------------------------------------------------------
// EXPORT
// ------------------------------------------------------------------

function _cleanForExport(ann) {
    const { internal_worldPosition, ...rest } = ann;
    return rest;
}

function copyAnnotationsAsJson() {
    if (!annotations.length) return;
    const json = JSON.stringify(annotations.map(_cleanForExport), null, 2);
    navigator.clipboard.writeText(json).then(() => updateStatus('JSON copied!'));
}

function copyAnnotationsAsCsv() {
    if (!annotations.length) return;

    const headers = [
        'id', 'surface_meshName', 'surface_triangleIndex', 'surface_barycentric',
        'placement_normal', 'placement_offset', 'placement_billboard',
        'visibility_minDistance', 'visibility_maxDistance', 'visibility_hideWhenOccluded',
        'ui_title', 'ui_description', 'ui_more',
        'camera_orbit', 'camera_target', 'camera_transitionDuration',
        'meta_version', 'meta_createdAt'
    ];

    const esc = s => '"' + String(s || '').replace(/"/g, '""') + '"';

    const rows = annotations.map(ann => [
        ann.id,
        esc(ann.surface.meshName),
        ann.surface.triangleIndex,
        esc(ann.surface.barycentric.join(',')),
        esc(ann.placement.normal.join(',')),
        ann.placement.offset,
        ann.placement.billboard,
        ann.visibility.minDistance,
        ann.visibility.maxDistance,
        ann.visibility.hideWhenOccluded,
        esc(ann.ui.title),
        esc(ann.ui.description),
        esc(ann.ui.more),
        esc(ann.camera.orbit.join(',')),
        esc(ann.camera.target.join(',')),
        ann.camera.transitionDuration,
        ann.meta.version,
        esc(ann.meta.createdAt)
    ].join(','));

    const csv = [headers.join(','), ...rows].join('\n');
    navigator.clipboard.writeText(csv).then(() => updateStatus('CSV copied!'));
}
