import 'package:flutter/material.dart';
import 'package:dialer/core/theme/app_theme.dart';

class CustomIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;

  final bool enabled;
  final bool active;

  final double iconSize;
  final double minSize;

  final EdgeInsetsGeometry padding;

  final Color? activeColor;
  final Color? disabledColor;

  final Color? activeBackgroundColor;
  final Color? inactiveBackgroundColor;

  const CustomIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
    this.active = false,
    this.iconSize = 24,
    this.minSize = 48,
    this.padding = const EdgeInsets.all(8),
    this.activeColor,
    this.disabledColor,
    this.activeBackgroundColor,
    this.inactiveBackgroundColor,
  });

  /// Asset constructor
  factory CustomIconButton.asset({
    Key? key,
    required String assetPath,
    required VoidCallback? onPressed,
    bool enabled = true,
    bool active = false,
    double iconSize = 24,
    double minSize = 48,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8),
    Color? activeColor,
    Color? disabledColor,
    Color? activeBackgroundColor,
    Color? inactiveBackgroundColor,
  }) {
    return CustomIconButton(
      key: key,
      onPressed: onPressed,
      enabled: enabled,
      active: active,
      iconSize: iconSize,
      minSize: minSize,
      padding: padding,
      activeColor: activeColor,
      disabledColor: disabledColor,
      activeBackgroundColor: activeBackgroundColor,
      inactiveBackgroundColor: inactiveBackgroundColor,
      icon: Image.asset(assetPath, width: iconSize, height: iconSize),
    );
  }

  /// Material icon constructor
  factory CustomIconButton.icon({
    Key? key,
    required IconData iconData,
    required VoidCallback? onPressed,
    bool enabled = true,
    bool active = false,
    double iconSize = 24,
    double minSize = 48,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8),
    Color? activeColor,
    Color? disabledColor,
    Color? activeBackgroundColor,
    Color? inactiveBackgroundColor,
  }) {
    return CustomIconButton(
      key: key,
      onPressed: onPressed,
      enabled: enabled,
      active: active,
      iconSize: iconSize,
      minSize: minSize,
      padding: padding,
      activeColor: activeColor,
      disabledColor: disabledColor,
      activeBackgroundColor: activeBackgroundColor,
      inactiveBackgroundColor: inactiveBackgroundColor,
      icon: Icon(iconData, size: iconSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? (activeColor ?? AppColors.onSurface)
        : (disabledColor ?? AppColors.onSurfaceVariantDark);

    final backgroundColor = active
        ? (activeBackgroundColor ?? AppColors.onSurface.withValues(alpha: 0.12))
        : (inactiveBackgroundColor ?? Colors.transparent);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: padding,
          alignment: Alignment.center,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            child: SizedBox(width: iconSize, height: iconSize, child: icon),
          ),
        ),
      ),
    );
  }
}
