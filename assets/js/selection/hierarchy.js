function getPartsHierarchy(useCategorization = false) {
    if (!window.scene) return [];
    
    if (useCategorization) {
        return getPartsByCategorization();
    } else {
        return getPartsSceneGraph();
    }
}

function getPartsSceneGraph() {
    if (!window.scene) return [];
    
    const result = [];
    
    // 1. Nodes Category (Full Scene Graph)
    const nodesRoot = {
        name: 'Nodes',
        displayName: 'Nodes',
        type: 'section',
        children: []
    };
    
    const processedNodes = new Set();
    // Use rootNodes to maintain the structural hierarchy of the 3D model
    window.scene.rootNodes.forEach(node => {
        const hNode = buildNodeHierarchy(node, processedNodes);
        if (hNode) nodesRoot.children.push(hNode);
    });
    result.push(nodesRoot);

    // 2. Materials Category
    const materialsRoot = {
        name: 'Materials',
        displayName: 'Materials',
        type: 'section',
        children: window.scene.materials.map(mat => ({
            name: mat.name,
            displayName: mat.name,
            uniqueId: mat.uniqueId.toString(),
            type: 'material',
            children: []
        }))
    };
    result.push(materialsRoot);
    
    return result;
}

function buildNodeHierarchy(node, processedNodes) {
    if (!node || processedNodes.has(node.uniqueId)) return null;
    processedNodes.add(node.uniqueId);
    
    // Identify specialized types to match Babylon.js icons
    let type = 'node';
    if (node instanceof BABYLON.Mesh || node instanceof BABYLON.InstancedMesh) {
        type = 'mesh';
    } else if (node.getClassName && node.getClassName().includes('Camera')) {
        type = 'camera';
    } else if (node.getClassName && node.getClassName().includes('Light')) {
        type = 'light';
    } else if (node instanceof BABYLON.TransformNode) {
        type = 'transform';
    }
    
    const hierarchyNode = {
        name: node.name || `Node ${node.uniqueId}`,
        uniqueId: node.uniqueId.toString(),
        type: type,
        children: []
    };
    
    const childrenNodes = node.getChildren ? node.getChildren() : [];
    if (childrenNodes && childrenNodes.length > 0) {
        childrenNodes.forEach(child => {
            const childHierarchy = buildNodeHierarchy(child, processedNodes);
            if (childHierarchy) hierarchyNode.children.push(childHierarchy);
        });
    }
    
    return hierarchyNode;
}

function getPartsByCategorization() {
    if (!window.scene) return [];
    
    const categories = {};
    const unCategorizedNodes = [];
    
    window.scene.meshes.forEach(mesh => {
        if (!mesh.name || mesh.name.startsWith('__')) return;
        
        // Use a less aggressive separator to avoid splitting names like "Object_4"
        // Common 3D naming uses "/" or ":" for explicit grouping/nesting
        const parts = mesh.name.split('/');
        
        if (parts.length > 1) {
            const category = parts[0];
            const partName = parts.slice(1).join('/');
            
            if (!categories[category]) {
                categories[category] = {
                    name: category,
                    displayName: category,
                    type: 'category',
                    children: []
                };
            }
            
            categories[category].children.push({
                name: mesh.name,
                uniqueId: mesh.uniqueId.toString(),
                displayName: partName,
                type: 'mesh',
                children: []
            });
        } else {
            unCategorizedNodes.push({
                name: mesh.name,
                uniqueId: mesh.uniqueId.toString(),
                displayName: mesh.name,
                type: 'mesh',
                children: []
            });
        }
    });
    
    return [
        ...Object.values(categories),
        ...unCategorizedNodes
    ];
}

/**
 * Get extras data from a node
 */
function getNodeExtras(nodeIdentifier) {
    if (!window.scene) return {};
    
    let node = window.scene.getNodeByName(nodeIdentifier);
    if (!node) {
        const id = parseInt(nodeIdentifier);
        if (!isNaN(id)) {
            node = window.scene.getNodeByUniqueId(id);
        }
    }
    
    // If it's a material (materials are not in scene.nodes)
    if (!node) {
        const id = parseInt(nodeIdentifier);
        if (!isNaN(id)) {
            node = window.scene.materials.find(m => m.uniqueId === id);
        } else {
            node = window.scene.getMaterialByName(nodeIdentifier);
        }
    }
    
    if (!node) return {};
    
    let type = 'node';
    if (node instanceof BABYLON.Mesh) type = 'mesh';
    else if (node instanceof BABYLON.Material) type = 'material';
    else if (node.getClassName && node.getClassName().includes('Camera')) type = 'camera';
    else if (node.getClassName && node.getClassName().includes('Light')) type = 'light';
    
    const extras = {
        name: node.name,
        uniqueId: node.uniqueId.toString(),
        type: type
    };
    
    if (node.metadata) {
        extras.metadata = node.metadata;
    }
    
    if (node.metadata && node.metadata.gltf && node.metadata.gltf.extras) {
        extras.extras = node.metadata.gltf.extras;
    }
    
    return extras;
}

