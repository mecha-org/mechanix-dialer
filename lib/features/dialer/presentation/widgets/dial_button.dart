import 'package:flutter/material.dart';

class DialButton extends StatelessWidget {
  final String? text;
  final String? subText;
  final Widget? icon;
  final Color backgroundColor;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const DialButton({
    super.key,
    this.text,
    this.subText,
    this.icon,
    required this.backgroundColor,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        onLongPress: onLongPress,
        onSecondaryTap: onLongPress,
        child: Center(
          child:
              icon ??
              (subText == null
                  ? Text(
                      text!,
                      style: Theme.of(context).textTheme.displayMedium,
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          text!,
                          style: Theme.of(
                            context,
                          ).textTheme.displayMedium?.copyWith(height: 1.1),
                        ),
                        Text(
                          subText!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    )),
        ),
      ),
    );
  }
}
