import 'package:flutter/material.dart';
import 'package:power3d/power3d.dart';

class SelectionExample extends StatefulWidget {
  const SelectionExample({super.key});

  @override
  State<SelectionExample> createState() => _SelectionExampleState();
}

class _SelectionExampleState extends State<SelectionExample> {
  final String _assetPath = 'assets/shoulder.glb';
  late final Power3DController _controller;

  bool _selectionEnabled = false;
  bool _multipleSelection = false;
  double _scale = 1.0;
  SelectionShift _shift = const SelectionShift();

  @override
  void initState() {
    super.initState();
    _controller = Power3DController();
    
    _controller.onPartSelected((partName, selected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selected ? "Selected" : "Deselected"}: $partName'),
          duration: const Duration(seconds: 1),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleSelection() {
    setState(() {
      _selectionEnabled = !_selectionEnabled;
      _updateSelectionConfig();
    });
  }

  void _updateSelectionConfig() {
    _controller.updateSelectionConfig(SelectionConfig(
      enabled: _selectionEnabled,
      multipleSelection: _multipleSelection,
      scaleSelection: _scale,
      selectionShift: _shift,
      selectionStyle: SelectionStyle(
        highlightColor: Colors.greenAccent.withOpacity(0.6),
        outlineColor: Colors.green,
        outlineWidth: 2.0,
      ),
      unselectedStyle: SelectionStyle(
        highlightColor: Colors.grey.withOpacity(0.3),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Object Parts & Selection'),
        actions: [
          IconButton(
            icon: Icon(_selectionEnabled ? Icons.touch_app : Icons.touch_app_outlined),
            onPressed: _toggleSelection,
            tooltip: _selectionEnabled ? 'Disable Selection' : 'Enable Selection',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.resetView(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Power3D.fromAsset(
              _assetPath,
              controller: _controller,
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ValueListenableBuilder<Power3DState>(
                valueListenable: _controller,
                builder: (context, state, _) {
                  return ListView(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Selection Controls",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          FilledButton.icon(
                            onPressed: state.selectedParts.isEmpty
                                ? null
                                : () => _controller.clearSelection(),
                            icon: const Icon(Icons.clear_all, size: 18),
                            label: const Text('Clear'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text("Multiple Selection"),
                        subtitle: const Text("Allow selecting multiple parts"),
                        value: _multipleSelection,
                        onChanged: _selectionEnabled
                            ? (v) {
                                setState(() {
                                  _multipleSelection = v;
                                  _updateSelectionConfig();
                                });
                              }
                            : null,
                      ),
                      const Divider(),
                      const Text(
                        "Available Parts",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      if (state.availableParts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No parts detected. Load a model with multiple meshes.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: state.availableParts.map((part) {
                            final isSelected = state.selectedParts.contains(part);
                            return FilterChip(
                              label: Text(part),
                              selected: isSelected,
                              onSelected: _selectionEnabled
                                  ? (_) {
                                      if (isSelected) {
                                        _controller.unselectPart(part);
                                      } else {
                                        _controller.selectPart(part);
                                      }
                                    }
                                  : null,
                            );
                          }).toList(),
                        ),
                      const Divider(),
                      const Text(
                        "Transform Selected",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      _buildSlider("Scale", _scale, 0.5, 2.0, (v) {
                        setState(() {
                          _scale = v;
                          _updateSelectionConfig();
                        });
                      }),
                      _buildSlider("Shift X", _shift.x, -2.0, 2.0, (v) {
                        setState(() {
                          _shift = _shift.copyWith(x: v);
                          _updateSelectionConfig();
                        });
                      }),
                      _buildSlider("Shift Y", _shift.y, -2.0, 2.0, (v) {
                        setState(() {
                          _shift = _shift.copyWith(y: v);
                          _updateSelectionConfig();
                        });
                      }),
                      _buildSlider("Shift Z", _shift.z, -2.0, 2.0, (v) {
                        setState(() {
                          _shift = _shift.copyWith(z: v);
                          _updateSelectionConfig();
                        });
                      }),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12))),
        Expanded(child: Slider(value: value, min: min, max: max, onChanged: onChanged)),
        SizedBox(
          width: 50,
          child: Text(value.toStringAsFixed(2), style: const TextStyle(fontSize: 12), textAlign: TextAlign.right),
        ),
      ],
    );
  }
}
