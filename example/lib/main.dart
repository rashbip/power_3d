import 'package:example/options/basic/asset_example.dart';
import 'package:example/options/basic/error_example.dart';
import 'package:example/options/basic/network_example.dart';
import 'package:example/options/basic/placeholder_example.dart';
import 'package:example/options/basic/environment_example.dart';
import 'package:example/options/basic/material_example.dart';
import 'package:example/options/selection/selection_example.dart';
import 'package:example/options/selection/selection_hierarchy_example.dart';
import 'package:example/options/selection/selection_visibility_example.dart';
import 'package:example/options/selection/selection_metadata_example.dart';
import 'package:example/options/selection/selection_visual_styles_example.dart';
import 'package:example/options/selection/selection_texture_example.dart';
import 'package:example/options/animation/animations_list_example.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Power3D Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Power3D Examples'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildExampleCard(
            context,
            title: 'Asset Loading',
            subtitle: 'Load models bundled with your app',
            icon: Icons.inventory_2,
            target: const AssetExample(),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            title: 'Network Loading',
            subtitle: 'Fetch models from the web (Lazy)',
            icon: Icons.cloud_download,
            target: const NetworkExample(),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            title: 'Custom Loading UI',
            subtitle: 'Provide your own fetching UI',
            icon: Icons.hourglass_empty,
            target: const PlaceholderExample(),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            title: 'Custom Error',
            subtitle: 'Provide your own error UI',
            icon: Icons.error_outline,
            target: const ErrorExample(),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            title: 'Environment Builder',
            subtitle: 'Sync Flutter background with 3D camera',
            icon: Icons.landscape,
            target: const EnvironmentExample(),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            title: 'Materials & Shading',
            subtitle: 'Change colors, transparency, and shading modes',
            icon: Icons.brush,
            target: const MaterialExample(),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            title: 'Object Parts & Selection',
            subtitle: 'Click to select parts, transform selections',
            icon: Icons.select_all,
            target: const SelectionExample(),
          ),
          const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Advanced Selection Features',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.indigoAccent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildExampleCard(
            context,
            title: 'Hierarchy & Structure',
            subtitle: 'Full scene graph and categorized views',
            icon: Icons.account_tree,
            target: const SelectionHierarchyExample(),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Visibility Controls',
            subtitle: 'Hide/Show selected and unselected parts',
            icon: Icons.visibility_outlined,
            target: const SelectionVisibilityExample(),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Metadata & Extras',
            subtitle: 'Extract GLTF extras and node data',
            icon: Icons.info_outline,
            target: const SelectionMetadataExample(),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Visual Styles & Boxes',
            subtitle: 'Material modes and bounding box helpers',
            icon: Icons.auto_fix_high,
            target: const SelectionVisualStylesExample(),
          ),
          const SizedBox(height: 12),
          _buildExampleCard(
            context,
            title: 'Texture Management',
            subtitle: 'Preview, edit, and export scene textures',
            icon: Icons.texture,
            target: const SelectionTextureExample(),
          ),
          const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Animations & Sequences',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildExampleCard(
            context,
            title: 'Animations List',
            subtitle: 'Manage playback, speed, and sequences',
            icon: Icons.movie_outlined,
            target: const AnimationsListExample(),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget target,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.indigoAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => target)),
      ),
    );
  }
}
