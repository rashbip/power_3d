/**
 * Get hierarchical structure of parts based on scene graph or optional categorization
 * @param {boolean} useCategorization - If true, use naming convention (e.g. "Category.PartName")
 * @returns {Array} Hierarchical tree structure
 */
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
    
    // To match Babylon.js Sandbox/Inspector, we show all root nodes
    const rootNodes = window.scene.rootNodes;
    
    const processedNodes = new Set();
    const children = [];
    
    rootNodes.forEach(node => {
        const hierarchyNode = buildNodeHierarchy(node, processedNodes);
        if (hierarchyNode) children.push(hierarchyNode);
    });
    
    return children;
}

function buildNodeHierarchy(node, processedNodes) {
    if (!node || processedNodes.has(node.uniqueId)) return null;
    processedNodes.add(node.uniqueId);
    
    const type = node instanceof BABYLON.Mesh || node instanceof BABYLON.InstancedMesh ? 'mesh' : 'node';
    
    const hierarchyNode = {
        name: node.name || `Node ${node.uniqueId}`,
        uniqueId: node.uniqueId.toString(),
        type: type,
        children: []
    };
    
    // Get all children (TransformNodes, Meshes, etc.)
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
        
        // Check if name contains a category separator (. or _)
        const parts = mesh.name.split(/[._]/);
        
        if (parts.length > 1) {
            const category = parts[0];
            const partName = parts.slice(1).join('.');
            
            if (!categories[category]) {
                categories[category] = {
                    name: category,
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
            // No category detected
            unCategorizedNodes.push({
                name: mesh.name,
                uniqueId: mesh.uniqueId.toString(),
                type: 'mesh',
                children: []
            });
        }
    });
    
    const result = [];
    // Add categories
    Object.values(categories).forEach(cat => result.push(cat));
    // Add uncategorized nodes
    unCategorizedNodes.forEach(node => result.push(node));
    
    return result;
}

/**
 * Get extras data from a node (label, description, category, colorHighlight, etc.)
 */
function getNodeExtras(nodeIdentifier) {
    if (!window.scene) return {};
    
    // Try to find by name or uniqueId
    let node = window.scene.getNodeByName(nodeIdentifier);
    if (!node) {
        const id = parseInt(nodeIdentifier);
        if (!isNaN(id)) {
            node = window.scene.getNodeByUniqueId(id);
        }
    }
    
    if (!node) return {};
    
    const extras = {
        name: node.name,
        id: node.id,
        uniqueId: node.uniqueId.toString(),
        type: node instanceof BABYLON.Mesh || node instanceof BABYLON.InstancedMesh ? 'mesh' : 'node'
    };
    
    // Check for metadata
    if (node.metadata) {
        extras.metadata = node.metadata;
    }
    
    // Check for GLTF extras
    if (node.metadata && node.metadata.gltf && node.metadata.gltf.extras) {
        extras.extras = node.metadata.gltf.extras;
    }
    
    return extras;
}

