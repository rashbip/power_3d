/**
 * Power3D Annotations Bridge (js/annotations.js)
 */
'use strict';

function initAnnotations() {
    Power3DAnnotationEngine.init();
    // Default style: tooltip
    setAnnotationStyle('tooltip');
}

function setAnnotations(json) {
    console.log("[JS Bridge] setAnnotations called with data type:", typeof json);
    if (typeof json === 'string') {
        console.log("[JS Bridge] Data length:", json.length);
    }
    Power3DAnnotationEngine.setAnnotations(json);
}

async function setAnnotationStyle(style) {
    if (!style) return;
    const s = style.toLowerCase().trim();
    
    // Built-in names
    if (s === 'tooltip' || s === 'toolpit') {
        if (window.Power3DTooltipStyle) Power3DAnnotationEngine.useStyle(Power3DTooltipStyle);
        return;
    }

    // Dynamic file loading (from power3d_annotations)
    if (s.endsWith('.js')) {
        try {
            console.log("[JS Bridge] Loading dynamic style from:", style);
            await new Promise((resolve, reject) => {
                const script = document.createElement('script');
                script.src = style;
                script.onload = resolve;
                script.onerror = reject;
                document.head.appendChild(script);
            });

            // Map filename to expected global object
            const base = style.split('/').pop().replace('.js', '');
            const objName = 'Power3D' + base.charAt(0).toUpperCase() + base.slice(1) + 'Style';
            console.log("[JS Bridge] Looking for style object:", objName);
            
            if (window[objName]) {
                Power3DAnnotationEngine.useStyle(window[objName]);
            } else {
                console.error("[JS Bridge] Style object not found:", objName);
            }
        } catch (e) {
            console.error("[JS Bridge] Failed to load style:", style, e);
        }
    }
}

function setAnnotationsVisible(visible) {
    Power3DAnnotationEngine.setVisible(visible);
}

function onModelLoadedForAnnotations() {
    console.log("[JS Bridge] Refreshing annotations after model load.");
    Power3DAnnotationEngine.refresh();
}
