import 'package:flutter/material.dart';
import 'package:power3d/power3d.dart';

class PlaceholderExample extends StatelessWidget {
  const PlaceholderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Loading UI')),
      body: Center(
        child: Power3D.fromNetwork(
          'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/MosquitoInAmber/glTF/MosquitoInAmber.gltf',
          loadingUi: (context, controller) {
            return Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.indigoAccent),
                    SizedBox(height: 24),
                    Text(
                      'PREPARING 3D VIEW',
                      style: TextStyle(
                        letterSpacing: 4,
                        fontWeight: FontWeight.w300,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
