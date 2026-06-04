import 'package:flutter/material.dart';
import 'package:dialer/core/theme/app_theme.dart';
import 'package:dialer/core/widgets/custom_image_asset.dart';

class CallToggleButton extends StatelessWidget {
  final String icon;
  final bool isActive;
  final bool isEnabled;
  final VoidCallback onTap;

  const CallToggleButton({
    super.key,
    required this.icon,
    required this.isActive,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: 160,
        height: 72,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.onSurface
              : AppColors.backgroundVariantDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: CustomImage(
            assetPath: icon,
            size: 24,
            color: isActive ? AppColors.surface : AppColors.onSurface,
            enabled: isEnabled,
          ),
        ),
      ),
    );
  }
}
