import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Default system'),
            subtitle: Text('Lorenz'),
            trailing: Icon(Icons.chevron_right),
          ),
          const ListTile(
            title: Text('Default palette'),
            subtitle: Text('Aurora'),
            trailing: Icon(Icons.chevron_right),
          ),
          const Divider(),
          const ListTile(
            title: Text('Iterations'),
            subtitle: Text('200,000 (default)'),
          ),
          const Divider(),
          ListTile(
            title: const Text('Upgrade to Pro'),
            subtitle: const Text('Remove ads, +10 systems, 4K export'),
            trailing: const Icon(Icons.star_rounded),
            onTap: () => Navigator.of(context).pushNamed('/paywall'),
          ),
          const Divider(),
          ListTile(
            title: const Text('About'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed('/about'),
          ),
        ],
      ),
    );
  }
}
