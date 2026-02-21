import 'package:flutter/material.dart';
import 'package:power3d/power3d.dart';

class AnnotationExample extends StatefulWidget {
  const AnnotationExample({super.key});

  @override
  State<AnnotationExample> createState() => _AnnotationExampleState();
}

class _AnnotationExampleState extends State<AnnotationExample> {
  late Power3DController _controller;
  AnnotationMode _mode = AnnotationMode.html;
  bool _showAnnotations = true;

  // Sample data mirroring the JSON provided by the user for the heart model
  final List<AnnotationData> _sampleAnnotations = [
    AnnotationData(
      id: "1771673201663",
      surface: const AnnotationSurface(
        meshName: "Object_4",
        triangleIndex: 856,
        barycentric: [
          0.01689829204707218,
          0.04094417098217577,
          0.942157536970752,
        ],
      ),
      placement: const AnnotationPlacement(
        normal: [-0.7693043774280661, -0.270632135228057, -0.578730526455896],
        offset: 0.01,
        billboard: true,
      ),
      visibility: const AnnotationVisibility(
        minDistance: 0.2,
        maxDistance: 20,
        hideWhenOccluded: true,
      ),
      ui: const AnnotationUI(
        title: "Demo1",
        description: "Anatomical detail of the heart.",
        more: "",
      ),
      camera: const AnnotationCamera(
        orbit: [10.645004955914972, 2.0945361250312, 2.3353881840117516],
        target: [
          0.0004044175148010254,
          -0.00259554386138916,
          -0.00025841593742370605,
        ],
        transitionDuration: 0.5,
      ),
    ),
    AnnotationData(
      id: "1771673225856",
      surface: const AnnotationSurface(
        meshName: "Object_4",
        triangleIndex: 5268,
        barycentric: [
          0.22122609269472598,
          0.5256418388382779,
          0.2531320684669962,
        ],
      ),
      placement: const AnnotationPlacement(
        normal: [0.9596783934248, -0.05853732773903036, -0.2749377428705778],
        offset: 0.01,
        billboard: true,
      ),
      visibility: const AnnotationVisibility(
        minDistance: 0.2,
        maxDistance: 20,
        hideWhenOccluded: true,
      ),
      ui: const AnnotationUI(
        title: "Demo2",
        description: "Description2",
        more: "",
      ),
      camera: const AnnotationCamera(
        orbit: [12.60893691116833, 1.721435082707354, 2.3353881840117516],
        target: [
          0.0004044175148010254,
          -0.00259554386138916,
          -0.00025841593742370605,
        ],
        transitionDuration: 0.5,
      ),
    ),
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
        title: const Text('Annotations Demo'),
        actions: [
          IconButton(
            icon: Icon(
              _showAnnotations ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () =>
                setState(() => _showAnnotations = !_showAnnotations),
            tooltip: 'Toggle Annotations',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Power3D(
              controller: _controller,
              initialModel: const Power3DData(
                path: 'assets/heart.glb',
                source: Power3DSource.asset,
              ),
              showAnnotations: _showAnnotations,
              annotations: _sampleAnnotations,
              annotationMode: _mode,
              // Custom HTML style (only used when mode == html)
              // Uses CSS classes defined in index.html – no inline styles needed.
              htmlAnnotationStyle: '''
                <div class="annotation-card-popup annotation-card-dark">
                  <div class="card-header">
                    <h4>{{title}}</h4>
                    <button class="close-btn" onclick="window._closeAnnotationCard()">&#x2715;</button>
                  </div>
                  <div class="card-content">
                    {{#description}}<p>{{description}}</p>{{/description}}
                    {{#more}}<a href="{{more}}" target="_blank" class="m3-button-text">Learn More &#x2192;</a>{{/more}}
                  </div>
                </div>
              ''',
              // Custom Dart builder (only used when mode == dart)
              dartAnnotationBuilder: (context, data) {
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Material(
                      elevation: 12,
                      borderRadius: BorderRadius.circular(24),
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.indigoAccent,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    data.ui.title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () =>
                                      _controller.clearActiveAnnotation(),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Text(
                              data.ui.description,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.center_focus_strong),
                                  label: const Text('Focus View'),
                                  onPressed: () =>
                                      _controller.focusAnnotation(data.id),
                                ),
                                if (data.ui.more.isNotEmpty)
                                  ElevatedButton(
                                    onPressed: () {}, // Handle URL
                                    child: const Text('Details'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Text('Display Mode:'),
          ChoiceChip(
            label: const Text('HTML (WebView)'),
            selected: _mode == AnnotationMode.html,
            onSelected: (s) => setState(() => _mode = AnnotationMode.html),
          ),
          ChoiceChip(
            label: const Text('Dart (Flutter)'),
            selected: _mode == AnnotationMode.dart,
            onSelected: (s) => setState(() => _mode = AnnotationMode.dart),
          ),
        ],
      ),
    );
  }
}
