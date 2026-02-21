// ============================================================
// UI Manager — DOM event wiring, pick handling, form logic,
// annotation list rendering.
// ============================================================
'use strict';

let isAnnotating = false;
let currentPick = null;
let _editingIndex = -1; // index of the annotation being edited, -1 if none

function initUI() {
    // ---------- File / URL loading ----------
    const dropZone  = document.getElementById('dropZone');
    const fileInput = document.getElementById('fileInput');
    const urlInput  = document.getElementById('urlInput');

    dropZone.addEventListener('click', () => fileInput.click());
    dropZone.addEventListener('dragover',  e => { e.preventDefault(); dropZone.classList.add('dragover'); });
    dropZone.addEventListener('dragleave', () => dropZone.classList.remove('dragover'));
    dropZone.addEventListener('drop', e => {
        e.preventDefault();
        dropZone.classList.remove('dragover');
        const file = e.dataTransfer.files[0];
        if (file) loadModelFromFile(file);
    });
    fileInput.addEventListener('change', e => {
        const file = e.target.files[0];
        if (file) loadModelFromFile(file);
        fileInput.value = ''; // allow re-selecting the same file
    });

    document.getElementById('urlLoadBtn').addEventListener('click', () => {
        const url = urlInput.value.trim();
        if (url) loadModelByUrl(url);
    });
    urlInput.addEventListener('keydown', e => {
        if (e.key === 'Enter') {
            const url = urlInput.value.trim();
            if (url) loadModelByUrl(url);
        }
    });

    // ---------- Background / Lighting ----------
    const bgColorPicker = document.getElementById('bgColorPicker');
    bgColorPicker.addEventListener('input', () => setBackgroundColor(bgColorPicker.value));

    document.getElementById('randomBgBtn').addEventListener('click', randomizeBackground);

    const brightnessSlider = document.getElementById('brightnessSlider');
    brightnessSlider.addEventListener('input', () => setBrightness(parseFloat(brightnessSlider.value)));

    const mouseSensSlider = document.getElementById('mouseSensitivitySlider');
    mouseSensSlider.addEventListener('input', () => setCameraSensitivity(parseFloat(mouseSensSlider.value)));
    // Initial sync
    setCameraSensitivity(parseFloat(mouseSensSlider.value));

    // ---------- Annotation & Model Transform ----------
    const markerSizeSlider = document.getElementById('markerSizeSlider');
    const scaleSlider      = document.getElementById('modelScaleSlider');
    const posX             = document.getElementById('modelPosX');
    const posY             = document.getElementById('modelPosY');
    const posZ             = document.getElementById('modelPosZ');

    markerSizeSlider.addEventListener('input', () => setMarkerSize(parseFloat(markerSizeSlider.value)));
    // Initial sync
    setMarkerSize(parseFloat(markerSizeSlider.value));

    scaleSlider.addEventListener('input', () => setModelScale(parseFloat(scaleSlider.value)));

    const syncPos = () => setModelPosition(
        parseFloat(posX.value), parseFloat(posY.value), parseFloat(posZ.value)
    );
    posX.addEventListener('input', syncPos);
    posY.addEventListener('input', syncPos);
    posZ.addEventListener('input', syncPos);

    document.getElementById('resetTransformBtn').addEventListener('click', resetModelTransform);

    // ---------- Camera / Utility ----------
    document.getElementById('resetCamBtn').addEventListener('click', resetCamera);
    document.getElementById('clearAllBtn').addEventListener('click', () => {
        if (confirm('Delete ALL annotations?')) clearAllAnnotations();
    });

    const importBtn = document.getElementById('importAnnBtn');
    const annInput  = document.getElementById('annFileInput');
    if (importBtn && annInput) {
        importBtn.addEventListener('click', () => annInput.click());
        annInput.addEventListener('change', e => {
            const file = e.target.files[0];
            if (file) importAnnotationsFromFile(file);
            annInput.value = ''; // allow re-importing the same file
        });
    }

    // ---------- Animation Controls ----------
    const animSelect     = document.getElementById('animationSelect');
    const animSlider     = document.getElementById('animSlider');
    const animSpeedSel   = document.getElementById('animSpeedSelect');

    document.getElementById('animPlayBtn').addEventListener('click',  () => playAnimation(parseInt(animSelect.value)));
    document.getElementById('animPauseBtn').addEventListener('click', () => pauseAnimation(parseInt(animSelect.value)));
    document.getElementById('animStopBtn').addEventListener('click',  () => stopAnimation(parseInt(animSelect.value)));
    animSelect.addEventListener('change', () => updateSliderRange(parseInt(animSelect.value)));
    animSlider.addEventListener('input',  () => scrubAnimation(parseInt(animSelect.value), parseFloat(animSlider.value)));
    animSpeedSel.addEventListener('change', () => setAnimationSpeed(parseInt(animSelect.value), parseFloat(animSpeedSel.value)));

    // ---------- Annotation Mode Toggle ----------
    document.getElementById('newAnnotBtn').addEventListener('click', () => {
        isAnnotating = true;
        document.getElementById('annotationForm').classList.remove('hidden');
        document.getElementById('mainActions').classList.add('hidden');
        updateStatus('Annotation mode — click any surface on the model');
        _resetForm();
    });

    document.getElementById('cancelBtn').addEventListener('click', _exitAnnotationMode);

    // ---------- Add/Update Button ----------
    const addBtn = document.getElementById('addBtn');
    addBtn.addEventListener('click', () => {
        if (_editingIndex === -1 && !currentPick) return;

        const annData = {
            surface: _editingIndex !== -1 ? annotations[_editingIndex].surface : {
                meshName: currentPick.meshName,
                triangleIndex: currentPick.triangleIndex,
                barycentric: currentPick.barycentric
            },
            placement: {
                normal: _editingIndex !== -1 ? annotations[_editingIndex].placement.normal : currentPick.normal,
                offset: parseFloat(document.getElementById('nodeOffset').value),
                billboard: document.getElementById('nodeBillboard').checked
            },
            visibility: {
                minDistance: parseFloat(document.getElementById('nodeMinDist').value),
                maxDistance: parseFloat(document.getElementById('nodeMaxDist').value),
                hideWhenOccluded: document.getElementById('nodeHideOccluded').checked
            },
            ui: {
                title: document.getElementById('nodeTitle').value.trim() || 'Untitled',
                description: document.getElementById('nodeDesc').value.trim(),
                more: document.getElementById('nodeMore').value.trim()
            },
            camera: {
                orbit: _editingIndex !== -1 ? annotations[_editingIndex].camera.orbit : currentPick.cameraOrbit,
                target: _editingIndex !== -1 ? annotations[_editingIndex].camera.target : currentPick.cameraTarget,
                transitionDuration: parseFloat(document.getElementById('nodeTransition').value)
            },
            meta: {
                version: 1,
                createdAt: _editingIndex !== -1 ? annotations[_editingIndex].meta.createdAt : new Date().toISOString(),
                updatedAt: new Date().toISOString()
            },
            internal_worldPosition: _editingIndex !== -1 ? annotations[_editingIndex].internal_worldPosition : currentPick.worldPosition
        };

        if (_editingIndex !== -1) {
            // Update existing
            const oldId = annotations[_editingIndex].id;
            annotations[_editingIndex] = { ...annData, id: oldId };
            updateAnnotationListUI();
        } else {
            // Add new
            const ann = { ...annData, id: Date.now() };
            addAnnotation(ann);
        }

        clearPreviewPoint();
        _exitAnnotationMode();
    });

    // ---------- Copy/Export ----------
    document.getElementById('copyJsonBtn').addEventListener('click', copyAnnotationsAsJson);
    document.getElementById('copyCsvBtn').addEventListener('click',  copyAnnotationsAsCsv);

    // ---------- 3D Pick Handler (wired after scene exists) ----------
    // We defer until next tick to make sure scene is fully ready.
    setTimeout(_initPickHandler, 0);
}

