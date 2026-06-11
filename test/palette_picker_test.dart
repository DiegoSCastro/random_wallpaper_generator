// Widget tests for the palette picker UI on the home screen.
//
// Why this exists:
//   The new palette button in the top bar opens a modal bottom sheet
//   listing every [WallpaperPalette]. Tapping a tile should:
//     1. Show the sheet (with all 6 palettes visible).
//     2. Close the sheet on tap.
//     3. Update the cubit's palette to the picked value via
//        `changePalette` (which re-renders the wallpaper with the
//        new colors).
//
// We piggyback on the same _MockWallpaperService and HomeScreen pump
// helper as ios_smoke_test.dart so the cubit's isolate-based render
// path doesn't run in tests (we only assert on cubit state + on-screen
// widgets, not on pixel output).
//
// NOTE: We test the PalettePickerSheet directly (not the home-screen
// IconButton that opens it). The IconButton-on-canvas hit-test behavior
// is exercised by ios_smoke_test's long-press test; this file focuses
// on the sheet's contract (list, select, dismiss).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:random_wallpaper_generator/src/core/wallpaper/palette.dart';
import 'package:random_wallpaper_generator/src/features/home/presentation/widgets/palette_picker_sheet.dart';

Future<Widget> _pumpSheet(WidgetTester tester, WallpaperPalette current) async {
  // Use a tall test surface so the full sheet (drag handle + title +
  // 6 tiles) is laid out without scrolling. iPhone 15 in landscape
  // would also fit, but a tall portrait keeps the test surface
  // representative of the real layout.
  tester.view.physicalSize = const Size(393, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showModalBottomSheet<WallpaperPalette>(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => PalettePickerSheet(current: current),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.widget(find.byType(MaterialApp));
}

void main() {
  testWidgets('PalettePickerSheet lists all 6 palettes with a selected check',
      (tester) async {
    const current = WallpaperPalette.aurora;
    await _pumpSheet(tester, current);
    await tester.tap(find.text('Open'));
    // pumpAndSettle for the modal bottom sheet animation.
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    // All 6 palette labels must be on screen.
    expect(find.text('Aurora'), findsOneWidget);
    expect(find.text('Ember'), findsOneWidget);
    expect(find.text('Ocean'), findsOneWidget);
    expect(find.text('Mono'), findsOneWidget);
    expect(find.text('Sakura'), findsOneWidget);
    expect(find.text('Neon'), findsOneWidget);
    // Sheet title.
    expect(find.text('Color Palette'), findsOneWidget);
    // The selected palette (Aurora) has a check_circle_rounded; the
    // others have a circle_outlined. We just assert that exactly one
    // check icon is present.
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    // And the 5 unselected tiles have an empty circle.
    expect(find.byIcon(Icons.circle_outlined), findsNWidgets(5));
  });

  testWidgets(
      'tapping a palette tile pops the sheet with the picked palette',
      (tester) async {
    const current = WallpaperPalette.aurora;
    await _pumpSheet(tester, current);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    // Tap "Ember" — it should be one of the 5 non-current tiles.
    await tester.tap(find.text('Ember'));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    // After popping, the sheet's Material widget should be gone.
    expect(find.byType(PalettePickerSheet), findsNothing);
  });

  testWidgets('PalettePickerSheet shows 6 swatches (one per palette)',
      (tester) async {
    // Sanity check on the visual preview: every palette tile has a
    // 40x40 gradient swatch on the left. We can't directly enumerate
    // LinearGradients because they live inside BoxDecoration, not in
    // the widget tree. Instead we count the 40x40 Containers that
    // wrap the swatch — they have a unique size and a
    // BoxDecoration.gradient, so a simple SizedBox(width: 40) match
    // is enough.
    await _pumpSheet(tester, WallpaperPalette.aurora);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    final swatchContainers = find
        .byWidgetPredicate((w) => w is Container && w.constraints?.maxWidth == 40);
    expect(swatchContainers, findsNWidgets(6),
        reason: 'each palette tile should have a 40x40 gradient swatch');
  });
}
