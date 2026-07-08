import 'package:flutter/material.dart';

class DialPadItem {
  final String? text;
  final String? subText;
  final Widget? icon;
  final Color backgroundColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const DialPadItem({
    this.text,
    this.subText,
    this.icon,
    required this.backgroundColor,
    this.onTap,
    this.onLongPress,
  });
}
