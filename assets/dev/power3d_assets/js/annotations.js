let annotations = [];
let annotationStyle = '';
let annotationContainer = null;
const annotationElements = new Map();
const hotspotMeshes = new Map(); // id -> BABYLON.Mesh (3D dots)

/**
 * Initializes the annotation system.
 */
function initAnnotations() {
    if (!annotationContainer) {
        annotationContainer = document.createElement('div');
        annotationContainer.id = 'power3d-annotations-container';
        annotationContainer.style.position = 'absolute';
        annotationContainer.style.top = '0';
        annotationContainer.style.left = '0';
        annotationContainer.style.width = '100%';
        annotationContainer.style.height = '100%';
        annotationContainer.style.pointerEvents = 'none';
        annotationContainer.style.overflow = 'hidden';
        annotationContainer.style.zIndex = '100';
        document.body.appendChild(annotationContainer);
    }

    // Register render observer to update positions
    scene.onBeforeRenderObservable.add(() => {
        updateAnnotationPositions();
    });
}

/**
 * Sets the annotations list.
 * @param {string} json JSON string of annotations.
 */
function setAnnotations(json) {
    try {
        let data = JSON.parse(json);
        if (!Array.isArray(data)) {
            data = [data];
        }
        annotations = data;
        
        // Mark for update
        annotations.forEach(ann => {
            ann._needsUpdate = true;
        });

        renderAnnotations();
    } catch (e) {
        console.error("Error parsing annotations:", e);
    }
}

/**
 * Sets the annotation style (HTML/CSS/JS).
 * @param {string} style Combined style string.
 */
function setAnnotationStyle(style) {
    annotationStyle = style;
    
    // Extract CSS
    const cssMatch = style.match(/<style>([\s\S]*?)<\/style>/);
    if (cssMatch) {
        let styleEl = document.getElementById('power3d-annotation-styles');
        if (!styleEl) {
            styleEl = document.createElement('style');
            styleEl.id = 'power3d-annotation-styles';
            document.head.appendChild(styleEl);
        }
        styleEl.textContent = cssMatch[1];
    }

    // Re-render annotations with new style
    renderAnnotations();
}

/**
 * Renders the annotations as DOM elements and 3D hotspots.
 */
function renderAnnotations() {
    if (!annotationContainer || !scene) return;

    const activeIds = new Set(annotations.map(a => a.id.toString()));

    // Clear existing 2D elements and 3D meshes that are no longer in the list
    for (const [id, el] of annotationElements.entries()) {
        if (!activeIds.has(id)) {
            annotationContainer.removeChild(el);
            annotationElements.delete(id);
        }
    }
    for (const [id, mesh] of hotspotMeshes.entries()) {
        if (!activeIds.has(id)) {
            mesh.dispose();
            hotspotMeshes.delete(id);
        }
    }

    // Create or update elements
    annotations.forEach(anno => {
        const idStr = anno.id.toString();
        
        // 1. Manage 3D Hotspot Mesh (Side project style)
        if (!hotspotMeshes.has(idStr)) {
            const sphere = BABYLON.MeshBuilder.CreateSphere(`hotspot-${idStr}`, { diameter: 1, segments: 12 }, scene);
            sphere.scaling.setAll(0.015); // standard marker size
            sphere.isPickable = true;
            sphere.renderingGroupId = 1; // always on top
            
            const mat = new BABYLON.StandardMaterial(`hotspot-mat-${idStr}`, scene);
            mat.emissiveColor = new BABYLON.Color3(0, 0.48, 1); // #007AFF
            mat.disableLighting = true;
            sphere.material = mat;
            
            sphere.metadata = { annotationId: anno.id };
            hotspotMeshes.set(idStr, sphere);
            
            // Sphere click focuses annotation
            sphere.actionManager = new BABYLON.ActionManager(scene);
            sphere.actionManager.registerAction(new BABYLON.ExecuteCodeAction(
                BABYLON.ActionManager.OnPickDownTrigger,
                () => focusOnAnnotation(anno)
            ));
        }

        // 2. Manage 2D DOM Element
        if (!annotationElements.has(idStr)) {
            const el = createAnnotationElement(anno);
            annotationContainer.appendChild(el);
            annotationElements.set(idStr, el);
        } else {
            updateElementData(annotationElements.get(idStr), anno);
        }
    });
}

