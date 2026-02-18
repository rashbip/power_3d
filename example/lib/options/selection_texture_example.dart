import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:power3d/power3d.dart';

class SelectionTextureExample extends StatefulWidget {
  const SelectionTextureExample({super.key});

  @override
  State<SelectionTextureExample> createState() =>
      _SelectionTextureExampleState();
}

class _SelectionTextureExampleState extends State<SelectionTextureExample> {
  final String _assetPath = 'assets/shoulder.glb';
  late final Power3DController _controller;
  List<Power3DTexture> _textures = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = Power3DController();
  }

  Future<void> _refreshTextures() async {
    final textures = await _controller.getTexturesList();
    if (!mounted) return;
    setState(() {
      _textures = textures;
      _isLoading = false;
    });
  }

  Future<void> _previewTexture(Power3DTexture texture) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final data = await _controller.getTextureData(texture.uniqueId);
    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (data == null || data == '{}' || data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load texture data')),
      );
      return;
    }

    try {
      final bytes = base64Decode(data.split(',').last);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(texture.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
              const SizedBox(height: 12),
              Text('Type: ${texture.className}'),
              Text('ID: ${texture.uniqueId}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error decoding texture: $e')));
    }
  }

  Future<void> _exportTexture(Power3DTexture texture) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        '${texture.name.replaceAll(' ', '_')}_${texture.uniqueId}.png';
    final path = p.join(directory.path, fileName);

    final result = await _controller.exportTexture(texture.uniqueId, path);

    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Texture exported to: $path'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to export texture')));
    }
  }

  void _editTexture(Power3DTexture texture) {
    double currentLevel = texture.level;
    double currentUScale = texture.uScale;
    double currentVScale = texture.vScale;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Texture: ${texture.name}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                Text('Brightness (Level): ${currentLevel.toStringAsFixed(2)}'),
                Slider(
                  value: currentLevel,
                  min: 0.0,
                  max: 5.0,
                  onChanged: (value) {
                    setModalState(() => currentLevel = value);
                    _controller.updateTexture(
                      texture.uniqueId,
                      TextureUpdate(level: value),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text('U Scale (Tiling): ${currentUScale.toStringAsFixed(2)}'),
                Slider(
                  value: currentUScale,
                  min: 0.1,
                  max: 10.0,
                  onChanged: (value) {
                    setModalState(() => currentUScale = value);
                    _controller.updateTexture(
                      texture.uniqueId,
                      TextureUpdate(uScale: value),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text('V Scale (Tiling): ${currentVScale.toStringAsFixed(2)}'),
                Slider(
                  value: currentVScale,
                  min: 0.1,
                  max: 10.0,
                  onChanged: (value) {
                    setModalState(() => currentVScale = value);
                    _controller.updateTexture(
                      texture.uniqueId,
                      TextureUpdate(vScale: value),
                    );
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Texture Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTextures,
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
              onModelLoaded: () {
                _refreshTextures();
              },
            ),
          ),
          Expanded(flex: 3, child: _buildTextureList()),
        ],
      ),
    );
  }

  Widget _buildTextureList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_textures.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No textures found in this scene.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _refreshTextures,
              child: const Text('Scan Scene'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _textures.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final texture = _textures[index];
        final isImage = !texture.isRenderTarget;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isImage
                ? Colors.blue.shade100
                : Colors.orange.shade100,
            child: Icon(
              isImage ? Icons.image : Icons.layers,
              color: isImage ? Colors.blue : Colors.orange,
            ),
          ),
          title: Text(
            texture.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${texture.className} (Level: ${texture.level.toStringAsFixed(1)})',
          ),
          trailing: Wrap(
            spacing: 4,
            children: [
              if (isImage)
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 20),
                  tooltip: 'Preview',
                  onPressed: () => _previewTexture(texture),
                ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit Properties',
                onPressed: () => _editTexture(texture),
              ),
              if (isImage)
                IconButton(
                  icon: const Icon(Icons.download_outlined, size: 20),
                  tooltip: 'Export',
                  onPressed: () => _exportTexture(texture),
                ),
            ],
          ),
          onTap: isImage ? () => _previewTexture(texture) : null,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
