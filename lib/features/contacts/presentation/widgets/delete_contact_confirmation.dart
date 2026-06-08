import 'package:mechanix_dialer/core/theme/app_theme.dart';
import 'package:mechanix_dialer/core/widgets/custom_button.dart';
import 'package:mechanix_dialer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class DeleteContactBottomSheet extends StatelessWidget {
  final String contactName;
  final VoidCallback onDelete;

  const DeleteContactBottomSheet({
    super.key,
    required this.contactName,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.backgroundVariantDark),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.deleteContactTitle,
              style: Theme.of(context).textTheme.headlineLarge,
            ),

            const SizedBox(height: 12),

            Text(
              AppLocalizations.of(
                context,
              )!.deleteContactConfirmation(contactName),
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: AppLocalizations.of(context)!.cancel,
                    backgroundColor: AppColors.onSurfaceVariantDark,
                    textColor: AppColors.onSurface,
                    borderRadius: 0,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: CustomButton(
                    label: AppLocalizations.of(context)!.delete,
                    backgroundColor: AppColors.onSurface,
                    textColor: AppColors.surface,
                    borderRadius: 0,
                    onPressed: onDelete,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
