import 'package:flutter/material.dart';

class DialPadItem {
  final String? text;
  final Widget? icon;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const DialPadItem({
    this.text,
    this.icon,
    required this.backgroundColor,
    this.onTap,
  });
}
