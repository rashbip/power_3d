/**
 * Texture Management Module
 */

function getTexturesList() {
    if (!window.scene) return [];
    
    return window.scene.textures.map(texture => {
        // Basic metadata
        const metadata = {
            uniqueId: texture.uniqueId.toString(),
            name: texture.name || "Unnamed Texture",
            className: texture.getClassName(),
            isRenderTargets: texture.isRenderTarget,
            level: texture.level,
            hasAlpha: texture.hasAlpha,
            uScale: texture.uScale || 1.0,
            vScale: texture.vScale || 1.0,
            uOffset: texture.uOffset || 0.0,
            vOffset: texture.vOffset || 0.0,
            coordinatesMode: texture.coordinatesMode
        };

        // If it's a file-based texture, we can get the URL
        if (texture.url) {
            metadata.url = texture.url;
        }

        return metadata;
    });
}

/**
 * Gets the base64 data of a texture for preview or export
 * @param {string} id - The uniqueId of the texture
 */
async function getTextureData(id) {
    if (!window.scene) return null;
    
    const numericId = parseInt(id);
    const texture = window.scene.textures.find(t => t.uniqueId === numericId);
    
    if (!texture) return null;

    try {
        // Create a canvas to read the pixels
        const size = texture.getSize();
        const width = size.width;
        const height = size.height;

        // Use InternalTexture to read pixels if possible
        const pixels = await texture.readPixels();
        if (!pixels) return null;

        const canvas = document.createElement('canvas');
        canvas.width = width;
        canvas.height = height;
        const ctx = canvas.getContext('2d');
        const imageData = ctx.createImageData(width, height);

        // Copy pixel data
        // Babylon uses RGBA, canvas uses RGBA
        imageData.data.set(new Uint8ClampedArray(pixels.buffer || pixels));
        ctx.putImageData(imageData, 0, 0);

        return canvas.toDataURL("image/png");
    } catch (e) {
        console.error("Failed to read texture pixels:", e);
        return null;
    }
}

/**
 * Updates a property of a texture
 * @param {string} id - The uniqueId of the texture
 * @param {object} properties - Key-value pairs of properties to update
 */
function updateTextureProperty(id, properties) {
    if (!window.scene) return;
    
    const numericId = parseInt(id);
    const texture = window.scene.textures.find(t => t.uniqueId === numericId);
    
    if (!texture) return;

    if (properties.level !== undefined) texture.level = properties.level;
    if (properties.uScale !== undefined) texture.uScale = properties.uScale;
    if (properties.vScale !== undefined) texture.vScale = properties.vScale;
    if (properties.uOffset !== undefined) texture.uOffset = properties.uOffset;
    if (properties.vOffset !== undefined) texture.vOffset = properties.vOffset;
}
