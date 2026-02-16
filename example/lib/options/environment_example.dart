import 'package:flutter/material.dart';
import 'package:power3d/power3d.dart';

class EnvironmentExample extends StatefulWidget {
  const EnvironmentExample({super.key});

  @override
  State<EnvironmentExample> createState() => _EnvironmentExampleState();
}

class _EnvironmentExampleState extends State<EnvironmentExample> {
  final String _assetPath = 'assets/heart.glb';
  final String _bgAsset = 'assets/images/frieren_bg.jpeg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Environment Example')),
      body: Power3D.fromAsset(
        _assetPath,
        // Simple widget background
        environmentBuilder: (context, state) {
          return Image.asset(
            _bgAsset,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        },
      ),
    );
  }
}
