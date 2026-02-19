// UI Manager: Handles DOM events and form interaction
let isAnnotating = false;
let currentPick = null;

function initUI() {
    const dropZone = document.getElementById("dropZone");
    const fileInput = document.getElementById("fileInput");
    const newAnnotBtn = document.getElementById("newAnnotBtn");
    const cancelBtn = document.getElementById("cancelBtn");
    const addBtn = document.getElementById("addBtn");
    const downloadBtn = document.getElementById("downloadBtn");
    const randomBgBtn = document.getElementById("randomBgBtn");
    const urlLoadBtn = document.getElementById("urlLoadBtn");
    const urlInput = document.getElementById("urlInput");

    // Drag and Drop
    dropZone.onclick = () => fileInput.click();
    dropZone.ondragover = (e) => { e.preventDefault(); dropZone.classList.add("dragover"); };
    dropZone.ondragleave = () => { dropZone.classList.remove("dragover"); };
    dropZone.ondrop = (e) => {
        e.preventDefault();
        dropZone.classList.remove("dragover");
        if (e.dataTransfer.files.length > 0) loadModelFromFile(e.dataTransfer.files[0]);
    };
    fileInput.onchange = (e) => {
        if (e.target.files.length > 0) loadModelFromFile(e.target.files[0]);
    };

    // URL Loading
    urlLoadBtn.onclick = () => {
        const url = urlInput.value.trim();
        if (url) loadModelByUrl(url);
    };

    // Background Randomization
    randomBgBtn.onclick = randomizeBackground;

    // Animation UI
    const animPlayBtn = document.getElementById("animPlayBtn");
    const animPauseBtn = document.getElementById("animPauseBtn");
    const animStopBtn = document.getElementById("animStopBtn");
    const animSlider = document.getElementById("animSlider");
    const animSelect = document.getElementById("animationSelect");
    const animSpeedSelect = document.getElementById("animSpeedSelect");

    animPlayBtn.onclick = () => playAnimation(animSelect.value);
    animPauseBtn.onclick = () => pauseAnimation(animSelect.value);
    animStopBtn.onclick = () => stopAnimation(animSelect.value);
    
    animSelect.onchange = () => updateSliderRange(animSelect.value);
    
    animSlider.oninput = () => scrubAnimation(animSelect.value, animSlider.value);
    
    animSpeedSelect.onchange = () => setAnimationSpeed(animSelect.value, parseFloat(animSpeedSelect.value));

    // Mode Toggle
    newAnnotBtn.onclick = () => {
        isAnnotating = true;
        document.getElementById("annotationForm").classList.remove("hidden");
        document.getElementById("mainActions").classList.add("hidden");
        updateStatus("Annotation Mode: Click on model");
        resetForm();
    };

    cancelBtn.onclick = () => {
        isAnnotating = false;
        document.getElementById("annotationForm").classList.add("hidden");
        document.getElementById("mainActions").classList.remove("hidden");
        updateStatus("Ready");
    };

    // Click Picking
    scene.onPointerDown = (evt, pickResult) => {
        if (!isAnnotating) return;

        if (pickResult.hit && pickResult.pickedMesh) {
            const mesh = pickResult.pickedMesh;
            currentPick = {
                meshName: mesh.name,
                triangleIndex: pickResult.faceId,
                worldPosition: [pickResult.pickedPoint.x, pickResult.pickedPoint.y, pickResult.pickedPoint.z],
                normal: [pickResult.getNormal().x, pickResult.getNormal().y, pickResult.getNormal().z],
                barycentric: [0.33, 0.33, 0.34], // Placeholder
                cameraOrbit: [camera.alpha, camera.beta, camera.radius],
                cameraTarget: [camera.target.x, camera.target.y, camera.target.z]
            };

            document.getElementById("pickedMesh").innerText = mesh.name;
            document.getElementById("pickedFace").innerText = pickResult.faceId;
            document.getElementById("pickData").classList.remove("hidden");
            addBtn.disabled = false;
            updateStatus("Point captured at face " + pickResult.faceId);
        }
    };

    addBtn.onclick = () => {
        const annotation = {
            id: document.getElementById("nodeId").value,
            title: document.getElementById("nodeTitle").value || "Untitled",
            description: document.getElementById("nodeDesc").value,
            ...currentPick
        };
        addAnnotation(annotation);
        cancelBtn.click();
    };

    downloadBtn.onclick = exportAnnotations;
}

function updateStatus(text) {
    document.getElementById("statusBar").innerText = text;
}

function resetForm() {
    document.getElementById("nodeId").value = "hotspot_" + (annotations.length + 1);
    document.getElementById("nodeTitle").value = "";
    document.getElementById("nodeDesc").value = "";
    document.getElementById("pickedMesh").innerText = "None";
    document.getElementById("pickedFace").innerText = "None";
    document.getElementById("pickData").classList.add("hidden");
    document.getElementById("addBtn").disabled = true;
    currentPick = null;
}

function updateAnnotationListUI() {
    const listItems = document.getElementById("listItems");
    const countSpan = document.getElementById("count");
    listItems.innerHTML = "";
    countSpan.innerText = annotations.length;

    annotations.forEach((ann, index) => {
        const div = document.createElement("div");
        div.className = "annotation-item";
        div.innerHTML = `
            <strong>${ann.title}</strong> (${ann.id})<br>
            <small>${ann.meshName} - Tri: ${ann.triangleIndex}</small>
            <div class="actions">
                <button class="btn-small secondary" onclick="deleteAnnotation(${index})">Del</button>
            </div>
        `;
        listItems.appendChild(div);
    });
}
