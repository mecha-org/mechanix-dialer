import 'package:dialer/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class RecentCallFilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const RecentCallFilterTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),

        alignment: Alignment.center,

        padding: const EdgeInsets.symmetric(horizontal: 24),

        decoration: BoxDecoration(
          color: selected
              ? AppColors.backgroundVariantLight
              : AppColors.backgroundVariantDark,

          borderRadius: BorderRadius.circular(8),
        ),

        child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