/**
 * Creates a DOM element for an annotation based on the style template.
 */
function createAnnotationElement(anno) {
    const tempDiv = document.createElement('div');
    
    // Extract HTML part from style (everything outside <style> and <script>)
    const htmlTemplate = annotationStyle.replace(/<style>[\s\S]*?<\/style>/g, '')
                                     .replace(/<script>[\s\S]*?<\/script>/g, '')
                                     .trim();
    
    // Replace placeholders
    const renderedHtml = htmlTemplate.replace(/{{id}}/g, anno.id)
                                    .replace(/{{title}}/g, anno.ui.title || '')
                                    .replace(/{{description}}/g, anno.ui.description || '')
                                    .replace(/{{more}}/g, anno.ui.more || '#');
    
    tempDiv.innerHTML = renderedHtml;
    const el = tempDiv.firstElementChild;
    if (!el) return document.createElement('div');
    
    el.id = `annotation-${anno.id}`;
    
    // Add click listener for camera focusing
    el.addEventListener('click', (e) => {
        if (anno.camera) {
            focusOnAnnotation(anno);
            e.stopPropagation();
        }
    });

    return el;
}

function focusOnAnnotation(anno) {
    if (typeof transitionCamera === 'function' && anno.camera.orbit && anno.camera.target) {
        transitionCamera(
            anno.camera.orbit[0], 
            anno.camera.orbit[1], 
            anno.camera.orbit[2], 
            { x: anno.camera.target[0], y: anno.camera.target[1], z: anno.camera.target[2] }, 
            (anno.camera.transitionDuration || 0.5) * 1000
        );
    }
}

/**
 * Updates existing element data.
 */
function updateElementData(el, anno) {
    // Basic implementation: update common fields if they exist in the template
    const titleEl = el.querySelector('.power3d-tooltip-title');
    if (titleEl) titleEl.textContent = anno.ui.title || '';
    
    const descEl = el.querySelector('.power3d-tooltip-body');
    if (descEl) descEl.textContent = anno.ui.description || '';
}

/**
 * Updates the screen position and visibility of all annotations.
 */