// ------------------------------------------------------------------
// PICK HANDLER
// ------------------------------------------------------------------

function _initPickHandler() {
    if (!scene) { setTimeout(_initPickHandler, 100); return; }

    scene.onPointerDown = (evt, pickResult) => {
        if (!isAnnotating) return;
        if (evt.button !== 0) return; // left click only

        if (pickResult.hit && pickResult.pickedMesh) {
            const mesh = pickResult.pickedMesh;

            // Handle clicking existing hotspots
            if (mesh.name === 'hotspot_mesh') {
                const markerId = mesh.metadata?.id;
                if (markerId) selectAnnotationById(markerId);
                return;
            }

            if (!isAnnotating) return;

            const pt = pickResult.pickedPoint;
            const bary = _calculateBarycentric(pickResult);
            const rawNormal = pickResult.getNormal(true, true);

            currentPick = {
                meshName: mesh.name,
                triangleIndex: pickResult.faceId,
                worldPosition: [pt.x, pt.y, pt.z],
                normal: rawNormal ? [rawNormal.x, rawNormal.y, rawNormal.z] : [0, 1, 0],
                barycentric: [bary.x, bary.y, bary.z],
                cameraOrbit: [camera.alpha, camera.beta, camera.radius],
                cameraTarget: [camera.target.x, camera.target.y, camera.target.z]
            };

            document.getElementById('pickedMesh').innerText = mesh.name;
            document.getElementById('pickedFace').innerText = pickResult.faceId;
            document.getElementById('pickData').classList.remove('hidden');
            document.getElementById('addBtn').disabled = false;
            
            // SHOW DOT INSTANTLY
            setPreviewPoint([pt.x, pt.y, pt.z]);

            updateStatus('Captured face ' + pickResult.faceId + ' at [' + bary.x.toFixed(2) + ', ' + bary.y.toFixed(2) + ', ' + bary.z.toFixed(2) + ']');
        }
    };
}

