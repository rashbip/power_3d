/**
 * Power3D Annotations Bridge (js/annotations.js)
 */
'use strict';

function initAnnotations() {
    Power3DAnnotationEngine.init();
    // Default style: tooltip
    // We use a small timeout to ensure tooltip.js is fully parsed if needed
    setTimeout(() => {
        setAnnotationStyle('tooltip');
    }, 100);
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
    
    console.log("[JS Bridge] setAnnotationStyle called with:", style);

    // Built-in names
    if (s === 'tooltip' || s === 'toolpit') {
        if (window.Power3DTooltipStyle) {
            Power3DAnnotationEngine.useStyle(Power3DTooltipStyle);
        } else {
            console.warn("[JS Bridge] TooltipStyle object not found, maybe script not loaded yet.");
        }
        return;
    }

    // Dynamic file loading
    if (s.endsWith('.js')) {
        try {
            console.log("[JS Bridge] Attempting to load dynamic script:", style);
            await new Promise((resolve, reject) => {
                const script = document.createElement('script');
                script.src = style + "?t=" + new Date().getTime(); // Cache busting
                script.onload = () => {
                    console.log("[JS Bridge] Script loaded successfully:", style);
                    resolve();
                };
                script.onerror = (e) => {
                    console.error("[JS Bridge] Script load failed:", style, e);
                    reject(e);
                };
                document.head.appendChild(script);
            });

            // Resolve the correct style object from the global window
            // Pattern: base filename -> Power3D[Name]Style
            const base = style.split('/').pop().replace('.js', '').toLowerCase();
            
            // Look for matching object in window (case-insensitive approach)
            let foundStyle = null;
            const keys = Object.keys(window);
            for (const key of keys) {
                if (key.startsWith('Power3D') && key.endsWith('Style')) {
                    const styleName = key.replace('Power3D', '').replace('Style', '').toLowerCase();
                    if (styleName === base) {
                        foundStyle = window[key];
                        console.log("[JS Bridge] Found matching style object:", key);
                        break;
                    }
                }
            }

            if (foundStyle) {
                Power3DAnnotationEngine.useStyle(foundStyle);
            } else {
                console.error("[JS Bridge] Could not find style object for:", base);
            }
        } catch (e) {
            console.error("[JS Bridge] Error during dynamic style loading:", e);
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
