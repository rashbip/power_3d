// =============================================================================
// annotations.js  –  Power3D annotation system
// Entry points: loadAnnotationsFromFlutter, clearAnnotationsFromFlutter,
//               focusAnnotationById
// All are exposed on window so inline HTML (onclick) and model-loader can call them.
// =============================================================================

(function () {
    'use strict';

    // ── State ──────────────────────────────────────────────────────────────────
    let _annotations  = [];
    let _markers      = [];   // { sphere, label, ann }
    let _mode         = 'html';
    let _htmlTemplate = null;

    // ── Helpers ────────────────────────────────────────────────────────────────
    function _scene()  { return window.scene;  }
    function _camera() { return window.scene && window.scene.activeCamera; }

    // ── Public API ─────────────────────────────────────────────────────────────

    /**
     * Called by Flutter: inject a list of annotation objects and display them.
     * @param {Array}   jsonList     - parsed annotation objects
     * @param {string}  mode         - 'html' | 'dart'
     * @param {string|null} template - optional HTML template string
     */
    window.loadAnnotationsFromFlutter = function (jsonList, mode, template) {
        clearAnnotationsFromFlutter();
        _annotations  = Array.isArray(jsonList) ? jsonList : [];
        _mode         = mode || 'html';
        _htmlTemplate = template || null;

        _annotations.forEach(function (ann) {
            const entry = _createMarker(ann);
            if (entry) _markers.push(entry);
        });
    };

    /**
     * Called by Flutter: remove all markers and close any open card.
     */
    window.clearAnnotationsFromFlutter = function () {
        _markers.forEach(function (entry) {
            try { if (entry.sphere)  entry.sphere.dispose();  } catch (_) {}
        });
        _markers      = [];
        _annotations  = [];
        _closeCard();
    };

    /**
     * Called by Flutter: smoothly animate camera to annotation's saved viewpoint.
     * @param {string|number} id
     */
    window.focusAnnotationById = function (id) {
        const ann = _annotations.find(function (a) { return String(a.id) === String(id); });
        if (!ann) return;
        const cam = _camera();
        if (!cam) return;
        _animateCamera(cam, ann.camera);
    };

    /**
     * Close the current HTML card overlay (also called from onclick in HTML).
     */
    window._closeAnnotationCard = function () {
        _closeCard();
    };

    // ── Marker creation ────────────────────────────────────────────────────────

    function _createMarker(ann) {
        const sc = _scene();
        if (!sc) return null;

        // 1. Reconstruct world position from barycentric coords
        const pos = _barycentricToWorld(ann, sc);
        if (!pos) {
            console.warn('[Annotations] Could not reconstruct position for annotation', ann.id, '– mesh:', ann.surface && ann.surface.meshName);
            return null;
        }

        // 2. Apply normal offset
        let wx = pos.x, wy = pos.y, wz = pos.z;
        if (ann.placement && ann.placement.normal) {
            const n   = ann.placement.normal;
            const off = ann.placement.offset || 0.01;
            wx += n[0] * off;
            wy += n[1] * off;
            wz += n[2] * off;
        }

        // 3. Build sphere marker
        const sphere = BABYLON.MeshBuilder.CreateSphere(
            'ann_sphere_' + ann.id,
            { diameter: 0.05, segments: 8 },
            sc
        );
        sphere.position = new BABYLON.Vector3(wx, wy, wz);

        const mat = new BABYLON.StandardMaterial('ann_mat_' + ann.id, sc);
        mat.diffuseColor  = new BABYLON.Color3(0.15, 0.55, 1.0);
        mat.emissiveColor = new BABYLON.Color3(0.05, 0.25, 0.6);
        mat.disableLighting = false;
        sphere.material = mat;

        // 4. Pulse animation so markers are easy to spot
        const anim = new BABYLON.Animation(
            'ann_pulse_' + ann.id,
            'scaling',
            30,
            BABYLON.Animation.ANIMATIONTYPE_VECTOR3,
            BABYLON.Animation.ANIMATIONLOOPMODE_CYCLE
        );
        anim.setKeys([
            { frame: 0,  value: new BABYLON.Vector3(1, 1, 1) },
            { frame: 15, value: new BABYLON.Vector3(1.3, 1.3, 1.3) },
            { frame: 30, value: new BABYLON.Vector3(1, 1, 1) },
        ]);
        sphere.animations = [anim];
        sc.beginAnimation(sphere, 0, 30, true, 1.0);

        // 5. Click handler
        sphere.isPickable = true;
        sphere.actionManager = new BABYLON.ActionManager(sc);
        sphere.actionManager.registerAction(
            new BABYLON.ExecuteCodeAction(
                BABYLON.ActionManager.OnPickTrigger,
                function () { _onMarkerClick(ann); }
            )
        );

        return { sphere: sphere, ann: ann };
    }

    // ── Click handling ─────────────────────────────────────────────────────────

    function _onMarkerClick(ann) {
        if (_mode === 'dart') {
            // Let Flutter handle the UI
            if (typeof sendMessageToFlutter === 'function') {
                sendMessageToFlutter({ type: 'annotationTapped', data: ann });
            }
        } else {
            _showCard(ann);
        }
    }

    // ── HTML card ──────────────────────────────────────────────────────────────

    function _showCard(ann) {
        _closeCard();

        const overlay = document.getElementById('annotation-overlay');
        if (!overlay) return;

        let tmpl = _htmlTemplate;
        if (!tmpl) {
            tmpl = [
                '<div class="annotation-card-popup">',
                '  <div class="card-header">',
                '    <h4>{{title}}</h4>',
                '    <button class="close-btn" onclick="window._closeAnnotationCard()">&#x2715;</button>',
                '  </div>',
                '  <div class="card-content">',
                '    {{#description}}<p>{{description}}</p>{{/description}}',
                '    {{#more}}<a href="{{more}}" target="_blank" class="m3-button-text">Learn More &#x2192;</a>{{/more}}',
                '  </div>',
                '</div>',
            ].join('\n');
        }

        let html = tmpl
            .replace(/{{title}}/g,       _esc(ann.ui.title))
            .replace(/{{id}}/g,           _esc(String(ann.id)));

        // {{#description}}...{{/description}}
        if (ann.ui.description) {
            html = html
                .replace(/{{#description}}([\s\S]*?){{\/description}}/g, '$1')
                .replace(/{{description}}/g, _esc(ann.ui.description));
        } else {
            html = html.replace(/{{#description}}[\s\S]*?{{\/description}}/g, '');
        }

        // {{#more}}...{{/more}}
        if (ann.ui.more) {
            html = html
                .replace(/{{#more}}([\s\S]*?){{\/more}}/g, '$1')
                .replace(/{{more}}/g, ann.ui.more); // URLs – don't escape
        } else {
            html = html.replace(/{{#more}}[\s\S]*?{{\/more}}/g, '');
        }

        overlay.innerHTML = html;
        overlay.classList.add('visible');
    }

    function _closeCard() {
        const overlay = document.getElementById('annotation-overlay');
        if (overlay) {
            overlay.innerHTML = '';
            overlay.classList.remove('visible');
        }
    }

    // ── Camera animation ───────────────────────────────────────────────────────

    function _animateCamera(cam, camData) {
        if (!camData) return;

        const orbit  = camData.orbit;   // [alpha, beta, radius]
        const target = camData.target;  // [x, y, z]
        const fps    = 60;
        const frames = Math.max(1, Math.round((camData.transitionDuration || 0.5) * fps));

        const ease = new BABYLON.CubicEase();
        ease.setEasingMode(BABYLON.EasingFunction.EASINGMODE_EASEINOUT);

        function _animProp(name, from, to, type) {
            const a = new BABYLON.Animation('ann_cam_' + name, name, fps, type,
                BABYLON.Animation.ANIMATIONLOOPMODE_CONSTANT);
            a.setKeys([{ frame: 0, value: from }, { frame: frames, value: to }]);
            a.setEasingFunction(ease);
            return a;
        }

        const targetVec = new BABYLON.Vector3(target[0], target[1], target[2]);
        const T = BABYLON.Animation.ANIMATIONTYPE_FLOAT;
        const TV = BABYLON.Animation.ANIMATIONTYPE_VECTOR3;

        window.scene.beginDirectAnimation(cam, [
            _animProp('alpha',  cam.alpha,  orbit[0], T),
            _animProp('beta',   cam.beta,   orbit[1], T),
            _animProp('radius', cam.radius, orbit[2], T),
            _animProp('target', cam.target, targetVec, TV),
        ], 0, frames, false);
    }

    // ── Barycentric reconstruction ─────────────────────────────────────────────

    function _barycentricToWorld(ann, sc) {
        if (!ann.surface) return null;

        const mesh = sc.getMeshByName(ann.surface.meshName);
        if (!mesh) return null;

        // Ensure vertex data is accessible (may be unindexed after instancing)
        const indices   = mesh.getIndices();
        const positions = mesh.getVerticesData(BABYLON.VertexBuffer.PositionKind);
        if (!indices || !positions || !indices.length) return null;

        const fid = ann.surface.triangleIndex;
        const b   = ann.surface.barycentric;

        // Safety check: triangle exists
        if (fid * 3 + 2 >= indices.length) return null;

        const i0 = indices[fid * 3];
        const i1 = indices[fid * 3 + 1];
        const i2 = indices[fid * 3 + 2];

        const v0 = BABYLON.Vector3.FromArray(positions, i0 * 3);
        const v1 = BABYLON.Vector3.FromArray(positions, i1 * 3);
        const v2 = BABYLON.Vector3.FromArray(positions, i2 * 3);

        // Local-space barycentric interpolation
        const local = v0.scale(b[0]).add(v1.scale(b[1])).add(v2.scale(b[2]));

        // Transform to world space
        return BABYLON.Vector3.TransformCoordinates(local, mesh.getWorldMatrix());
    }

    // ── Utility ────────────────────────────────────────────────────────────────

    function _esc(str) {
        return String(str)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

})();
