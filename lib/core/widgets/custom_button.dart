import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String? label;
  final Widget? icon;
  final VoidCallback onPressed;

  final Color backgroundColor;
  final Color textColor;

  final EdgeInsets padding;
  final double borderRadius;

  final Size? minimumSize;

  final TextStyle? textStyle;

  final MaterialTapTargetSize? tapTargetSize;

  final double spacing;

  const CustomButton({
    super.key,
    this.label,
    this.icon,
    required this.onPressed,
    this.backgroundColor = Colors.grey,
    this.textColor = Colors.white,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.borderRadius = 8.0,
    this.minimumSize,
    this.textStyle,
    this.tapTargetSize,
    this.spacing = 8,
  }) : assert(
         label != null || icon != null,
         'Either label or icon must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: padding,
        minimumSize: minimumSize,
        tapTargetSize:
            tapTargetSize ??
            ((minimumSize != null && minimumSize!.height < 48)
                ? MaterialTapTargetSize.shrinkWrap
                : null),
      ),

      onPressed: onPressed,

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) icon!,

          if (icon != null && label != null) SizedBox(width: spacing),

          if (label != null)
            Text(
              label!,
              style:
                  textStyle ??
                  Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: textColor),
            ),
        ],
      ),
    );
  }
}
