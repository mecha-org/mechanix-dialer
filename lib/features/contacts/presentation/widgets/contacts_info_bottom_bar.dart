import 'package:mechanix_dialer/core/constants/icons.dart';
import 'package:flutter/material.dart';
import 'package:mechanix_dialer/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_dialer/core/widgets/custom_icon_button.dart';

class ContactsInfoBottomBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onMore;
  final bool isMenuActive;

  const ContactsInfoBottomBar({
    super.key,
    required this.onBack,
    required this.onMore,
    required this.isMenuActive,
  });

  @override
  Widget build(BuildContext context) {
    return BottomBar(
      key: const ValueKey('contacts_info_bottom_bar'),

      leading: CustomIconButton.asset(
        assetPath: AppIcons.back,
        onPressed: onBack,
      ),

      trailing: [
        CustomIconButton.icon(
          iconData: Icons.more_vert,
          onPressed: onMore,
          active: isMenuActive,
        ),
      ],
    );
  }
}
