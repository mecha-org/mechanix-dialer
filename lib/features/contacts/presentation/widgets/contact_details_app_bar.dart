import 'package:flutter/material.dart';
import 'package:mechanix_dialer/core/constants/icons.dart';
import 'package:mechanix_dialer/core/theme/app_theme.dart';
import 'package:mechanix_dialer/core/utils/helper.dart';
import 'package:mechanix_dialer/core/widgets/custom_image_asset.dart';
import 'package:mechanix_contacts/features/contacts/data/models/contacts.dart';

class ContactDetailsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final ContactEntity contact;

  const ContactDetailsAppBar({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    final initials = getInitials(contact.name);

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 72,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.backgroundVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: initials.trim().isEmpty
                ? const CustomImage(
                    size: 28,
                    color: AppColors.onSurface,
                    assetPath: AppIcons.person,
                  )
                : Text(initials, style: Theme.of(context).textTheme.bodyLarge),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              contact.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(72);
}
