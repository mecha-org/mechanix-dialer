import 'package:flutter/material.dart';
import 'package:mechanix_dialer/core/theme/app_theme.dart';
import 'package:mechanix_contacts/features/contacts/data/models/contacts.dart';
import 'package:mechanix_dialer/l10n/app_localizations.dart';

class ContactListTile extends StatelessWidget {
  final ContactEntity contact;
  final String initials;
  final VoidCallback onTap;

  const ContactListTile({
    super.key,
    required this.contact,
    required this.initials,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 70,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.backgroundVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          initials,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        contact.name,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: AppColors.onSurface),
      ),
      subtitle: Text(
        contact.phoneNumbers.isNotEmpty
            ? contact.phoneNumbers.first.number
            : AppLocalizations.of(context)!.noPhoneNumbers,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariantDark),
      ),
      onTap: onTap,
    );
  }
}
