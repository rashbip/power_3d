import 'package:flutter/material.dart';
import 'package:power3d/power3d.dart';

class NetworkExample extends StatelessWidget {
  const NetworkExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network Example (Lazy)')),
      body: Center(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Model will only download when you click initialize.',
              ),
            ),
            Expanded(
              child: Power3D.fromNetwork(
                'https://models.babylonjs.com/Demos/shaderBall/BabylonShaderBall_Simple.gltf',
                lazy: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
