import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:power3d/power3d.dart';
import 'package:power3d_annotations/power3d_annotations.dart';

class AnnotationsExample extends StatefulWidget {
  const AnnotationsExample({super.key});

  @override
  State<AnnotationsExample> createState() => _AnnotationsExampleState();
}

class _AnnotationsExampleState extends State<AnnotationsExample> {
  late Power3DController _controller;

  final List<Map<String, dynamic>> _sampleAnnotations = [
    {
      "surface": {
        "meshName": "Cervical vertebrae (C5)",
        "triangleIndex": 1834,
        "barycentric": [
          0.7429233280878619,
          0.12119115004014532,
          0.1358855218719927,
        ],
      },
      "placement": {
        "normal": [
          0.5508035109519491,
          0.35219299529181236,
          -0.7566872447652251,
        ],
        "offset": 0.01,
        "billboard": true,
      },
      "visibility": {
        "minDistance": 0.2,
        "maxDistance": 20,
        "hideWhenOccluded": true,
      },
      "ui": {
        "title": "Vertebrata 1",
        "description":
            "The L1 vertebra is the first vertebra in the lumbar spine, located beneath the T12 vertebra. It is the smallest and most superior of the lumbar vertebrae, bearing the weight of the upper body and acting as a transition between the thoracic and lumbar vertebrae. The L1 vertebra has a large, roughly cylindrical body, which makes up most of its mass, and supports the entire weight of the tissues of the upper body.",
        "more": "https://en.wikipedia.org/wiki/Thoracic_spinal_nerve_1",
      },
      "camera": {
        "orbit": [-1.5707963267948966, 1.0471975511965976, 0.371608743104348],
        "target": [
          0.11866259574890137,
          1.3473149538040161,
          0.0006333440542221069,
        ],
        "transitionDuration": 0.5,
      },
      "meta": {
        "version": 1,
        "createdAt": "2026-03-04T12:01:45.349Z",
        "updatedAt": "2026-03-04T12:01:45.349Z",
      },
      "id": 1772625705349,
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = Power3DController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Annotations Example"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Power3D.fromAsset(
            "assets/shoulder.glb",
            controller: _controller,
            annotations: jsonEncode(_sampleAnnotations),
            annotationStyle: Power3DAnnotationStyles.tooltip,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _controller.setAnnotations(jsonEncode(_sampleAnnotations));
                  },
                  child: const Text("Reset Annotations"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _controller.setAnnotations(jsonEncode([]));
                  },
                  child: const Text("Clear All"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
