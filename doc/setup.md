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
If loading non-HTTPS models or using local assets from the plugin, add the following to your `Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

## macOS

### 1. App Sandbox Entitlements
Ensure your `macos/Runner/*.entitlements` files (both Debug and Release) include:

```xml
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.network.server</key>
<true/>
```

## Web

Power3D works seamlessly on Web out of the box. However, ensure that:
- Your textures and models are served with proper **CORS headers** if hosted on external domains.
- If using local files or assets, they must be registered in `pubspec.yaml` (handled automatically by the plugin).

## Desktop (Windows & Linux)

### Windows
- Power3D requires the **WebView2 Runtime** to be installed. It is included by default in Windows 10 (version 1803+) and Windows 11.
- During development, ensure your environment supports the `flutter_inappwebview` Windows implementation requirements.

### Linux
- Ensure you have `libwebkit2gtk` installed on your system. For development on Ubuntu:
  ```bash
  sudo apt-get install libwebkit2gtk-4.1-dev
  ```

## Troubleshooting

- **Models not loading**: Check the browser/system console. Verify the URL points directly to a supported 3D file (.glb, .gltf, .obj, .stl).
- **Cleartext error**: Re-check the Android/iOS settings above.
- **Black screen on Linux**: Verify that WebKit2GTK is correctly installed and accessible.
