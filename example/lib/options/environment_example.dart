import 'package:flutter/material.dart';
import 'package:power3d/power3d.dart';

class EnvironmentExample extends StatefulWidget {
  const EnvironmentExample({super.key});

  @override
  State<EnvironmentExample> createState() => _EnvironmentExampleState();
}

class _EnvironmentExampleState extends State<EnvironmentExample> {
  final String _assetPath = 'assets/heart.glb';
  late final Power3DController _controller;

  // Main Light Controls
  LightType _mainLightType = LightType.hemispheric;
  double _mainIntensity = 0.7;
  Color _mainColor = Colors.white;
  bool _mainCastShadows = false;

  // Fill Light Controls
  bool _enableFillLight = false;
  double _fillIntensity = 0.3;
  Color _fillColor = Colors.blueAccent;

  // Scene Processing
  double _exposure = 1.0;
  double _contrast = 1.0;

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

  List<LightingConfig> _buildLights() {
    final lights = <LightingConfig>[
      LightingConfig(
        type: _mainLightType,
        intensity: _mainIntensity,
        color: _mainColor,
        castShadows: _mainCastShadows,
      ),
    ];

    if (_enableFillLight) {
      lights.add(
        LightingConfig(
          type: LightType.point,
          intensity: _fillIntensity,
          color: _fillColor,
          castShadows: false,
        ),
      );
    }

    return lights;
  }

  void _updateLighting() {
    _controller.setLights(_buildLights());
  }

  void _updateSceneProcessing() {
    _controller.updateSceneProcessing(exposure: _exposure, contrast: _contrast);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Lighting'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.resetView(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Power3D.fromAsset(
              _assetPath,
              controller: _controller,
              lights: _buildLights(),
              exposure: _exposure,
              contrast: _contrast,
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ListView(
                children: [
                  const Text(
                    "Main Light",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),

                  // Light Type
                  SegmentedButton<LightType>(
                    segments: const [
                      ButtonSegment(
                        value: LightType.hemispheric,
                        label: Text("Hemi"),
                        icon: Icon(Icons.wb_sunny_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: LightType.directional,
                        label: Text("Dir"),
                        icon: Icon(Icons.light_mode, size: 16),
                      ),
                      ButtonSegment(
                        value: LightType.point,
                        label: Text("Point"),
                        icon: Icon(Icons.lightbulb_outline, size: 16),
                      ),
                    ],
                    selected: {_mainLightType},
                    onSelectionChanged: (Set<LightType> newSelection) {
                      setState(() {
                        _mainLightType = newSelection.first;
                        _updateLighting();
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Intensity
                  _buildSlider("Intensity", _mainIntensity, 0.0, 3.0, (v) {
                    setState(() {
                      _mainIntensity = v;
                      _updateLighting();
                    });
                  }),

                  // Color Presets
                  const SizedBox(height: 8),
                  const Text("Color", style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _colorButton(Colors.white, (c) {
                        setState(() {
                          _mainColor = c;
                          _updateLighting();
                        });
                      }, _mainColor == Colors.white),
                      _colorButton(Colors.amber, (c) {
                        setState(() {
                          _mainColor = c;
                          _updateLighting();
                        });
                      }, _mainColor == Colors.amber),
                      _colorButton(Colors.blueAccent, (c) {
                        setState(() {
                          _mainColor = c;
                          _updateLighting();
                        });
                      }, _mainColor == Colors.blueAccent),
                      _colorButton(Colors.redAccent, (c) {
                        setState(() {
                          _mainColor = c;
                          _updateLighting();
                        });
                      }, _mainColor == Colors.redAccent),
                    ],
                  ),

                  // Shadows
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text(
                      "Cast Shadows",
                      style: TextStyle(fontSize: 14),
                    ),
                    value: _mainCastShadows,
                    onChanged: _mainLightType == LightType.hemispheric
                        ? null
                        : (v) {
                            setState(() {
                              _mainCastShadows = v;
                              _updateLighting();
                            });
                          },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),

                  const Divider(height: 32),

                  // Fill Light
                  SwitchListTile(
                    title: const Text(
                      "Enable Fill Light",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    value: _enableFillLight,
                    onChanged: (v) {
                      setState(() {
                        _enableFillLight = v;
                        _updateLighting();
                      });
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),

                  if (_enableFillLight) ...[
                    const SizedBox(height: 8),
                    _buildSlider("Fill Intensity", _fillIntensity, 0.0, 2.0, (
                      v,
                    ) {
                      setState(() {
                        _fillIntensity = v;
                        _updateLighting();
                      });
                    }),
                  ],

                  const Divider(height: 32),

                  // Scene Processing
                  const Text(
                    "Scene Processing",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),

                  _buildSlider("Exposure", _exposure, 0.1, 3.0, (v) {
                    setState(() {
                      _exposure = v;
                      _updateSceneProcessing();
                    });
                  }),

                  _buildSlider("Contrast", _contrast, 0.5, 2.0, (v) {
                    setState(() {
                      _contrast = v;
                      _updateSceneProcessing();
                    });
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
        SizedBox(
          width: 40,
          child: Text(
            value.toStringAsFixed(1),
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _colorButton(Color color, ValueChanged<Color> onTap, bool isSelected) {
    return GestureDetector(
      onTap: () => onTap(color),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
