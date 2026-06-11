import 'package:flutter/material.dart';

import '../home_cubit.dart';

class WallpaperCanvas extends StatelessWidget {
  const WallpaperCanvas({required this.state, super.key});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    if (state.image == null) {
      return const ColoredBox(color: Colors.black);
    }
    return RawImage(
      image: state.image,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
    );
  }
}
