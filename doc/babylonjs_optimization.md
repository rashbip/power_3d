# Babylon.js Asset Optimization

## Current Setup (CDN-Based)

The plugin now uses **CDN-hosted Babylon.js libraries** instead of bundling them locally. This reduces the plugin size significantly.

### What's Loaded:
- **Babylon.js Core**: ~1.5MB (from CDN)
- **Babylon.js Loaders**: ~400KB (from CDN)

**Total**: ~2MB loaded from CDN (no local storage needed!)

### Previous Setup (Local Assets):
- Local babylon.js file: **7.8MB** ❌

## Benefits of CDN Approach

1. **Reduced APK/IPA Size**: No 7.8MB babylon.js file bundled
2. **Browser Caching**: Users download once, cached across sessions
3. **Always Updated**: Get latest bug fixes and performance improvements
4. **Faster Development**: No need to manage large binary assets

## Optional: Local Hosting

If you need offline support or want to bundle Babylon.js locally, you can download the minified versions:

1. Download from: https://cdn.babylonjs.com/
   - `babylon.min.js` (~1.5MB)
   - `babylonjs.loaders.min.js` (~400KB)

2. Place in `assets/babylon/` folder

3. Update `index.html`:
```html
<script src="babylon/babylon.min.js"></script>
<script src="babylon/babylonjs.loaders.min.js"></script>
```

## Current index.html Configuration

```html
<!-- Babylon.js Core -->
<script src="https://cdn.babylonjs.com/babylon.js"></script>
<!-- Babylon.js Loaders (Required for GLTF/GLB/Draco) -->
<script src="https://cdn.babylonjs.com/loaders/babylonjs.loaders.min.js"></script>
```

This configuration:
- Loads from CDN (fast, cached)
- Supports all model formats (GLB, GLTF, Draco compression)
- No local storage impact
