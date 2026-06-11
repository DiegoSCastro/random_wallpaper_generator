import 'package:flutter_test/flutter_test.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/generators/aizawa.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/generators/clifford.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/generators/hopalong.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/generators/rossler.dart';

void main() {
  group('CliffordGenerator', () {
    test('produces points in [0..1]', () {
      const gen = CliffordGenerator();
      final points = gen.generate(
        params: gen.defaultParams.copyWith(iterations: 10000),
        maxPoints: 10000,
      );
      expect(points.length, 10000);
      for (final p in points) {
        expect(p.x, inInclusiveRange(0.0, 1.0));
        expect(p.y, inInclusiveRange(0.0, 1.0));
      }
    });
  });

  group('HopalongGenerator', () {
    test('produces points in [0..1]', () {
      const gen = HopalongGenerator();
      final points = gen.generate(
        params: gen.defaultParams.copyWith(iterations: 10000),
        maxPoints: 10000,
      );
      expect(points.length, 10000);
      for (final p in points) {
        expect(p.x, inInclusiveRange(0.0, 1.0));
        expect(p.y, inInclusiveRange(0.0, 1.0));
      }
    });
  });

  group('AizawaGenerator', () {
    test('produces points in [0..1]', () {
      const gen = AizawaGenerator();
      final points = gen.generate(
        params: gen.defaultParams.copyWith(iterations: 10000),
        maxPoints: 10000,
      );
      expect(points.length, 10000);
      for (final p in points) {
        expect(p.x, inInclusiveRange(0.0, 1.0));
        expect(p.y, inInclusiveRange(0.0, 1.0));
      }
    });
  });

  group('RosslerGenerator', () {
    test('produces points in [0..1]', () {
      const gen = RosslerGenerator();
      final points = gen.generate(
        params: gen.defaultParams.copyWith(iterations: 10000),
        maxPoints: 10000,
      );
      expect(points.length, 10000);
      for (final p in points) {
        expect(p.x, inInclusiveRange(0.0, 1.0));
        expect(p.y, inInclusiveRange(0.0, 1.0));
      }
    });
  });
}
