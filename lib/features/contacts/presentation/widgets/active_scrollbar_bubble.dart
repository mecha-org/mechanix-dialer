import 'package:mechanix_dialer/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ActiveScrollbarBubble extends StatelessWidget {
  final String symbol;
  final double verticalAlignment;

  const ActiveScrollbarBubble({
    super.key,
    required this.symbol,
    required this.verticalAlignment,
  });

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      alignment: Alignment(1.0, verticalAlignment),
      maxHeight: 40,
      maxWidth: 80,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.onSurfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              symbol,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.surface,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(right: 10),
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
