import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:power3d/power3d.dart';

class AnnotationsExample extends StatefulWidget {
  const AnnotationsExample({super.key});

  @override
  State<AnnotationsExample> createState() => _AnnotationsExampleState();
}

class _AnnotationsExampleState extends State<AnnotationsExample> {
  late Power3DController _controller;
  bool _isVisible = true;

  // Exact JSON structure provided by the user
  final List<Map<String, dynamic>> _sampleAnnotations = [
    {
      "surface": {
        "meshName": "Object_4",
        "triangleIndex": 3521,
        "barycentric": [
          0.1252498687723287,
          0.46019301196035234,
          0.41455711926731886,
        ]
      },
      "placement": {
        "normal": [
          -0.22445354922545183,
          0.35689999506205955,
          -0.9067761563720121,
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
        "title": "Left Ventricle",
        "description":
            "The left ventricle is the heart’s main pumping chamber, responsible for delivering oxygenated blood to the entire body through high-pressure systemic circulation.\n\nAnatomy and Structure:\nThe left ventricle is located in the lower left portion of the heart, beneath the left atrium, and forms the apex of the heart. It is conical in shape, longer than the right ventricle, and has thick muscular walls (8–12 mm), which are necessary to generate the high pressure required to pump blood throughout the body. The left ventricle is separated from the right ventricle by the interventricular septum, which bulges slightly into the right ventricle.",
        "more":
            "https://biologyinsights.com/what-is-the-left-ventricle-and-what-does-it-do/",
      },
      "camera": {
        "orbit": [4.458062239127961, 1.8252585212556045, 2.8151857366272726],
        "target": [
          0.0004044175148010254,
          -0.00259554386138916,
          -0.00025841593742370605,
        ],
        "transitionDuration": 0.5,
      },
      "meta": {
        "version": 1,
        "createdAt": "2026-03-05T17:10:43.538Z",
        "updatedAt": "2026-03-05T17:10:43.538Z",
      },
      "id": 1772730643538,
      "isSelected": true,
    },
    {
      "surface": {
        "meshName": "Object_4",
        "triangleIndex": 3056,
        "barycentric": [
          0.14201931743314922,
          0.820490215036602,
          0.03749046753024869,
        ],
      },
      "placement": {
        "normal": [
          -0.1324288200233617,
          -0.2485560593826406,
          -0.9595220127602041,
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
        "title": "Aortic Region",
        "description":
            "Visualizing the region near the aortic root. This sample hotspot demonstrates multi-point annotation on the same mesh.",
        "more": "Just more info or link",
      },
      "camera": {
        "orbit": [4.458062239127961, 1.8252585212556045, 2.8151857366272726],
        "target": [
          0.0004044175148010254,
          -0.00259554386138916,
          -0.00025841593742370605,
        ],
        "transitionDuration": 0.5
      },
      "meta": {
        "version": 1,
        "createdAt": "2026-03-05T17:11:18.891Z",
        "updatedAt": "2026-03-05T17:11:18.891Z",
      },
      "id": 1772730678891,
      "isSelected": false,
    }
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
        title: const Text("Heart Anatomy"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Power3D.fromAsset(
            "assets/heart.glb",
            controller: _controller,
            annotations: jsonEncode(_sampleAnnotations),
            // annotationStyle: "tooltip", // Now optional, defaults to tooltip
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.center_focus_strong),
                  onPressed: () {
                    // Focus on a specific point (e.g. Aortic Region)
                    _controller.focusCamera(
                      orbit: [4.458, 1.825, 2.815],
                      target: [0.0004, -0.0025, -0.0002],
                      duration: 1.0,
                    );
                  },
                  label: const Text("Focus Point"),
                ),
                StatefulBuilder(
                  builder: (context, setState) {
                    return ElevatedButton.icon(
                      icon: Icon(
                        _isVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        _isVisible = !_isVisible;
                        setState(() {});
                        _controller.toggleAnnotations(_isVisible);
                      },
                      label: Text(
                        _isVisible ? "Hide Annotations" : "Show Annotations",
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
