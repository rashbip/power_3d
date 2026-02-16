import 'package:example/options/asset_example.dart';
import 'package:example/options/error_example.dart';
import 'package:example/options/network_example.dart';
import 'package:example/options/placeholder_example.dart';
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
