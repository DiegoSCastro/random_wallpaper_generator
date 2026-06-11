import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:random_wallpaper_generator/src/core/ads/admob.dart';
import 'package:random_wallpaper_generator/src/core/revenuecat/purchases.dart';
import 'package:random_wallpaper_generator/src/core/storage/favorites_repository.dart';
import 'package:random_wallpaper_generator/src/core/storage/settings_repository.dart';
import 'package:random_wallpaper_generator/src/core/theme/app_theme.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/registry.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/wallpaper_service.dart';
import 'package:random_wallpaper_generator/src/features/about/presentation/about_screen.dart';
import 'package:random_wallpaper_generator/src/features/home/presentation/home_screen.dart';
import 'package:random_wallpaper_generator/src/features/paywall/presentation/paywall_screen.dart';
import 'package:random_wallpaper_generator/src/features/settings/presentation/settings_screen.dart';

class RandomWallpaperGeneratorApp extends StatelessWidget {
  const RandomWallpaperGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<WallpaperRegistry>(
          create: (_) => const WallpaperRegistry(),
        ),
        RepositoryProvider<WallpaperService>(
          create: (_) => const WallpaperService(),
        ),
        RepositoryProvider<FavoritesRepository>(
          create: (_) => FavoritesRepository(),
        ),
        RepositoryProvider<SettingsRepository>(
          create: (_) => SettingsRepository(),
        ),
        RepositoryProvider<AdMobService>(
          create: (_) => AdMobService(),
        ),
        RepositoryProvider<PurchasesService>(
          create: (_) => PurchasesService(),
        ),
      ],
      child: MaterialApp(
        title: 'Random Wallpaper Generator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routes: {
          '/': (_) => const HomeScreen(),
          '/home': (_) => const HomeScreen(),
          '/settings': (_) => const SettingsScreen(),
          '/paywall': (_) => const PaywallScreen(),
          '/about': (_) => const AboutScreen(),
        },
      ),
    );
  }
}
