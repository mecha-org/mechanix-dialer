import 'package:flutter/material.dart';

class DialButton extends StatelessWidget {
  final String? text;
  final Widget? icon;
  final Color backgroundColor;
  final VoidCallback onTap;

  const DialButton({
    super.key,
    this.text,
    this.icon,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Center(
          child:
              icon ??
              Text(text!, style: Theme.of(context).textTheme.displayMedium),
        ),
      ),
    );
  }
}
