import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:power3d/power3d.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AssetExample extends StatefulWidget {
  const AssetExample({super.key});

  @override
  State<AssetExample> createState() => _AssetExampleState();
}

class _AssetExampleState extends State<AssetExample> {
  final String _assetPath = 'assets/heart.glb';
  late final Power3DController _controller;

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

  Future<void> _handleScreenshot() async {
    final dir = await getTemporaryDirectory();
    final path = p.join(
      dir.path,
      'screenshot_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await _controller.takeScreenshot(path);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Screenshot saved to: $path')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: ValueListenableBuilder<Power3DState>(
        valueListenable: _controller,
        builder: (context, state, child) {
          return Stack(
            children: [
              Center(
                child: Power3D.fromAsset(_assetPath, controller: _controller),
              ),
              if (state.lastScreenshot != null)
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [BoxShadow(blurRadius: 4)],
                    ),
                    child: Image.memory(
                      base64Decode(state.lastScreenshot!.split(',')[1]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: ValueListenableBuilder<Power3DState>(
        valueListenable: _controller,
        builder: (context, state, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'screenshot',
                onPressed: _handleScreenshot,
                child: const Icon(Icons.camera_alt),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'reset',
                onPressed: () => _controller.resetView(),
                child: const Icon(Icons.refresh),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'rotate',
                backgroundColor: state.autoRotate ? Colors.indigoAccent : null,
                onPressed: () => _controller.updateRotation(
                  enabled: !state.autoRotate,
                  speed: 2.0,
                  stopAfter: const Duration(seconds: 3),
                ),
                child: const Icon(Icons.rotate_right),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ValueListenableBuilder<Power3DState>(
          valueListenable: _controller,
          builder: (context, state, child) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Lock Position (Panning)'),
                    value: state.isPositionLocked,
                    onChanged: (val) => _controller.setLockPosition(val),
                  ),
                  SwitchListTile(
                    title: const Text('Enable Zoom'),
                    value: state.enableZoom,
                    onChanged: (val) => _controller.updateZoom(enabled: val),
                  ),
                  ListTile(
                    title: const Text('Rotation Speed'),
                    subtitle: Slider(
                      value: state.rotationSpeed,
                      min: 0.1,
                      max: 5.0,
                      onChanged: (val) =>
                          _controller.updateRotation(speed: val),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
