import 'package:flutter/material.dart';
import 'package:power3d/power3d.dart';
import 'dart:convert';

/// Example demonstrating metadata and extras extraction:
/// - Fetching GLTF extras
/// - Displaying node metadata
/// - Interactive data inspection
class SelectionMetadataExample extends StatefulWidget {
  const SelectionMetadataExample({super.key});

  @override
  State<SelectionMetadataExample> createState() =>
      _SelectionMetadataExampleState();
}

class _SelectionMetadataExampleState extends State<SelectionMetadataExample> {
  final String _assetPath = 'assets/shoulder.glb';
  late final Power3DController _controller;
  Map<String, dynamic>? _selectedExtras;
  String? _loadingId;

  @override
  void initState() {
    super.initState();
    _controller = Power3DController();

    _controller.updateSelectionConfig(
      const SelectionConfig(
        enabled: true,
        multipleSelection: false, // Single selection is better for metadata inspection
        selectionStyle: SelectionStyle(
          outlineColor: Colors.purpleAccent,
          outlineWidth: 3.0,
        ),
      ),
    );

    _controller.onPartSelected((partIdentifier, selected) {
      if (selected) {
        _loadExtras(partIdentifier);
      } else {
        setState(() {
          _selectedExtras = null;
        });
      }
    });
  }

  Future<void> _loadExtras(String id) async {
    setState(() {
      _loadingId = id;
      _selectedExtras = null;
    });
    
    final extras = await _controller.getNodeExtras(id);
    
    if (mounted && _loadingId == id) {
      setState(() {
        _selectedExtras = extras;
        _loadingId = null;
      });
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
        title: const Text('Node Metadata & Extras'),
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
            flex: 1,
            child: Power3D.fromAsset(_assetPath, controller: _controller),
          ),
          Expanded(
            flex: 1,
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
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inpsection Panel',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildContent(state),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Power3DState state) {
    if (state.selectedParts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Select a part of the model\nto inspect its data',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_loadingId != null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedExtras == null || _selectedExtras!.isEmpty) {
      return const Center(child: Text('No metadata found for this node.'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Name', _selectedExtras!['name']),
          _buildInfoRow('Unique ID', _selectedExtras!['uniqueId']),
          _buildInfoRow('Type', _selectedExtras!['type']),
          const Divider(height: 32),
          const Text(
            'Raw Data (JSON)',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigoAccent),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert(_selectedExtras),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value?.toString() ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
