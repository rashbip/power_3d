import 'package:flutter/material.dart';
import 'package:power3d/power3d.dart';

class EnvironmentExample extends StatefulWidget {
  const EnvironmentExample({super.key});

  @override
  State<EnvironmentExample> createState() => _EnvironmentExampleState();
}

class _EnvironmentExampleState extends State<EnvironmentExample> {
  final String _assetPath = 'assets/heart.glb';
  final String _skyboxAsset = 'assets/images/frieren_bg.jpeg';
  late final Power3DController _controller;

  // Configuration state for toggles
  bool _syncRotation = true;
  bool _syncZoom = true;
  bool _syncVertical = true;
  bool _bgAutoRotate = false;
  bool _objAutoRotate = false;

  @override
  void initState() {
    super.initState();
    _controller = Power3DController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Environment Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset View',
            onPressed: () => _controller.resetView(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Power3D.fromAsset(
              _assetPath,
              controller: _controller,
              // Use Native Skybox (PhotoDome)
              skyboxPath: _skyboxAsset,
              skyboxSource: Power3DSource.asset,
              // Configure Background Sync
              environmentConfig: EnvironmentConfig(
                syncRotation: _syncRotation,
                syncVerticalRotation: _syncVertical,
                syncZoom: _syncZoom,
                autoRotate: _bgAutoRotate,
                autoRotationSpeed: 0.5,
              ),
              // Optional Layered Widget on top of Skybox
              environmentBuilder: (context, state) {
                return Center(
                  child: Image.asset(
                    'assets/images/frieren_bg.jpeg',
                    fit: BoxFit.cover,
                  ),
                );

                // return Center(
                //   child: Opacity(
                //     opacity: 0.3,
                //     child: Container(
                //       padding: const EdgeInsets.all(20),
                //       decoration: BoxDecoration(
                //         color: Colors.blueAccent.withOpacity(0.2),
                //         shape: BoxShape.circle,
                //       ),
                //       child: const Text(
                //         "Flutter Widget Layer",
                //         style: TextStyle(color: Colors.white, fontSize: 16),
                //       ),
                //     ),
                //   ),
                // );
              },
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    "Environment Config",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SwitchListTile(
                    title: const Text("Sync Rotation"),
                    subtitle: const Text("Background pans with camera"),
                    value: _syncRotation,
                    onChanged: (v) => setState(() => _syncRotation = v),
                  ),
                  SwitchListTile(
                    title: const Text("Sync Zoom"),
                    subtitle: const Text("Background scales with distance"),
                    value: _syncZoom,
                    onChanged: (v) => setState(() => _syncZoom = v),
                  ),
                  SwitchListTile(
                    title: const Text("Independent BG Rotation"),
                    subtitle: const Text("Background spins while obj steady"),
                    value: _bgAutoRotate,
                    onChanged: (v) => setState(() => _bgAutoRotate = v),
                  ),
                  const Divider(),
                  const Text(
                    "Object Controls",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SwitchListTile(
                    title: const Text("Object Auto Rotate"),
                    value: _objAutoRotate,
                    onChanged: (v) {
                      setState(() => _objAutoRotate = v);
                      _controller.updateRotation(enabled: v);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
