import 'package:flutter/material.dart';
import 'package:power3d/power3d.dart';

/// Example demonstrating visibility controls:
/// - Hide Selected parts
/// - Hide Unselected parts
/// - Show All (Unhide)
/// - Individual visibility toggles
class SelectionVisibilityExample extends StatefulWidget {
  const SelectionVisibilityExample({super.key});

  @override
  State<SelectionVisibilityExample> createState() =>
      _SelectionVisibilityExampleState();
}

class _SelectionVisibilityExampleState extends State<SelectionVisibilityExample> {
  final String _assetPath = 'assets/shoulder.glb';
  late final Power3DController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Power3DController();

    // Enable selection for context
    _controller.updateSelectionConfig(
      const SelectionConfig(
        enabled: true,
        multipleSelection: true,
        selectionStyle: SelectionStyle(
          outlineColor: Colors.orange,
          outlineWidth: 2.0,
        ),
      ),
    );
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
        title: const Text('Visibility Controls'),
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
            'Batch Actions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: state.selectedParts.isEmpty
                      ? null
                      : () => _controller.hideSelected(),
                  icon: const Icon(Icons.visibility_off, size: 18),
                  label: const Text('Hide Selected'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: state.selectedParts.isEmpty
                      ? null
                      : () => _controller.hideUnselected(),
                  child: const Text('Hide Others'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  state.hiddenParts.isEmpty ? null : () => _controller.unhideAll(),
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text('Show All Parts'),
            ),
          ),
          const Divider(height: 32),
          const Text(
            'Individual Visibility',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: state.availableParts.length,
              itemBuilder: (context, index) {
                final part = state.availableParts[index];
                final isHidden = state.hiddenParts.contains(part);
                final isSelected = state.selectedParts.contains(part);

                return ListTile(
                  leading: IconButton(
                    icon: Icon(isHidden ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      if (isHidden) {
                        _controller.showParts([part]);
                      } else {
                        _controller.hideParts([part]);
                      }
                    },
                  ),
                  title: Text(part, style: TextStyle(
                    decoration: isHidden ? TextDecoration.lineThrough : null,
                    color: isHidden ? Colors.grey : null,
                  )),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
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
