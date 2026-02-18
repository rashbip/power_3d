import 'package:flutter/material.dart';
import 'package:power3d/power3d.dart';

class NetworkExample extends StatefulWidget {
  const NetworkExample({super.key});

  @override
  State<NetworkExample> createState() => _NetworkExampleState();
}

class _NetworkExampleState extends State<NetworkExample> {
  final Power3DController _controller = Power3DController();
  bool _initialized = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network Example (Lazy)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'The viewer is set to "lazy: true", meaning it won\'t start until we manually trigger it.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                if (!_initialized)
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _initialized = true;
                      });
                      // Note: In lazy mode, the widget begins initialization
                      // when 'lazy' becomes false or when the widget is rebuilt with lazy: false.
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Initialize & Download Model'),
                  )
                else
                  const Text(
                    'Initializing...',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Power3D.fromNetwork(
              'https://models.babylonjs.com/Demos/shaderBall/BabylonShaderBall_Simple.gltf',
              controller: _controller,
              lazy: !_initialized,
              errorWidget: const Center(
                child: Text(
                  'Error loading model. Check your internet connection.',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
