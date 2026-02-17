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
  final String _assetPath = 'assets/heart.glb';
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

    // Handle leaf nodes or selectable objects
    if (children.isEmpty && type != 'section' && type != 'category') {
      final isSelected = state.selectedParts.contains(selectionId);

      IconData iconData = Icons.adjust;
      Color iconColor = Colors.grey;

      switch (type) {
        case 'mesh':
          iconData = Icons.view_in_ar;
          iconColor = isSelected ? Colors.blue : Colors.grey;
          break;
        case 'camera':
          iconData = Icons.videocam;
          iconColor = Colors.blueAccent;
          break;
        case 'light':
          iconData = Icons.lightbulb_outline;
          iconColor = Colors.orangeAccent;
          break;
        case 'material':
          iconData = Icons.blur_on;
          iconColor = Colors.purpleAccent;
          break;
        case 'transform':
          iconData = Icons.open_with;
          iconColor = Colors.cyan;
          break;
      }

      return Padding(
        padding: EdgeInsets.only(left: level * 16.0),
        child: ListTile(
          leading: Icon(iconData, size: 18, color: iconColor),
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
            // Only meshes and materials (maybe) are selectable for styling/info
            if (type == 'mesh' || type == 'material') {
              if (isSelected) {
                _controller.unselectPart(selectionId);
              } else {
                _controller.selectPart(selectionId);
              }
            } else {
              // For others, just show metadata
              _controller.getNodeExtras(selectionId).then((extras) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Node: $name (Type: $type)')),
                  );
                }
              });
            }
          },
        ),
      );
    }

    // Handle folders / expansion tiles
    IconData folderIcon = Icons.folder_open;
    Color? folderColor;

    if (type == 'section') {
      folderIcon = name == 'Materials' ? Icons.api : Icons.account_tree;
      folderColor = Colors.indigoAccent;
    } else if (type == 'category') {
      folderIcon = Icons.folder;
      folderColor = Colors.amber;
    }

    return ExpansionTile(
      leading: Icon(folderIcon, size: 20, color: folderColor),
      title: Text(
        displayName,
        style: TextStyle(
          fontWeight: type == 'section' ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
          color: type == 'section' ? Colors.indigoAccent : null,
        ),
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
