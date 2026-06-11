import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Random Wallpaper Generator',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text('v0.1.0 · © 2026 Omega Dev Apps',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            const Text(
              'Generates infinite procedural wallpapers from dynamical systems: '
              'Lorenz, Clifford, Hopalong, Aizawa, Rossler.',
            ),
            const SizedBox(height: 24),
            const Text('Privacy', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            const Text(
              'No account. No tracking. No data leaves your device. '
              'Wallpapers are generated locally on your phone.',
            ),
          ],
        ),
      ),
    );
  }
}
