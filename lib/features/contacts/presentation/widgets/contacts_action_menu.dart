import 'package:mechanix_dialer/core/theme/app_theme.dart';
import 'package:mechanix_dialer/core/widgets/custom_icon_button.dart';
import 'package:mechanix_dialer/features/contacts/presentation/screens/contact_details_screen.dart';
import 'package:mechanix_dialer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ContactsActionsMenu extends StatelessWidget {
  final VoidCallback closeContactsActionsSheet;
  final ContactDetailsScreenState state;

  const ContactsActionsMenu({
    super.key,
    required this.closeContactsActionsSheet,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundVariant,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomIconButton.icon(
                iconData: Icons.close,
                onPressed: closeContactsActionsSheet,
              ),
            ],
          ),

          const Divider(height: 1, color: AppColors.backgroundVariantLight),

          ListTile(
            minTileHeight: 60,
            leading: const Icon(
              Icons.edit_outlined,
              color: AppColors.onSurface,
            ),
            title: Text(
              AppLocalizations.of(context)!.editContact,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.onSurface),
            ),
            onTap: () {
              closeContactsActionsSheet();
              state.editContact();
            },
          ),

          ListTile(
            minTileHeight: 60,
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title: Text(
              AppLocalizations.of(context)!.deleteContact,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: Colors.redAccent),
            ),
            onTap: () {
              closeContactsActionsSheet();
              state.confirmDelete();
            },
          ),
        ],
      ),
    );
  }
}