function updateAnnotationPositions() {
    if (!scene || !canvas) return;

    annotations.forEach(anno => {
        const idStr = anno.id.toString();
        const el = annotationElements.get(idStr);
        const hotspot = hotspotMeshes.get(idStr);
        if (!el) return;

        let mesh = scene.getMeshByName(anno.surface.meshName);
        if (!mesh) {
            const searchName = anno.surface.meshName.toLowerCase();
            mesh = scene.meshes.find(m => m.name.toLowerCase().includes(searchName));
        }

        // FALLBACK: For diagnostic testing, use the first renderable mesh if still not found
        if (!mesh && anno.id === "test-01") {
            mesh = scene.meshes.find(m => m.getTotalVertices() > 0);
        }

        if (!mesh) {
            el.classList.add('hidden');
            if (hotspot) hotspot.isVisible = false;
            return;
        }

        // 1. Determine world position
        let worldPosition;
        if (anno.internal_worldPosition && !anno._needsUpdate) {
            worldPosition = BABYLON.Vector3.FromArray(anno.internal_worldPosition);
        } else {
            const localPosition = getPositionOnMesh(mesh, anno.surface.triangleIndex, anno.surface.barycentric);
            if (!localPosition) return;

            worldPosition = BABYLON.Vector3.TransformCoordinates(localPosition, mesh.getWorldMatrix());
            
            // Apply placement offset in WORLD space along the normal
            if (anno.placement && anno.placement.offset) {
                const normal = (anno.placement.normal) ? 
                    new BABYLON.Vector3(anno.placement.normal[0], anno.placement.normal[1], anno.placement.normal[2]) :
                    BABYLON.Vector3.Up();
                
                // Transform normal if needed, but side project usually gives world normal
                worldPosition.addInPlace(normal.scale(anno.placement.offset));
            }

            anno.internal_worldPosition = [worldPosition.x, worldPosition.y, worldPosition.z];
            delete anno._needsUpdate;
        }

        // 2. Update 3D Hotspot position
        if (hotspot) {
            hotspot.position.copyFrom(worldPosition);
            hotspot.isVisible = true;
        }

        // 3. Project to 2D
        const screenPos = BABYLON.Vector3.Project(
            worldPosition,
            BABYLON.Matrix.Identity(),
            scene.getTransformMatrix(),
            scene.activeCamera.viewport.toGlobal(canvas.width, canvas.height)
        );

        // Visibility checks
        let visible = true;

        // Distance check
        const distance = BABYLON.Vector3.Distance(scene.activeCamera.position, worldPosition);
        if (anno.visibility) {
            if (distance < anno.visibility.minDistance || distance > anno.visibility.maxDistance) {
                visible = false;
            }
        }

        // Occlusion check
        if (visible && anno.visibility && anno.visibility.hideWhenOccluded) {
            const dir = worldPosition.subtract(scene.activeCamera.position);
            const ray = new BABYLON.Ray(scene.activeCamera.position, dir.normalize(), distance - 0.05);
            const pick = scene.pickWithRay(ray, (m) => m.isPickable && m.isVisible && m !== hotspot);
            if (pick && pick.hit && pick.pickedMesh && pick.pickedMesh !== mesh) {
                visible = false;
            }
        }

        // Frustum check
        if (visible && (screenPos.x < 0 || screenPos.x > canvas.width || screenPos.y < 0 || screenPos.y > canvas.height || screenPos.z < 0 || screenPos.z > 1)) {
            visible = false;
        }

        if (visible) {
            el.classList.remove('hidden');
            el.classList.add('visible');
            el.style.left = `${screenPos.x}px`;
            el.style.top = `${screenPos.y}px`;
        } else {
            el.classList.remove('visible');
            el.classList.add('hidden');
        }
    });
}

/**
 * Updates existing element data.
 */
function updateElementData(el, anno) {
    const titleEl = el.querySelector('.power3d-tooltip-title');
    if (titleEl) titleEl.textContent = anno.ui.title || '';
    
    const descEl = el.querySelector('.power3d-tooltip-body');
    if (descEl) descEl.textContent = anno.ui.description || '';
}

/**
 * Calculates the exact 3D position on a mesh given triangle index and barycentric coordinates.
 */
function getPositionOnMesh(mesh, triangleIndex, barycentric) {
    if (triangleIndex === undefined || triangleIndex === null || !barycentric) {
        return mesh.getBoundingInfo().boundingBox.center.clone();
    }

    const indices = mesh.getIndices();
    const positions = mesh.getVerticesData(BABYLON.VertexBuffer.PositionKind);
    
    if (!indices || !positions) return null;

    const i0 = indices[triangleIndex * 3];
    const i1 = indices[triangleIndex * 3 + 1];
    const i2 = indices[triangleIndex * 3 + 2];

    const v0 = BABYLON.Vector3.FromArray(positions, i0 * 3);
    const v1 = BABYLON.Vector3.FromArray(positions, i1 * 3);
    const v2 = BABYLON.Vector3.FromArray(positions, i2 * 3);

    // P = w1*V0 + w2*V1 + w3*V2
    const result = v0.scale(barycentric[0])
                    .add(v1.scale(barycentric[1]))
                    .add(v2.scale(barycentric[2]));

    return result;
}

// Map polyfill or helper if needed, but modern browsers in WebView support Map.
if (!annotationElements.remove) {
    annotationElements.remove = function(key) {
        this.delete(key);
    };
}
if (!annotationElements.getProperty) {
    annotationElements.getProperty = function(key) {
        return this.get(key);
    };
}
