import 'package:flutter/material.dart';
import 'package:power3d/power3d.dart';

class MaterialExample extends StatefulWidget {
  const MaterialExample({super.key});

  @override
  State<MaterialExample> createState() => _MaterialExampleState();
}

class _MaterialExampleState extends State<MaterialExample> {
  final String _assetPath = 'assets/heart.glb';
  late final Power3DController _controller;

  ShadingMode _shadingMode = ShadingMode.shaded;

  // Material Properties
  Color _baseColor = Colors.red;
  double _metallic = 0.5;
  double _roughness = 0.5;
  double _alpha = 1.0;
  late final Color _emissiveColor = Colors.black;
  bool _doubleSided = false;

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

  void _updateMaterial() {
    _controller.setGlobalMaterial(
      MaterialConfig(
        color: _baseColor,
        metallic: _metallic,
        roughness: _roughness,
        alpha: _alpha,
        emissiveColor: _emissiveColor,
        doubleSided: _doubleSided,
      ),
    );
  }

  void _updateShading(ShadingMode mode) {
    setState(() {
      _shadingMode = mode;
      _controller.setShadingMode(mode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Materials & Shaded'),
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
            flex: 2, // Adjusted to give more space to controls
            child: Power3D.fromAsset(_assetPath, controller: _controller),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ListView(
                children: [
                  const Text(
                    "Shading Mode",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ShadingMode.values.map((mode) {
                      return FilterChip(
                        label: Text(mode.name.toUpperCase()),
                        selected: _shadingMode == mode,
                        onSelected: (_) => _updateShading(mode),
                      );
                    }).toList(),
                  ),
                  const Divider(height: 32),
                  const Text(
                    "Material Properties",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),

                  SwitchListTile(
                    title: const Text("Double Sided"),
                    subtitle: const Text("Render both sides of polygons"),
                    value: _doubleSided,
                    onChanged: (v) {
                      setState(() {
                        _doubleSided = v;
                        _updateMaterial();
                      });
                    },
                  ),

                  _buildSlider("Metallic", _metallic, 0.0, 1.0, (v) {
                    setState(() {
                      _metallic = v;
                      _updateMaterial();
                    });
                  }),
                  _buildSlider("Roughness", _roughness, 0.0, 1.0, (v) {
                    setState(() {
                      _roughness = v;
                      _updateMaterial();
                    });
                  }),
                  _buildSlider("Alpha", _alpha, 0.0, 1.0, (v) {
                    setState(() {
                      _alpha = v;
                      _updateMaterial();
                    });
                  }),

                  const SizedBox(height: 16),
                  const Text("Base Color", style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children:
                        [
                              Colors.red,
                              Colors.blue,
                              Colors.green,
                              Colors.white,
                              Colors.amber,
                              Colors.black,
                            ]
                            .map(
                              (c) => _colorButton(c, (color) {
                                setState(() => _baseColor = color);
                                _updateMaterial();
                              }, _baseColor == c),
                            )
                            .toList(),
                  ),
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
            value.toStringAsFixed(2),
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