// ------------------------------------------------------------------
// FORM HELPERS
// ------------------------------------------------------------------

function _exitAnnotationMode() {
    isAnnotating = false;
    _editingIndex = -1;
    clearPreviewPoint();
    document.getElementById('addBtn').innerText = 'Add';
    document.getElementById('annotationForm').classList.add('hidden');
    document.getElementById('mainActions').classList.remove('hidden');
    updateStatus('Ready');
}

function _resetForm() {
    const fields = {
        nodeTitle: '', nodeDesc: '', nodeMore: '',
        nodeOffset: '0.01', nodeMinDist: '0.2',
        nodeMaxDist: '20.0', nodeTransition: '0.5'
    };
    Object.entries(fields).forEach(([id, val]) => {
        document.getElementById(id).value = val;
    });
    document.getElementById('nodeBillboard').checked   = true;
    document.getElementById('nodeHideOccluded').checked = true;
    document.getElementById('pickedMesh').innerText = 'None';
    document.getElementById('pickedFace').innerText = 'None';
    document.getElementById('pickData').classList.add('hidden');
    document.getElementById('addBtn').disabled = true;
    currentPick = null;
}

// ------------------------------------------------------------------
// STATUS BAR
// ------------------------------------------------------------------

function updateStatus(text) {
    const bar = document.getElementById('statusBar');
    if (bar) bar.innerText = text;
}

// ------------------------------------------------------------------
// ANNOTATION LIST RENDER
// ------------------------------------------------------------------

function updateAnnotationListUI() {
    const listItems = document.getElementById('listItems');
    const countSpan = document.getElementById('count');
    const copyJson = document.getElementById('copyJsonBtn');
    const copyCsv = document.getElementById('copyCsvBtn');

    listItems.innerHTML = '';
    countSpan.innerText = annotations.length;
    copyJson.disabled = annotations.length === 0;
    copyCsv.disabled = annotations.length === 0;

    annotations.forEach((ann, index) => {
        const div = document.createElement('div');
        div.className = 'annotation-item' + (ann.isSelected ? ' selected' : '');
        div.id = 'ann-item-' + ann.id;
        div.innerHTML = `
            <div class="ann-info" onclick="selectAnnotationById(${ann.id})">
                <strong>${_esc(ann.ui.title)}</strong>
                <small>${_esc(ann.surface.meshName)} · face ${ann.surface.triangleIndex}</small>
                ${ann.ui.description ? `<small class="ann-desc">${_esc(ann.ui.description)}</small>` : ''}
            </div>
            <div style="display:flex;gap:4px;flex-shrink:0">
                <button class="secondary btn-sm" onclick="editAnnotation(${index})" title="Edit info">✏️</button>
                <button class="secondary btn-sm" onclick="focusAnnotation(${index})" title="Focus camera">🎯</button>
                <button class="danger btn-sm"    onclick="deleteAnnotation(${index})" title="Delete">🗑</button>
            </div>
        `;
        listItems.appendChild(div);
    });
}

/** 
 * Open the annotation form in edit mode for an existing annotation.
 */
