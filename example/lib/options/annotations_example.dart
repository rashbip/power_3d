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
  bool _isVisible = true;
  Power3DAnnotationStyle _currentStyle = Power3DAnnotationStyle.tooltip;

  // Updated with HTML descriptions
  final List<Map<String, dynamic>> _sampleAnnotations = [
    {
      "surface": {
        "meshName": "Object_4",
        "triangleIndex": 3521,
        "barycentric": [0.1252, 0.4601, 0.4145]
      },
      "placement": {
        "normal": [-0.2244, 0.3568, -0.9067],
        "offset": 0.01,
        "billboard": true,
      },
      "visibility": {
        "hideWhenOccluded": true,
      },
      "ui": {
        "title": "Left Ventricle",
        "description":
            "<div style='display:flex; align-items:flex-start; gap:8px;'> <img src='https://cdn-icons-png.flaticon.com/512/833/833472.png' style='width:28px; height:28px; margin-top:4px;' alt='heart icon'> <div> <p style='color:#333; line-height:1.6; margin:0 0 10px 0;'> The <b style='color:#c0392b;'>left ventricle</b> is the heart’s main pumping chamber. </p> <ul style='padding-left:20px; margin:0; color:#444;'> <li style='margin-bottom:6px;'>Thick muscular walls (8–12 mm)</li> <li style='margin-bottom:6px;'>High-pressure systemic circulation</li> </ul> </div> </div>",
        "more":
            "https://biologyinsights.com/what-is-the-left-ventricle-and-what-does-it-do/",
      },
      "camera": {
        "orbit": [4.458, 1.825, 2.815],
        "target": [0.0004, -0.0025, -0.0002],
        "transitionDuration": 0.5,
      },
      "id": 1772730643538,
      "isSelected": true,
    },
    {
      "surface": {
        "meshName": "Object_4",
        "triangleIndex": 3056,
        "barycentric": [0.1420, 0.8204, 0.0374],
      },
      "placement": {
        "normal": [-0.1324, -0.2485, -0.9595],
        "offset": 0.01,
      },
      "visibility": {
        "hideWhenOccluded": true,
      },
      "ui": {
        "title": "Aortic Region",
        "description":
            "Visualizing the region near the <span style='color:#38bdf8'>aortic root</span>. <br/><i>Demonstrates multi-point support.</i>",
        "more": "About aortic region",
      },
      "camera": {
        "orbit": [4.458, 1.825, 2.815],
        "target": [0.0004, -0.0025, -0.0002],
        "transitionDuration": 0.5
      },
      "id": 1772730678891,
      "isSelected": false,
    }
  ];

  @override
  void initState() {
    super.initState();
    _controller = Power3DController()..initForAnnotations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Heart Anatomy"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<Power3DAnnotationStyle>(
              value: _currentStyle,
              dropdownColor: Colors.black87,
              style: const TextStyle(color: Colors.white),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _currentStyle = val);
                  _controller.setAnnotationStyleEnum(val);
                }
              },
              items: Power3DAnnotationStyle.values.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text(s.name.toUpperCase()),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Power3D.fromAsset(
            "assets/heart.glb",
            controller: _controller,
            annotations: jsonEncode(_sampleAnnotations),
            annotationStyle: _currentStyle,
            onAnnotationMore: (id, data) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Learn More: ${data['ui']['title']}"),
                  content: Text(
                    "Annotation ID: $id\n\nFull Data Received:\n${jsonEncode(data)}",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CLOSE"),
                    ),
                  ],
                ),
              );
              debugPrint("Power3D Example: More clicked for $id. Data: $data");
            },
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
                  onPressed: () async {
                    // Dynamic focus: Get data for currently selected ID
                    // In a real app, you might track the selected ID in state.
                    // Here we manually check the first sample for demo.
                    const testId = "1772730643538";
                    final data = await _controller.getAnnotationData(testId);
                    debugPrint("Retrieved point data for focus: $data");

                    if (data != null && data['camera'] != null) {
                      final cam = data['camera'];
                      _controller.focusCamera(
                        orbit: (cam['orbit'] as List)
                            .cast<num>()
                            .map((e) => e.toDouble())
                            .toList(),
                        target: (cam['target'] as List)
                            .cast<num>()
                            .map((e) => e.toDouble())
                            .toList(),
                        duration: 1.0,
                      );
                    }
                  },
                  label: const Text("Focus Left Ventricle"),
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
