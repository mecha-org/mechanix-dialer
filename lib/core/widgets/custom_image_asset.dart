import 'package:mechanix_dialer/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class CustomImage extends StatelessWidget {
  final String assetPath;
  final double size;
  final Color? color;
  final bool enabled;
  final Color? disabledColor;

  const CustomImage({
    super.key,
    required this.assetPath,
    this.size = 24,
    this.color = AppColors.onSurface,
    this.enabled = true,
    this.disabledColor = AppColors.onSurfaceVariantDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color? effectiveColor = enabled ? color : disabledColor;

    return Image.asset(
      assetPath,
      width: size,
      height: size,
      color: effectiveColor,
    );
  }
}
