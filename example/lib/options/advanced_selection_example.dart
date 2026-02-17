import 'package:flutter/material.dart';
import 'package:power3d/power3d.dart';

/// Advanced selection example demonstrating all selection features:
/// - Hierarchical parts tree
/// - Visibility controls with eye icons
/// - Bounding box visualization
/// - Material modes for selected parts
/// - Node extras extraction
class AdvancedSelectionExample extends StatefulWidget {
  const AdvancedSelectionExample({super.key});

  @override
  State<AdvancedSelectionExample> createState() =>
      _AdvancedSelectionExampleState();
}

class _AdvancedSelectionExampleState extends State<AdvancedSelectionExample> {
  final String _assetPath = 'assets/shoulder.glb';
  late final Power3DController _controller;

  bool _selectionEnabled = true;
  bool _multipleSelection = true;
  bool _useCategorization = false;
  bool _showBoundingBoxes = false;
  ShadingMode _selectedMaterialMode = ShadingMode.shaded;

  List<dynamic>? _hierarchy;
  Map<String, dynamic>? _selectedExtras;

  @override
  void initState() {
    super.initState();
    _controller = Power3DController();

    // Configure selection
    _controller.updateSelectionConfig(
      SelectionConfig(
        enabled: _selectionEnabled,
        multipleSelection: _multipleSelection,
        scaleSelection: 1.15,
        selectionShift: const SelectionShift(y: 0.2),
        selectionStyle: SelectionStyle(
          highlightColor: Colors.blueAccent.withValues(alpha: 0.7),
          outlineColor: Colors.blue,
          outlineWidth: 2.5,
        ),
        unselectedStyle: SelectionStyle(
          highlightColor: Colors.grey.withValues(alpha: 0.2),
        ),
      ),
    );

    // Listen to selection events
    _controller.onPartSelected((partName, selected) {
      if (selected) {
        _loadNodeExtras(partName);
      }
    });

    // Listen to model load and fetch hierarchy
    _controller.addListener(() {
      if (_controller.value.status == Power3DStatus.loaded &&
          _hierarchy == null) {
        _loadHierarchy();
      }
    });
  }

  Future<void> _loadHierarchy() async {
    final hierarchy = await _controller.getPartsHierarchy(
      useCategorization: _useCategorization,
    );
    setState(() {
      _hierarchy = hierarchy;
    });
  }

  Future<void> _loadNodeExtras(String partName) async {
    final extras = await _controller.getNodeExtras(partName);
    setState(() {
      _selectedExtras = extras;
    });
  }

  void _toggleHierarchyMode() {
    setState(() {
      _useCategorization = !_useCategorization;
      _hierarchy = null;
    });
    _loadHierarchy();
  }

