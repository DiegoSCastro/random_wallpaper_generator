import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_system.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/registry.dart';
import 'package:random_wallpaper_generator/src/features/home/presentation/home_cubit.dart';
import 'package:random_wallpaper_generator/src/features/home/presentation/widgets/action_bar.dart';
import 'package:random_wallpaper_generator/src/features/home/presentation/widgets/system_picker_sheet.dart';
import 'package:random_wallpaper_generator/src/features/home/presentation/widgets/wallpaper_canvas.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => HomeCubit(
        registry: ctx.read<WallpaperRegistry>(),
      )..loadInitial(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Random Wallpaper'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          final cubit = context.read<HomeCubit>();
          return Stack(
            fit: StackFit.expand,
            children: [
              WallpaperCanvas(state: state),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: ActionBar(
                    state: state,
                    onRegenerate: cubit.regenerate,
                    onSave: () => cubit.save(context),
                    onApply: () => cubit.apply(context),
                    onPickSystem: () => _openSystemPicker(context, cubit, state.system),
                  ),
                ),
              ),
              if (state.isGenerating)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x33000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openSystemPicker(
    BuildContext context,
    HomeCubit cubit,
    WallpaperSystem current,
  ) async {
    final picked = await showModalBottomSheet<WallpaperSystem>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SystemPickerSheet(
        current: current,
      ),
    );
    if (picked != null) {
      await cubit.changeSystem(picked);
    }
  }
}

// WallpaperSystem is used in the picker signature; keep the import alive.
// ignore: unused_element
typedef _Unused = WallpaperSystem;
