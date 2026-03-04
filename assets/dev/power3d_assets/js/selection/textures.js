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
 * Requests texture data and sends it back via FlutterChannel
 * @param {string} id - The uniqueId of the texture
 */
async function requestTextureData(id) {
    const dataUrl = await getTextureData(id);
    if (window.FlutterChannel) {
        window.FlutterChannel.postMessage(JSON.stringify({
            type: 'textureData',
            uniqueId: id,
            data: dataUrl
        }));
    }
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
        const size = texture.getSize();
        const width = size.width;
        const height = size.height;

        if (width <= 0 || height <= 0) {
            console.warn(`Texture ${id} has invalid dimensions: ${width}x${height}`);
            return null;
        }

        const pixels = await texture.readPixels();
        if (!pixels) {
            console.warn(`Texture ${id} readPixels returned null`);
            return null;
        }

        const canvas = document.createElement('canvas');
        canvas.width = width;
        canvas.height = height;
        const ctx = canvas.getContext('2d');
        const imageData = ctx.createImageData(width, height);
        const data = imageData.data;
        const expectedLength = width * height * 4;
        
        // Paranoiac copy
        if (pixels instanceof Float32Array) {
            for (let i = 0; i < expectedLength; i++) {
                if (i < pixels.length) {
                    data[i] = Math.min(255, Math.max(0, pixels[i] * 255));
                }
            }
        } else {
            const len = Math.min(pixels.length, expectedLength);
            for (let i = 0; i < len; i++) {
                data[i] = pixels[i];
            }
        }

        ctx.putImageData(imageData, 0, 0);
        return canvas.toDataURL("image/png");
    } catch (e) {
        console.error(`Failed to read texture pixels for ${id}:`, e);
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
