# Setup & Permissions

To use Power3D, you may need to configure platform-specific settings, especially when loading models from the network.

## Android

### 1. Internet Permission
Ensure your `app/src/main/AndroidManifest.xml` includes:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### 2. Cleartext Traffic (HTTP)
If you are loading models from non-HTTPS URLs or a local development server, you must allow cleartext traffic.

**Option A: Global (Development only)**
In `AndroidManifest.xml`, add `android:usesCleartextTraffic="true"` to the `<application>` tag:
```xml
<application
    ...
    android:usesCleartextTraffic="true">
```

**Option B: Recommended (Network Security Config)**
Create `res/xml/network_security_config.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true" />
</network-security-config>
```

Then reference it in `AndroidManifest.xml`:
```xml
<application
    ...
    android:networkSecurityConfig="@xml/network_security_config">
```

## iOS

### 1. App Transport Security
If loading non-HTTPS models, add the following to your `Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## Troubleshooting

- **Models not loading**: Check the browser console if you are using a proxy or ensure the URL points directly to a supported 3D file (.glb, .gltf, .obj, .stl).
- **Cleartext error**: Re-check the Android settings above. Android 9+ blocks HTTP by default.
