/**
 * Power3D Tooltip Style (js/annotation/styles/tooltip.js)
 * Self-contained style with premium aesthetics.
 */
'use strict';

window.Power3DTooltipStyle = (() => {
    function injectStyles() {
        if (document.getElementById('p3d-tooltip-style')) return;
        const style = document.createElement('style');
        style.id = 'p3d-tooltip-style';
        style.textContent = `
            .p3d-tooltip-el {
                position: absolute;
                pointer-events: auto;
                transform: translate(-50%, -100%);
                margin-top: -12px;
                z-index: 2100;
                font-family: 'Inter', system-ui, -apple-system, sans-serif;
                cursor: pointer;
            }
            .p3d-tooltip-card {
                background: rgba(15, 23, 42, 0.95);
                border: 1px solid rgba(255, 255, 255, 0.1);
                border-radius: 12px;
                padding: 12px;
                width: 220px;
                -webkit-backdrop-filter: blur(12px);
                backdrop-filter: blur(12px);
                box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.5), 0 8px 10px -6px rgba(0, 0, 0, 0.5);
                transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
                opacity: 0.9;
            }
            .p3d-tooltip-el:hover .p3d-tooltip-card {
                opacity: 1;
                transform: scale(1.02);
            }
            .p3d-tooltip-title { 
                color: #f8fafc; 
                font-weight: 700; 
                font-size: 14px; 
                margin: 0;
                letter-spacing: -0.01em;
            }
            .p3d-tooltip-content { 
                max-height: 0; 
                overflow: hidden; 
                opacity: 0; 
                transition: all 0.4s ease;
                color: #94a3b8;
                font-size: 12px;
                line-height: 1.5;
            }
            .p3d-tooltip-el.active .p3d-tooltip-content {
                max-height: 200px;
                opacity: 1;
                margin-top: 10px;
                border-top: 1px solid rgba(255, 255, 255, 0.05);
                padding-top: 10px;
            }
            .p3d-tooltip-dot {
                width: 12px;
                height: 12px;
                background: #38bdf8;
                border: 2px solid #fff;
                border-radius: 50%;
                margin: 4px auto 0;
                box-shadow: 0 0 12px rgba(56, 189, 248, 0.5);
                transition: all 0.3s ease;
            }
            .p3d-tooltip-el.active .p3d-tooltip-dot {
                background: #fb923c;
                box-shadow: 0 0 15px rgba(251, 146, 60, 0.7);
                transform: scale(1.2);
            }
            @keyframes p3d-pulse {
                0% { box-shadow: 0 0 0 0 rgba(56, 189, 248, 0.4); }
                70% { box-shadow: 0 0 0 10px rgba(56, 189, 248, 0); }
                100% { box-shadow: 0 0 0 0 rgba(56, 189, 248, 0); }
            }
            .p3d-tooltip-el:not(.active) .p3d-tooltip-dot {
                animation: p3d-pulse 2s infinite;
            }
        `;
        document.head.appendChild(style);
    }

    function createDom(ann) {
        injectStyles();
        const el = document.createElement('div');
        el.className = 'p3d-tooltip-el';
        el.dataset.id = ann.id;
        
        el.innerHTML = `
            <div class="p3d-tooltip-card">
                <p class="p3d-tooltip-title">${ann.ui.title}</p>
                <div class="p3d-tooltip-content">
                    ${ann.ui.description || ''}
                    ${ann.ui.more ? `<br><a href="${ann.ui.more}" target="_blank" style="color:#38bdf8;text-decoration:none;font-weight:600;display:block;margin-top:8px;">Learn More →</a>` : ''}
                </div>
            </div>
            <div class="p3d-tooltip-dot"></div>
        `;

        el.onclick = (e) => {
            e.stopPropagation();
            // Close others
            document.querySelectorAll('.p3d-tooltip-el').forEach(o => {
                if(o !== el) o.classList.remove('active');
            });
            
            const isActive = el.classList.toggle('active');
            if (isActive && ann.camera && window.Power3DAnnotationEngine) {
                window.Power3DAnnotationEngine.flyTo(ann.camera);
            }
        };

        if (ann.isSelected) el.classList.add('active');
        return el;
    }

    return { createDom };
})();
