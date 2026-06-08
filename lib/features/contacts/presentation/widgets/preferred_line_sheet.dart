import 'package:flutter/material.dart';
import 'package:mechanix_dialer/core/theme/app_theme.dart';
import 'package:mechanix_contacts/features/contacts/data/models/sim_card.dart';
import 'package:mechanix_dialer/l10n/app_localizations.dart';

class PreferredLineSheet extends StatelessWidget {
  final List<SimCardEntity> simCards;
  final SimCardEntity selectedSim;
  final ValueChanged<SimCardEntity> onSelected;

  const PreferredLineSheet({
    super.key,
    required this.simCards,
    required this.selectedSim,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text(
                AppLocalizations.of(context)!.preferredLine,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
            ),

            ...simCards.map((sim) {
              final isSelected = selectedSim.slot == sim.slot;

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? AppColors.onSurface
                          : AppColors.onSurfaceVariantDark,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    sim.slot,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? AppColors.onSurface
                          : AppColors.onSurfaceVariantDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  sim.number,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariant,
                    fontWeight: isSelected
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(
                        Icons.check_circle,
                        color: AppColors.onSurface,
                        size: 20,
                      )
                    : null,
                onTap: () => onSelected(sim),
              );
            }),
          ],
        ),
      ),
    );
  }
}