  void _toggleBoundingBoxes() {
    setState(() {
      _showBoundingBoxes = !_showBoundingBoxes;
    });

    if (_showBoundingBoxes && _controller.value.selectedParts.isNotEmpty) {
      _controller.showBoundingBox(
        _controller.value.selectedParts,
        config: const BoundingBoxConfig(
          color: Colors.greenAccent,
          lineWidth: 2.0,
        ),
      );
    } else {
      _controller.hideBoundingBox(_controller.value.boundingBoxParts);
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
        title: const Text('Advanced Selection'),
        actions: [
          IconButton(
            icon: Icon(
              _selectionEnabled ? Icons.touch_app : Icons.touch_app_outlined,
            ),
            onPressed: () {
              setState(() {
                _selectionEnabled = !_selectionEnabled;
                _controller.updateSelectionConfig(
                  _controller.value.selectionConfig.copyWith(
                    enabled: _selectionEnabled,
                  ),
                );
              });
            },
            tooltip: 'Toggle Selection',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.resetView(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 3D Viewer
          Expanded(
            flex: 2,
            child: Power3D.fromAsset(_assetPath, controller: _controller),
          ),
          // Control Panel
          Expanded(
            flex: 3,
            child: ValueListenableBuilder<Power3DState>(
              valueListenable: _controller,
              builder: (context, state, _) {
                return _buildControlPanel(state);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(Power3DState state) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            TabBar(
              tabs: const [
                Tab(icon: Icon(Icons.account_tree), text: 'Hierarchy'),
                Tab(icon: Icon(Icons.visibility), text: 'Visibility'),
                Tab(icon: Icon(Icons.info_outline), text: 'Extras'),
                Tab(icon: Icon(Icons.texture), text: 'Material'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildHierarchyTab(state),
                  _buildVisibilityTab(state),
                  _buildExtrasTab(state),
                  _buildMaterialTab(state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHierarchyTab(Power3DState state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hierarchy Mode',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Scene Graph')),
                ButtonSegment(value: true, label: Text('Categorized')),
              ],
              selected: {_useCategorization},
              onSelectionChanged: (Set<bool> selected) {
                _toggleHierarchyMode();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Multiple Selection'),
          value: _multipleSelection,
          onChanged: _selectionEnabled
              ? (v) {
                  setState(() {
                    _multipleSelection = v;
                    _controller.updateSelectionConfig(
                      _controller.value.selectionConfig.copyWith(
                        multipleSelection: v,
                      ),
                    );
                  });
                }
              : null,
        ),
        const Divider(),
        if (_hierarchy != null)
          ..._hierarchy!.map(
            (node) => _buildHierarchyNode(node as Map<String, dynamic>, state),
          )
        else if (state.availableParts.isNotEmpty)
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
          )
        else
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Loading hierarchy...',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHierarchyNode(
    Map<String, dynamic> node,
    Power3DState state, {
    int level = 0,
  }) {
    final String name = node['name'] ?? 'unknown';
    final String displayName = node['displayName'] ?? name;
    final List children = node['children'] ?? [];
    final String type = node['type'] ?? 'unknown';
    final String? uniqueId = node['uniqueId']?.toString();
    final String selectionId = uniqueId ?? name;

    if (type == 'mesh') {
      final isSelected = state.selectedParts.contains(selectionId);
      return Padding(
        padding: EdgeInsets.only(left: 16.0 + (level * 16.0)),
        child: InkWell(
          onTap: _selectionEnabled
              ? () {
                  if (isSelected) {
                    _controller.unselectPart(selectionId);
                  } else {
                    _controller.selectPart(selectionId);
                  }
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Icon(
                  Icons.view_in_ar,
                  size: 18,
                  color: isSelected ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      color: isSelected ? Colors.blue : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, size: 16, color: Colors.blue),
              ],
            ),
          ),
        ),
      );
    }

    // Node or Category
    return ExpansionTile(
      leading: Icon(
        type == 'category'
            ? Icons.folder
            : (type == 'node' ? Icons.adjust : Icons.account_tree),
        size: 20,
        color: type == 'node' ? Colors.orangeAccent : null,
      ),
      title: Text(
        displayName,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
      initiallyExpanded: level == 0,
      children: children
          .map(
            (child) => _buildHierarchyNode(
              child as Map<String, dynamic>,
              state,
              level: level + 1,
            ),
          )
          .toList(),
      onExpansionChanged: (expanded) {
        if (expanded && type == 'node') {
          // You could optionally select a group or load extras here
          _loadNodeExtras(selectionId);
        }
      },
    );
}

  Widget _buildVisibilityTab(Power3DState state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: state.selectedParts.isEmpty
                    ? null
                    : () => _controller.hideSelected(),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.visibility_off, size: 18),
                    SizedBox(width: 4),
                    Text('Hide Selected'),
                  ],
                ),
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
        FilledButton(
          onPressed: state.hiddenParts.isEmpty
              ? null
              : () => _controller.unhideAll(),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.visibility, size: 18),
              SizedBox(width: 8),
              Text('Show All'),
            ],
          ),
        ),
        const Divider(),
        const Text(
          'Individual Parts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...state.availableParts.map((part) {
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
            title: Text(part),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: Colors.blue)
                : null,
            onTap: _selectionEnabled
                ? () {
                    if (isSelected) {
                      _controller.unselectPart(part);
                    } else {
                      _controller.selectPart(part);
                    }
                  }
                : null,
          );
        }),
      ],
    );
  }

  Widget _buildExtrasTab(Power3DState state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.selectedParts.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Select a part to view its extras data',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else ...[
          Text(
            'Selected: ${state.selectedParts.length} part(s)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_selectedExtras != null && _selectedExtras!.isNotEmpty) ...[
            const Text(
              'Node Extras:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _formatJson(_selectedExtras!),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ] else
            const Text(
              'No extras data available for this part.',
              style: TextStyle(color: Colors.grey),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: state.selectedParts.isNotEmpty
                ? () => _loadNodeExtras(state.selectedParts.first)
                : null,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh, size: 18),
                SizedBox(width: 8),
                Text('Reload Extras'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMaterialTab(Power3DState state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Checkbox(
              value: _showBoundingBoxes,
              onChanged: state.selectedParts.isEmpty
                  ? null
                  : (v) {
                      _toggleBoundingBoxes();
                    },
            ),
            const Text('Show Bounding Boxes'),
          ],
        ),
        const Divider(),
        const Text(
          'Apply Material Mode to:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButton<ShadingMode>(
          value: _selectedMaterialMode,
          isExpanded: true,
          items: ShadingMode.values.map((mode) {
            return DropdownMenuItem(value: mode, child: Text(mode.name));
          }).toList(),
          onChanged: (mode) {
            if (mode != null) {
              setState(() {
                _selectedMaterialMode = mode;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: state.selectedParts.isEmpty
                    ? null
                    : () {
                        _controller.applyMaterialModeToSelection(
                          _selectedMaterialMode,
                          applyToSelected: true,
                        );
                      },
                child: const Text('To Selected'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonal(
                onPressed: state.selectedParts.isEmpty
                    ? null
                    : () {
                        _controller.applyMaterialModeToSelection(
                          _selectedMaterialMode,
                          applyToSelected: false,
                        );
                      },
                child: const Text('To Unselected'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => _controller.setShadingMode(ShadingMode.shaded),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.refresh, size: 18),
              SizedBox(width: 8),
              Text('Reset All Materials'),
            ],
          ),
        ),
      ],
    );
  }

  String _formatJson(Map<String, dynamic> json) {
    final buffer = StringBuffer();
    _formatJsonRecursive(json, buffer, 0);
    return buffer.toString();
  }

  void _formatJsonRecursive(dynamic value, StringBuffer buffer, int indent) {
    final indentStr = '  ' * indent;

    if (value is Map) {
      buffer.writeln('{');
      final entries = value.entries.toList();
      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        buffer.write('$indentStr  "${entry.key}": ');
        _formatJsonRecursive(entry.value, buffer, indent + 1);
        if (i < entries.length - 1) buffer.write(',');
        buffer.writeln();
      }
      buffer.write('$indentStr}');
    } else if (value is List) {
      buffer.writeln('[');
      for (var i = 0; i < value.length; i++) {
        buffer.write('$indentStr  ');
        _formatJsonRecursive(value[i], buffer, indent + 1);
        if (i < value.length - 1) buffer.write(',');
        buffer.writeln();
      }
      buffer.write('$indentStr]');
    } else if (value is String) {
      buffer.write('"$value"');
    } else {
      buffer.write(value.toString());
    }
  }
}
