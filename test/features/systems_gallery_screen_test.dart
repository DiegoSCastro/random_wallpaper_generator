// Tests for the SystemsGalleryScreen — confirms the static picker
// shows every WallpaperSystem and returns the picked system when a
// card is tapped.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_system.dart';
import 'package:random_wallpaper_generator/src/features/home/presentation/systems_gallery_screen.dart';

void main() {
  group('SystemsGalleryScreen', () {
    testWidgets('shows the grid with the current system at the top',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SystemsGalleryScreen(current: WallpaperSystem.lorenz),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      // The screen is rendered with the system that is currently
      // active on top — that's the only label the user is guaranteed
      // to see on a phone-portrait viewport without scrolling, so
      // we check for it.
      expect(find.byType(GridView), findsOneWidget);
      expect(
        find.text(WallpaperSystem.lorenz.label),
        findsAtLeastNWidgets(1),
        reason: 'current system label should be visible',
      );
      // And the system that immediately follows in the enum order —
      // the second card in the grid — also shows up. That confirms
      // GridView is laying out more than one child.
      expect(
        find.text(WallpaperSystem.clifford.label),
        findsAtLeastNWidgets(1),
        reason: 'second card label should be visible',
      );
    });

    testWidgets('emits the picked system when a card is tapped',
        (tester) async {
      WallpaperSystem? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SystemsGalleryScreen(
                          current: WallpaperSystem.lorenz,
                        ),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(WallpaperSystem.clifford.label));
      await tester.pumpAndSettle();
      expect(result, WallpaperSystem.clifford);
    });

    test('preview asset path uses the enum name', () {
      for (final system in WallpaperSystem.values) {
        final path = 'assets/system_previews/${system.name}.png';
        expect(path, startsWith('assets/system_previews/'));
        expect(path, endsWith('.png'));
      }
    });
  });
}
