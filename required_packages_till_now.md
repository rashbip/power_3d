# Required Babylon.js Packages

This file tracks the Babylon.js components kept in the `assets/full` directory.

## Core Engine

- `babylon.js`: The main Babylon.js engine (7.8 MB).
- `babylon.ktx2Decoder.js`: KTX2 decoder.
- `babylon.ktx2Decoder.wasm`: KTX2 decoder WASM.

## Physics & Math

- `ammo.js`: Bullet physics engine (if needed).
- `cannon.js`: Cannon physics engine (if needed).
- `earcut.min.js`: Polygon triangulation.

## Loaders & Materials

- `loaders/`: Directory for glTF, OBJ, etc.
- `materialsLibrary/`: Various materials.

## Triaged (Deleted)

- All `.map` files (source maps).
- All `.d.ts` files (TypeScript definitions).
- `inspector/`, `nodeEditor/`, `guiEditor/`, etc.: Visual editors.
- Non-minified `.js` files where `.min.js` exists.
- Debug/Max versions of core libraries.

## Current Asset Size

- 30.58 MB (Down from >100 MB)
