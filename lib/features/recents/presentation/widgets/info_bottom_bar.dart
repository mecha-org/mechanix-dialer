import 'package:dialer/core/constants/icons.dart';
import 'package:flutter/material.dart';
import 'package:dialer/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:dialer/core/widgets/custom_icon_button.dart';

class RecentInfoBottomBar extends StatelessWidget {
  const RecentInfoBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomBar(
      key: const ValueKey('dialer_bottom_bar'),

      leading: CustomIconButton.asset(
        assetPath: AppIcons.back,
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
}
