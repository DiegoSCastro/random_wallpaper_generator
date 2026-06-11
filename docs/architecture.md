# Architecture Decisions

## State management: Cubit (flutter_bloc)

- App is simple (1 main screen with state machine)
- Cubit maps to: `GeneratorCubit` (current system, params, generated image), `SettingsCubit` (quality, palette, system picker), `FavoritesCubit` (saved wallpapers)
- No `BlocEvent` boilerplate — Cubit is the right level

## Repository return type: fpdart `TaskEither<Failure, T>`

- Per Diego's preference: model failures through return types, not `try/catch`
- Used in: `WallpaperRepository`, `FavoritesRepository`, `AdRepository`
- UI layer pattern-matches on `TaskEither` for error display

## Wallpaper rendering: CustomPainter (CPU) + FragmentShader (GPU)

- **CPU CustomPainter** for the dynamical system point iteration (cheap, debuggable)
- **GPU FragmentShader** for the final compositing: color gradient, blur, glow, vignette
- Off-screen render to `ui.Image` at 1440x3200 (typical Android)
- Save as PNG via `Image.toByteData(format: png)` to gallery

## Why not pure ShaderToy approach

- A full GLSL implementation of Lorenz attractor IS possible but harder to debug
- CustomPainter for the points + FragmentShader for the composite gives us:
  - Better control over the points (debuggable, testable, parameterizable)
  - Better visual quality (we can do anti-aliasing on the points, glow on the shader)
  - Easier to support 5+ systems (one CustomPainter per system, one shared shader)

## Performance budget

- **Target**: generation → image ready in <500ms on a Pixel 6 (mid-range 2021)
- **Method**:
  - Pre-compute points off main thread (`compute()` or Isolate)
  - Render at 1080x2400 by default; 1440x3200 for Pro
  - Cap iterations at 200k for free, 1M for Pro
  - Cache last 20 generated wallpapers in memory

## Theme: liquid-glass

- Material 3 + custom `ThemeData` with `surfaceTintColor: Colors.transparent`
- Translucent surfaces using `BackdropFilter` + `ImageFilter.blur`
- Very low contrast chrome (8% black overlay on top of wallpaper)
- No buttons with backgrounds — just text/icons with subtle glow

## File structure (chosen)

```
lib/
  app/                     # MaterialApp, router, theme
    app.dart
    router.dart
  src/
    core/
      theme/
        app_theme.dart
        liquid_glass.dart
      wallpaper/
        models/
          wallpaper_system.dart   # enum + metadata
          generator_params.dart
        generators/
          lorenz.dart
          clifford.dart
          hopalong.dart
          aizawa.dart
          rossler.dart
        generator.dart            # WallpaperGenerator interface
        registry.dart             # map<system, generator>
        palette.dart              # color palettes
        renderer.dart             # CustomPainter → ui.Image
        shader/
          wallpaper.frag          # GLSL fragment shader
        exporter.dart             # ui.Image → PNG, save to gallery
      storage/
        favorites_repository.dart
        settings_repository.dart
      ads/
        admob.dart                # AdMob wrapper
      revenuecat/
        purchases.dart            # RevenueCat wrapper
    features/
      home/
        presentation/
          home_screen.dart
          home_cubit.dart
        domain/
          models/
            wallpaper.dart
      settings/
        presentation/
          settings_screen.dart
          settings_cubit.dart
      paywall/
        presentation/
          paywall_screen.dart
      about/
        presentation/
          about_screen.dart
test/
  core/wallpaper/         # generator unit tests (each system)
  features/home/          # cubit tests
```

## Trade-offs rejected

- **Pure GLSL / shader-only**: harder to debug, more device-specific crashes
- **Riverpod**: Diego prefers Bloc, not introducing new paradigm
- **Hive for storage**: SharedPreferences is enough for <100 favorites
- **Clean Architecture full repo/domain/data split per feature**: overkill for 1-2 features
- **GetIt for DI**: simple `RepositoryProvider` + Cubit via `BlocProvider` is enough
