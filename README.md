# random_wallpaper_generator

Mathematical wallpaper generator for Android. Generates infinite procedural wallpapers using dynamical systems (Lorenz, Clifford, Hopalong, Aizawa, Rossler) rendered via Flutter CustomPainter and GLSL fragment shaders. Lightweight, GPU-accelerated, offline-first.

## Quick start

```bash
flutter pub get
flutter run                    # debug
flutter build apk --debug      # APK
flutter test                   # unit tests
flutter analyze                # static analysis
```

## Architecture

```
lib/
  app/                         # App entry, MaterialApp, router, theme
  src/
    core/
      theme/                   # Liquid-glass neutral theme (iOS-style translucent surfaces)
      wallpaper/               # Generators, palette, shader, exporter
      storage/                 # SharedPreferences, favorites repository
      ads/                     # AdMob wrapper (banner + interstitial, with kill-switch)
      revenuecat/              # Pro entitlement wrapper
    features/
      home/                    # Generator screen, infinite scroll, apply, save
      settings/                # Quality, palette, system picker
      paywall/                 # Pro upsell (remove ads + extra systems)
      about/                   # License, privacy
test/                          # Unit tests (generators, cubits, repositories)
```

## Generators

Each generator is a `WallpaperGenerator` — pure function `(seed, params) -> Image`. Implementations live in `lib/src/core/wallpaper/generators/`. Adding a new system = new file + one line in the registry.

| System | Family | Visual |
|---|---|---|
| Lorenz  | 3D attractor | Double-spiral, butterfly shape |
| Clifford | 2D attractor | Organic, plant-like |
| Hopalong | 2D attractor | Fractal curves |
| Aizawa | 3D attractor | Spherical web |
| Rossler | 3D attractor | Spiral roll |

## Stack

- Flutter 3.32.4 (Dart 3.8)
- VGV lint (`very_good_analysis`) — no full Very Good scaffold
- `flutter_bloc` (Cubit) for state
- `fpdart` for repository return types (`TaskEither`)
- `equatable` for value objects
- CustomPainter + GLSL `FragmentShader` for performance
- AdMob (banner + interstitial) — free tier
- RevenueCat — Pro tier (no ads, all systems, 4K export)

## Decisions deferred (post-MVP, documented in `docs/`)

- **Curated daily wallpaper** (server-side 1 PNG/day) — see `docs/curated-daily.md`
- Live wallpaper service (Android `WallpaperService`)
- iOS support
- Cloud sync of favorites
- Community gallery

## License

Private. © 2026 Omega Dev Apps.
