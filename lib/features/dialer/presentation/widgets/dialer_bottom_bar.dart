import 'package:flutter/material.dart';
import 'package:dialer/core/constants/icons.dart';
import 'package:dialer/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:dialer/core/widgets/custom_icon_button.dart';

class DialerBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const DialerBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomBar(
      key: const ValueKey('dialer_bottom_bar'),

      leading: CustomIconButton.asset(
        assetPath: AppIcons.recent,
        active: currentIndex == 0,
        onPressed: () => onTap(0),
      ),

      center: [
        CustomIconButton.asset(
          assetPath: AppIcons.dialpad,
          active: currentIndex == 1,
          onPressed: () => onTap(1),
        ),
      ],

      trailing: [
        CustomIconButton.asset(
          assetPath: AppIcons.contacts,
          active: currentIndex == 2,
          onPressed: () => onTap(2),
        ),
      ],
    );
  }
}
