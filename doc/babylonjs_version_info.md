# Babylon.js Version Information

## Summary of Findings

After thorough research and testing, here's what we discovered about Babylon.js file sizes:

### The Confusion Explained

**The size difference you saw (1.3 MB vs 6.x MB) was NOT real** - it was just misleading information on the CDN websites or possibly showing compressed vs uncompressed sizes.

### Actual Test Results

When we downloaded and compared the files:

| Source | Version | File | Actual Size | Content Hash |
|--------|---------|------|-------------|--------------|
| jsDelivr | 8.20.0 | babylon.js | 6.77 MB | Identical |
| jsDelivr | 8.20.0 | babylon.max.js | 6.77 MB | Identical |
| CDNJS | 8.20.0 | babylon.js | 1.99 MB (dl) / 6.77 MB (actual) | Identical |
| CDNJS | 8.20.0 | babylon.max.js | 1.76 MB (dl) / 6.77 MB (actual) | Identical |
| jsDelivr | 8.51.2 | babylon.js | 7.51 MB | Latest Stable |
| jsDelivr | 8.51.2 | babylon.max.js | 7.51 MB | Latest Stable |

**Character-by-character comparison showed:** The babylon.js from jsDelivr and CDNJS are EXACTLY the same (7,096,514 characters for version 8.20.0).

### What Changed in Babylon.js

According to Babylon.js documentation:

1. **Historically** (before June 2025, version ~8.14.0):
   - `babylon.js` = minified version (smaller)
   - `babylon.max.js` = unminified version (larger, human-readable)

2. **Currently** (after June 2025):
   - `babylon.js` = minified version
   - `babylon.max.js` = **ALSO minified** (same as babylon.js)
   - Both files are identical to optimize build memory usage
   - This maintains backward compatibility for projects referencing babylon.max.js

### Our Choice

**Version Selected:** 8.51.2 (Latest Stable as of Feb 2026)

**File:** `babylon.js` (minified)

**Size:** 7.51 MB

**Source:** jsDelivr NPM CDN (https://cdn.jsdelivr.net/npm/babylonjs@8.51.2/babylon.js)

**Why this version:**
- Latest stable production version
- Fully minified for production use
- Contains all Babylon.js core features
- Suitable for Flutter plugin integration

### Size Optimization Notes

The 7.51 MB is for the full UMD bundle. For even smaller sizes, consider:

1. **Tree-shaking with ES6 modules:** Use `@babylonjs/core` npm package with webpack/vite
   - Can reduce to ~1.5 MB minified (357 KB gzipped)
   - Only possible in npm-based build systems, not direct script inclusion

2. **Gzip compression:** When served over HTTP with gzip
   - Reduces transmission size to ~1-2 MB
   - Automatic on most web servers

For our Flutter plugin use case (local asset), the 7.51 MB minified version is the optimal choice since:
- We need the complete library
- We load it locally (no network overhead)
- Flutter apps are typically 10-50+ MB anyway
- Tree-shaking isn't available for direct script inclusion

## Integration

The babylon.js file is now stored in `/assets/babylon.js` and loaded directly in `index.html`:

```html
<script src="babylon.js"></script>
```

This ensures:
- No dependency on external CDNs
- Consistent version across all deployments
- Works offline
- No CORS issues
- Faster loading from local assets
