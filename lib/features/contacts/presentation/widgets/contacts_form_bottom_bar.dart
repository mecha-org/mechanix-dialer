import 'package:mechanix_dialer/core/constants/icons.dart';
import 'package:flutter/material.dart';
import 'package:mechanix_dialer/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_dialer/core/widgets/custom_icon_button.dart';

class ContactsFormBottomBar extends StatelessWidget {
  final VoidCallback? onSave;

  const ContactsFormBottomBar({super.key, this.onSave});

  @override
  Widget build(BuildContext context) {
    return BottomBar(
      key: const ValueKey('contacts_form_bottom_bar'),

      leading: CustomIconButton.asset(
        assetPath: AppIcons.back,
        onPressed: () => Navigator.pop(context),
      ),
      trailing: [
        CustomIconButton.icon(iconData: Icons.check, onPressed: onSave),
      ],
    );
  }
}