function editAnnotation(idx) {
    const ann = annotations[idx];
    if (!ann) return;

    _editingIndex = idx;
    isAnnotating = true;

    // Fill form with current data
    document.getElementById('nodeTitle').value = ann.ui.title;
    document.getElementById('nodeDesc').value  = ann.ui.description;
    document.getElementById('nodeMore').value  = ann.ui.more;
    document.getElementById('nodeOffset').value = ann.placement.offset;
    document.getElementById('nodeMinDist').value = ann.visibility.minDistance;
    document.getElementById('nodeMaxDist').value = ann.visibility.maxDistance;
    document.getElementById('nodeTransition').value = ann.camera.transitionDuration;
    document.getElementById('nodeBillboard').checked = ann.placement.billboard;
    document.getElementById('nodeHideOccluded').checked = ann.visibility.hideWhenOccluded;

    // Visual picked info (not editable but helpful)
    document.getElementById('pickedMesh').innerText = ann.surface.meshName;
    document.getElementById('pickedFace').innerText = ann.surface.triangleIndex;
    document.getElementById('pickData').classList.remove('hidden');

    document.getElementById('addBtn').innerText = 'Update';
    document.getElementById('addBtn').disabled = false;
    document.getElementById('annotationForm').classList.remove('hidden');
    document.getElementById('mainActions').classList.add('hidden');

    updateStatus('Editing: ' + ann.ui.title);
    selectAnnotationById(ann.id);
}

/** 
 * Select an annotation by its ID, highlighting both 3D and UI.
 */
function selectAnnotationById(id) {
    let focusIndex = -1;
    annotations.forEach((ann, idx) => {
        ann.isSelected = (ann.id === id);
        if (ann.isSelected) focusIndex = idx;
        // Notify 3D manager to update marker visual
        updateMarkerSelection(ann.id, ann.isSelected);
    });
    updateAnnotationListUI();
    if (focusIndex !== -1) {
        // Smoothly scroll the sidebar item into view
        document.getElementById('ann-item-' + id)?.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }
}

/** Focus the camera smoothly on the annotation's recorded camera position. */
function focusAnnotation(idx) {
    const ann = annotations[idx];
    if (!ann || !camera) return;
    
    selectAnnotationById(ann.id);

    const [alpha, beta, radius] = ann.camera.orbit;
    const [tx, ty, tz] = ann.camera.target;
    // ... rest same
    const duration = (ann.camera.transitionDuration || 0.5) * 60; // frames at 60fps

    BABYLON.Animation.CreateAndStartAnimation(
        'camAlpha', camera, 'alpha', 60, duration,
        camera.alpha, alpha, BABYLON.Animation.ANIMATIONLOOPMODE_CONSTANT
    );
    BABYLON.Animation.CreateAndStartAnimation(
        'camBeta', camera, 'beta', 60, duration,
        camera.beta, beta, BABYLON.Animation.ANIMATIONLOOPMODE_CONSTANT
    );
    BABYLON.Animation.CreateAndStartAnimation(
        'camRadius', camera, 'radius', 60, duration,
        camera.radius, radius, BABYLON.Animation.ANIMATIONLOOPMODE_CONSTANT
    );
    camera.target = new BABYLON.Vector3(tx, ty, tz);
    updateStatus('Focusing on: ' + ann.ui.title);
}

function _esc(s) {
    return String(s || '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

/** Calculate barycentric coordinates for a pick result. */
function _calculateBarycentric(pick) {
    const mesh = pick.pickedMesh;
    const indices = mesh.getIndices();
    const positions = mesh.getVerticesData(BABYLON.VertexBuffer.PositionKind);
    if (!indices || !positions) return { x: 0.33, y: 0.33, z: 0.34 };

    const i1 = indices[pick.faceId * 3];
    const i2 = indices[pick.faceId * 3 + 1];
    const i3 = indices[pick.faceId * 3 + 2];

    const v1 = BABYLON.Vector3.FromArray(positions, i1 * 3);
    const v2 = BABYLON.Vector3.FromArray(positions, i2 * 3);
    const v3 = BABYLON.Vector3.FromArray(positions, i3 * 3);

    // Coordinate transformation to world space
    const wm = mesh.getWorldMatrix();
    const p1 = BABYLON.Vector3.TransformCoordinates(v1, wm);
    const p2 = BABYLON.Vector3.TransformCoordinates(v2, wm);
    const p3 = BABYLON.Vector3.TransformCoordinates(v3, wm);
    const p  = pick.pickedPoint;

    // Math: P = A + u(B-A) + v(C-A)
    const f1 = p1.subtract(p);
    const f2 = p2.subtract(p);
    const f3 = p3.subtract(p);

    const va = BABYLON.Vector3.Cross(p1.subtract(p2), p1.subtract(p3)).length();
    const va1 = BABYLON.Vector3.Cross(f2, f3).length();
    const va2 = BABYLON.Vector3.Cross(f3, f1).length();
    const va3 = BABYLON.Vector3.Cross(f1, f2).length();

    return { x: va1 / va, y: va2 / va, z: va3 / va };
}
