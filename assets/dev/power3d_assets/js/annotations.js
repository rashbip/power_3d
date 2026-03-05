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

function setAnnotationStyle(styleName) {
    if (!styleName) return;
    const name = styleName.toLowerCase().trim();
    if ((name === 'tooltip' || name === 'toolpit') && window.Power3DTooltipStyle) {
        Power3DAnnotationEngine.useStyle(Power3DTooltipStyle);
    }
}

function setAnnotationsVisible(visible) {
    Power3DAnnotationEngine.setVisible(visible);
}

function onModelLoadedForAnnotations() {
    console.log("[JS Bridge] Refreshing annotations after model load.");
    Power3DAnnotationEngine.refresh();
}
