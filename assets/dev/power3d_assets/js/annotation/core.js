/**
 * Power3D – Annotation Engine Core (js/annotation/core.js)
 * Adopts babylon_annotator logic using BABYLON.GUI for robust positioning.
 */
'use strict';

window.Power3DAnnotationEngine = (() => {
    let _annotations = [];
    let _markers = new Map(); // id -> { sphere: BABYLON.Mesh, label: BABYLON.GUI.Rectangle, element: HTMLElement }
    let _guiTexture = null;
    let _container = null;
    let _style = null;
    let _visible = true;

    function init() {
        if (!_container) {
            _container = document.createElement('div');
            _container.id = 'p3d-ann-layer';
            _container.style.cssText = 'position:absolute;inset:0;pointer-events:none;z-index:1000;overflow:hidden;';
            document.body.appendChild(_container);
        }

        if (window.scene && !_guiTexture) {
            // Using AdvancedDynamicTexture like babylon_annotator
            _guiTexture = BABYLON.GUI.AdvancedDynamicTexture.CreateFullscreenUI("Power3DAnnotations", true, window.scene);
            window.scene.onBeforeRenderObservable.add(_updateHTMLOverlays);
            console.log("[AnnotationEngine] GUI Texture initialized.");
        }
    }

    function useStyle(styleModule) {
        _style = styleModule;
        _rebuild();
    }

    function setAnnotations(data) {
        _annotations = Array.isArray(data) ? data : (typeof data === 'string' ? JSON.parse(data) : [data]);
        console.log("[AnnotationEngine] Received annotations:", _annotations.length);
        _rebuild();
    }

    function _rebuild() {
        if (!window.scene || !_guiTexture) return;

        // Cleanup
        _markers.forEach(m => {
            if (m.sphere) m.sphere.dispose();
            if (m.label) m.label.dispose();
            if (m.element && m.element.parentNode) m.element.parentNode.removeChild(m.element);
        });
        _markers.clear();
        _container.innerHTML = '';

        _annotations.forEach(ann => {
            const worldPos = _calculateWorldPos(ann);
            if (!worldPos) {
                console.warn("[AnnotationEngine] Skip missing mesh/face:", ann.surface.meshName, ann.surface.triangleIndex);
                return;
            }

            // 1. Create a tracking sphere like babylon_annotator
            const sphere = BABYLON.MeshBuilder.CreateSphere("hotspot_" + ann.id, { diameter: 0.02 }, window.scene);
            sphere.position = worldPos;
            sphere.isVisible = false;
            sphere.isPickable = false;

            // 2. Create a GUI Label for stable coordinate extraction
            // We use this dummy label to leverage linkWithMesh logic which is perfectly stable in Babylon
            const label = new BABYLON.GUI.Rectangle("label_" + ann.id);
            label.width = "0px";
            label.height = "0px";
            label.thickness = 0;
            label.alpha = 0;
            _guiTexture.addControl(label);
            label.linkWithMesh(sphere);

            // 3. Create the HTML UI via the style module
            let element = null;
            if (_style && typeof _style.createDom === 'function') {
                element = _style.createDom(ann);
                _container.appendChild(element);
            }

            _markers.set(ann.id.toString(), { sphere, label, element, data: ann });
        });
        console.log("[AnnotationEngine] Rebuild finished. Markers:", _markers.size);
    }

    /**
     * Every frame, we sync the HTML elements with the GUI label positions.
     * This is the "secret sauce" of babylon_annotator stability.
     */
    function _updateHTMLOverlays() {
        if (!_visible) return;

        _markers.forEach((m, id) => {
            if (!m.element || !m.label) return;

            // label.centerX/centerY give us the screen coordinates automatically linked to mesh
            const screenX = m.label.centerX;
            const screenY = m.label.centerY;

            // Simple frustum check (GUI label internally handles hidden state if out of view)
            const isVisible = m.label.isVisible;

            if (isVisible) {
                m.element.style.display = 'block';
                m.element.style.left = screenX + 'px';
                m.element.style.top = screenY + 'px';
            } else {
                m.element.style.display = 'none';
            }
        });
    }

    function _calculateWorldPos(ann) {
        if (!window.scene) return null;
        let mesh = window.scene.getMeshByName(ann.surface.meshName);
        
        // Fuzzy search fallback
        if (!mesh) {
            mesh = window.scene.meshes.find(m => 
                m.name.toLowerCase().includes(ann.surface.meshName.toLowerCase()) && 
                m.getTotalVertices() > 0 &&
                !m.name.includes("__root__")
            );
        }

        if (!mesh) return null;

        const indices = mesh.getIndices();
        const positions = mesh.getVerticesData(BABYLON.VertexBuffer.PositionKind);
        const idx = ann.surface.triangleIndex;
        const b = ann.surface.barycentric;

        if (!indices || !positions || (idx * 3 + 2) >= indices.length) return null;

        const i0 = indices[idx * 3], i1 = indices[idx * 3 + 1], i2 = indices[idx * 3 + 2];
        const v0 = BABYLON.Vector3.FromArray(positions, i0 * 3);
        const v1 = BABYLON.Vector3.FromArray(positions, i1 * 3);
        const v2 = BABYLON.Vector3.FromArray(positions, i2 * 3);

        const local = v0.scale(b[0]).add(v1.scale(b[1])).add(v2.scale(b[2]));
        const world = BABYLON.Vector3.TransformCoordinates(local, mesh.getWorldMatrix());

        if (ann.placement?.offset && ann.placement?.normal) {
            const norm = new BABYLON.Vector3(...ann.placement.normal);
            world.addInPlace(norm.scale(ann.placement.offset));
        }
        return world;
    }

    function setVisible(v) {
        _visible = v;
        if (_container) _container.style.display = v ? 'block' : 'none';
        if (_guiTexture) _guiTexture.rootContainer.isVisible = v;
    }

    function refresh() { _rebuild(); }

    function flyTo(cfg) {
        if (!window.scene || !window.scene.activeCamera) return;
        const cam = window.scene.activeCamera;
        const dur = (cfg.transitionDuration || 0.5) * 60;
        BABYLON.Animation.CreateAndStartAnimation('cA', cam, 'alpha', 60, dur, cam.alpha, cfg.orbit[0], 0);
        BABYLON.Animation.CreateAndStartAnimation('cB', cam, 'beta', 60, dur, cam.beta, cfg.orbit[1], 0);
        BABYLON.Animation.CreateAndStartAnimation('cR', cam, 'radius', 60, dur, cam.radius, cfg.orbit[2], 0);
        const targetVec = new BABYLON.Vector3(...cfg.target);
        cam.setTarget(targetVec);
    }

    return { init, setAnnotations, useStyle, setVisible, refresh, flyTo };
})();
