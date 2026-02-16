import 'package:flutter/material.dart';
import 'package:power3d/power3d.dart';

class ErrorExample extends StatelessWidget {
  const ErrorExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Error')),
      body: Center(
        child: Power3D.fromNetwork(
          'https://invalid.url/model.glb',
          errorWidget: Container(
            color: Colors.red.withOpacity(0.1),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 60,
                    color: Colors.orange,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Something went wrong while loading the 3D model.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
