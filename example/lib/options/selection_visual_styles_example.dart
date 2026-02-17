import 'package:flutter/material.dart';
import 'package:power3d/power3d.dart';

/// Example demonstrating visual styles and effects:
/// - Material modes (wireframe, xray, unlit)
/// - Bounding boxes
/// - Highlight layers
class SelectionVisualStylesExample extends StatefulWidget {
  const SelectionVisualStylesExample({super.key});

  @override
  State<SelectionVisualStylesExample> createState() =>
      _SelectionVisualStylesExampleState();
}

class _SelectionVisualStylesExampleState
    extends State<SelectionVisualStylesExample> {
  final String _assetPath = 'assets/shoulder.glb';
  late final Power3DController _controller;

  ShadingMode _selectedMaterialMode = ShadingMode.shaded;
  bool _showBoundingBox = false;
  bool _applyToSelected = true;

  @override
  void initState() {
    super.initState();
    _controller = Power3DController();

    _controller.updateSelectionConfig(
      const SelectionConfig(
        enabled: true,
        multipleSelection: true,
        selectionStyle: SelectionStyle(
          highlightColor: Colors.blueAccent,
          outlineColor: Colors.lightBlue,
          outlineWidth: 3.0,
        ),
      ),
    );

    _controller.onPartSelected((partIdentifier, selected) {
      if (_showBoundingBox) {
        if (selected) {
          _controller.showBoundingBox([partIdentifier]);
        } else {
          _controller.hideBoundingBox([partIdentifier]);
        }
      }
    });
  }

  void _updateMaterialMode(ShadingMode? mode) {
    if (mode == null) return;
    setState(() {
      _selectedMaterialMode = mode;
    });
    _controller.applyMaterialModeToSelection(
      mode,
      applyToSelected: _applyToSelected,
    );
  }

  void _toggleBoundingBox(bool value) {
    setState(() {
      _showBoundingBox = value;
    });

    final state = _controller.value;
    if (value) {
      _controller.showBoundingBox(state.selectedParts.toList());
    } else {
      _controller.hideBoundingBox(state.selectedParts.toList());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visual Styles & Effects'),
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
            flex: 2,
            child: Power3D.fromAsset(_assetPath, controller: _controller),
          ),
          Expanded(
            flex: 3,
            child: ValueListenableBuilder<Power3DState>(
              valueListenable: _controller,
              builder: (context, state, _) {
                return _buildPanel(state);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel(Power3DState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Material Modes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Apply to: '),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Selected')),
                  ButtonSegment(value: false, label: Text('Others')),
                ],
                selected: {_applyToSelected},
                onSelectionChanged: (v) {
                  setState(() => _applyToSelected = v.first);
                  _updateMaterialMode(_selectedMaterialMode);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ShadingMode.values
                .where(
                  (m) =>
                      m == ShadingMode.shaded ||
                      m == ShadingMode.wireframe ||
                      m == ShadingMode.xray ||
                      m == ShadingMode.unlit ||
                      m == ShadingMode.pointCloud,
                )
                .map((mode) {
                  return ChoiceChip(
                    label: Text(mode.name),
                    selected: _selectedMaterialMode == mode,
                    onSelected: (selected) {
                      if (selected) _updateMaterialMode(mode);
                    },
                  );
                })
                .toList(),
          ),
          const Divider(height: 32),
          const Text(
            'Visual Helpers',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SwitchListTile(
            title: const Text('Render Bounding Boxes'),
            subtitle: const Text('Show wireframe box around selection'),
            value: _showBoundingBox,
            onChanged: _toggleBoundingBox,
          ),
          const Divider(),
          const Text(
            'Quick Select (for testing)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: state.availableParts.length,
              itemBuilder: (context, index) {
                final part = state.availableParts[index];
                final isSelected = state.selectedParts.contains(part);
                return ListTile(
                  title: Text(part, style: const TextStyle(fontSize: 14)),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : null,
                  dense: true,
                  onTap: () {
                    if (isSelected) {
                      _controller.unselectPart(part);
                    } else {
                      _controller.selectPart(part);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
