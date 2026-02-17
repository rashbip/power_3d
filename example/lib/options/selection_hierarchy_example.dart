import 'package:flutter/material.dart';
import 'package:power3d/power3d.dart';

/// Example demonstrating hierarchical part selection:
/// - Full Scene Graph traversal
/// - Categorized view (naming convention based)
/// - Node-based selection (by UniqueId)
class SelectionHierarchyExample extends StatefulWidget {
  const SelectionHierarchyExample({super.key});

  @override
  State<SelectionHierarchyExample> createState() =>
      _SelectionHierarchyExampleState();
}

class _SelectionHierarchyExampleState extends State<SelectionHierarchyExample> {
  final String _assetPath = 'assets/shoulder.glb';
  late final Power3DController _controller;

  bool _useCategorization = false;
  List<dynamic>? _hierarchy;

  @override
  void initState() {
    super.initState();
    _controller = Power3DController();

    // Configure selection
    _controller.updateSelectionConfig(
      const SelectionConfig(
        enabled: true,
        multipleSelection: true,
        selectionStyle: SelectionStyle(
          outlineColor: Colors.blue,
          outlineWidth: 2.5,
        ),
      ),
    );

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

  void _toggleHierarchyMode() {
    setState(() {
      _useCategorization = !_useCategorization;
      _hierarchy = null;
    });
    _loadHierarchy();
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
        title: const Text('Hierarchy Selection'),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Scene Structure',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Graph')),
                  ButtonSegment(value: true, label: Text('Category')),
                ],
                selected: {_useCategorization},
                onSelectionChanged: (Set<bool> selected) {
                  _toggleHierarchyMode();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _hierarchy != null
                ? ListView(
                    children: _hierarchy!
                        .map((node) => _buildHierarchyNode(
                            node as Map<String, dynamic>, state))
                        .toList(),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
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
        padding: EdgeInsets.only(left: level * 16.0),
        child: ListTile(
          leading: Icon(
            Icons.view_in_ar,
            size: 18,
            color: isSelected ? Colors.blue : Colors.grey,
          ),
          title: Text(
            displayName,
            style: TextStyle(
              color: isSelected ? Colors.blue : null,
              fontWeight: isSelected ? FontWeight.bold : null,
              fontSize: 14,
            ),
          ),
          trailing: isSelected
              ? const Icon(Icons.check_circle, size: 16, color: Colors.blue)
              : null,
          dense: true,
          onTap: () {
            if (isSelected) {
              _controller.unselectPart(selectionId);
            } else {
              _controller.selectPart(selectionId);
            }
          },
        ),
      );
    }

    return ExpansionTile(
      leading: Icon(
        type == 'category' ? Icons.folder : Icons.adjust,
        size: 20,
        color: type == 'node' ? Colors.orangeAccent : null,
      ),
      title: Text(
        displayName,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      dense: true,
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
    );
  }
}
