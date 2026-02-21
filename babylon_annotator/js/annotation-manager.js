// ============================================================
// Annotation Manager — hotspot data, 3D sphere markers,
// 2D GUI labels, export (JSON / CSV).
// ============================================================
'use strict';

let annotations = [];
let hotspotMarkers = new Map(); // id → { sphere, label }
let previewMarker = null;       // temporary { sphere, label } for a point not yet added
let _currentMarkerSize = 0.02;  // global diameter control

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
        const sphere = BABYLON.MeshBuilder.CreateSphere('preview_dot', { diameter: 1, segments: 8 }, scene);
        sphere.scaling.setAll(_currentMarkerSize);
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
        label.linkOffsetYInPixels = -(_currentMarkerSize * 500) - 10;

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
    const sphere = BABYLON.MeshBuilder.CreateSphere('hotspot_mesh', { diameter: 1, segments: 8 }, scene);
    sphere.scaling.setAll(_currentMarkerSize);
    sphere.position = pos;
    sphere.isPickable = false;
    sphere.renderingGroupId = 1; // always on top of model

    const mat = new BABYLON.StandardMaterial('hotspot_mat_' + ann.id, scene);
    mat.emissiveColor = new BABYLON.Color3(0.22, 0.75, 1.0);
    mat.disableLighting = true;
    sphere.material = mat;

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
    label.linkOffsetYInPixels = -(_currentMarkerSize * 500) - 10;

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

/**
 * Update the size of all existing markers and the preview marker.
 */
function setMarkerSize(size) {
    _currentMarkerSize = size;
    const offset = -(size * 500) - 10;
    
    // Update existing markers
    hotspotMarkers.forEach(m => {
        if (m.sphere) m.sphere.scaling.setAll(size);
        if (m.label) m.label.linkOffsetYInPixels = offset;
    });

    // Update preview if active
    if (previewMarker) {
        if (previewMarker.sphere) previewMarker.sphere.scaling.setAll(size);
        if (previewMarker.label) previewMarker.label.linkOffsetYInPixels = offset;
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
// ------------------------------------------------------------------
// IMPORT
// ------------------------------------------------------------------

async function importAnnotationsFromFile(file) {
    const text = await file.text();
    let imported = [];

    try {
        if (file.name.toLowerCase().endsWith('.json')) {
            imported = JSON.parse(text);
        } else if (file.name.toLowerCase().endsWith('.csv')) {
            imported = _parseCsv(text);
        }

        if (!Array.isArray(imported)) {
            imported = [imported]; // handle single object JSON
        }

        clearAllAnnotations();

        imported.forEach(ann => {
            // Reconstruct the internal world position from surface data
            ann.internal_worldPosition = _reconstructWorldPosition(ann);
            addAnnotation(ann);
        });

        updateStatus(`Imported ${imported.length} annotations`);
    } catch (e) {
        console.error('Import error:', e);
        updateStatus('Error importing file: ' + e.message);
    }
}

/** Simple CSV parser for our specific format */
function _parseCsv(text) {
    const lines = text.split(/\r?\n/).filter(l => l.trim());
    if (lines.length < 2) return [];
    
    // Skip header
    const dataRows = lines.slice(1);
    
    return dataRows.map(row => {
        // Very basic CSV splitting (doesn't handle commas inside quotes perfectly, 
        // but enough for our known safe format)
        const parts = [];
        let current = '';
        let inQuotes = false;
        for (let char of row) {
            if (char === '"') inQuotes = !inQuotes;
            else if (char === ',' && !inQuotes) {
                parts.push(current.trim());
                current = '';
            } else {
                current += char;
            }
        }
        parts.push(current.trim());

        const parseVec = s => s.split(',').map(Number);

        return {
            id: parseInt(parts[0]) || Date.now(),
            surface: {
                meshName: parts[1],
                triangleIndex: parseInt(parts[2]),
                barycentric: parseVec(parts[3])
            },
            placement: {
                normal: parseVec(parts[4]),
                offset: parseFloat(parts[5]),
                billboard: parts[6] === 'true'
            },
            visibility: {
                minDistance: parseFloat(parts[7]),
                maxDistance: parseFloat(parts[8]),
                hideWhenOccluded: parts[9] === 'true'
            },
            ui: {
                title: parts[10],
                description: parts[11],
                more: parts[12]
            },
            camera: {
                orbit: parseVec(parts[13]),
                target: parseVec(parts[14]),
                transitionDuration: parseFloat(parts[15])
            },
            meta: {
                version: parseInt(parts[16]),
                createdAt: parts[17] || new Date().toISOString()
            }
        };
    });
}

/** 
 * Find the world position of an annotation by mesh name, face index, and barycentric coords.
 */
function _reconstructWorldPosition(ann) {
    if (!scene) return [0,0,0];
    const mesh = scene.getMeshByName(ann.surface.meshName);
    if (!mesh) return [0,0,0];

    const indices = mesh.getIndices();
    const positions = mesh.getVerticesData(BABYLON.VertexBuffer.PositionKind);
    if (!indices || !positions) return [0,0,0];

    const fid = ann.surface.triangleIndex;
    const b = ann.surface.barycentric;

    const i1 = indices[fid * 3];
    const i2 = indices[fid * 3 + 1];
    const i3 = indices[fid * 3 + 2];

    const v1 = BABYLON.Vector3.FromArray(positions, i1 * 3);
    const v2 = BABYLON.Vector3.FromArray(positions, i2 * 3);
    const v3 = BABYLON.Vector3.FromArray(positions, i3 * 3);

    const wm = mesh.getWorldMatrix();
    const p1 = BABYLON.Vector3.TransformCoordinates(v1, wm);
    const p2 = BABYLON.Vector3.TransformCoordinates(v2, wm);
    const p3 = BABYLON.Vector3.TransformCoordinates(v3, wm);

    // P = w1*P1 + w2*P2 + w3*P3
    const worldP = p1.scale(b[0]).add(p2.scale(b[1])).add(p3.scale(b[2]));
    return [worldP.x, worldP.y, worldP.z];
}
