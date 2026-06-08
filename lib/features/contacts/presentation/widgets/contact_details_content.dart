import 'dart:ui';

import 'package:mechanix_dialer/core/constants/icons.dart';
import 'package:mechanix_dialer/core/theme/app_theme.dart';
import 'package:mechanix_dialer/core/widgets/custom_icon_button.dart';
import 'package:mechanix_dialer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ContactDetailsBody extends StatelessWidget {
  final String? selectedSimSlot;
  final String? selectedSimNumber;
  final List<String> numbers;
  final List<String> emails;
  final VoidCallback? onPreferredLineTap;
  final ValueChanged<String> onCall;
  final ValueChanged<String> onMessage;

  const ContactDetailsBody({
    super.key,
    required this.selectedSimSlot,
    required this.selectedSimNumber,
    required this.numbers,
    required this.emails,
    this.onPreferredLineTap,
    required this.onCall,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: AppColors.backgroundVariantLight, height: 1),
            const SizedBox(height: 16),

            if (selectedSimSlot != null && selectedSimNumber != null) ...[
              InkWell(
                onTap: onPreferredLineTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.preferredLine,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.onSurfaceVariant,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              selectedSimSlot!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            selectedSimNumber!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Divider(color: AppColors.backgroundVariantLight, height: 1),

              const SizedBox(height: 16),
            ],

            if (numbers.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  AppLocalizations.of(context)!.contact,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariantDark,
                    fontSize: 14,
                  ),
                ),
              ),
            ],

            ...numbers.map(
              (number) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        number,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                    CustomIconButton.asset(
                      assetPath: AppIcons.call,
                      inactiveBackgroundColor: AppColors.onSurfaceVariant,
                      activeColor: AppColors.surface,
                      iconSize: 28,
                      minSize: 44,
                      onPressed: () => onCall(number),
                    ),

                    const SizedBox(width: 28),

                    CustomIconButton.asset(
                      assetPath: AppIcons.message,
                      inactiveBackgroundColor: AppColors.backgroundVariant,
                      iconSize: 28,
                      onPressed: () => onMessage(number),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            const Divider(color: AppColors.backgroundVariantLight, height: 1),

            const SizedBox(height: 8),

            ...emails.map(
              (email) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  email,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
