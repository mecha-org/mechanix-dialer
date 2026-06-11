import 'package:flutter/material.dart';
import 'package:mechanix_dialer/core/theme/app_theme.dart';
import 'package:mechanix_dialer/core/widgets/custom_image_asset.dart';

class CallActionButton extends StatelessWidget {
  final String icon;
  final bool isEnabled;
  final VoidCallback onTap;

  const CallActionButton({
    super.key,
    required this.icon,
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
          color: AppColors.backgroundVariantDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: CustomImage(
            assetPath: icon,
            size: 24,
            color: AppColors.onSurface,
            enabled: isEnabled,
          ),
        ),
      ),
    );
  }
}
