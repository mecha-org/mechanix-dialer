import 'dart:ui';

import 'package:dialer/core/constants/icons.dart';
import 'package:dialer/core/theme/app_theme.dart';
import 'package:dialer/core/utils/enums.dart';
import 'package:dialer/core/utils/helper.dart';
import 'package:dialer/core/widgets/custom_icon_button.dart';
import 'package:dialer/features/dialer/blocs/dialer_bloc.dart';
import 'package:dialer/features/dialer/blocs/dialer_event.dart';
import 'package:dialer/features/dialer/data/models/sim_card.dart';
import 'package:dialer/features/recents/data/models/recent_calls.dart';
import 'package:dialer/features/recents/presentation/widgets/call_type_icon.dart';
import 'package:dialer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RecentCallInfoContent extends StatelessWidget {
  final ScrollController scrollController;
  final List<String> phoneNumbers;
  final List<RecentCallEntity> recentCalls;
  final List<SimCardEntity> simCards;

  const RecentCallInfoContent({
    super.key,
    required this.scrollController,
    required this.phoneNumbers,
    required this.recentCalls,
    required this.simCards,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: AppColors.backgroundVariantLight, height: 1),
            const SizedBox(height: 16),

            Text(
              AppLocalizations.of(context)!.contact,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariantDark,
              ),
            ),

            const SizedBox(height: 8),

            ...phoneNumbers.map(
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
                      onPressed: () {
                        context.read<DialerBloc>().add(
                          StartOutgoingCall(
                            number,
                            simNumber: simCards.first.number,
                          ),
                        );
                      },
                      inactiveBackgroundColor: AppColors.onSurfaceVariant,
                      activeColor: AppColors.surface,
                      iconSize: 28,
                      minSize: 44,
                    ),
                    const SizedBox(width: 28),
                    CustomIconButton.asset(
                      assetPath: AppIcons.message,
                      onPressed: () {
                        // TODO: Implement messaging functionality
                      },
                      inactiveBackgroundColor: AppColors.backgroundVariant,
                      iconSize: 28,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Divider(color: AppColors.backgroundVariantLight, height: 1),

            const SizedBox(height: 16),

            Text(
              AppLocalizations.of(context)!.callHistory,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariantDark,
              ),
            ),

            const SizedBox(height: 8),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentCalls.length,
              itemBuilder: (context, index) {
                final call = recentCalls[index];

                return _CallHistoryTile(call: call, simCards: simCards);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CallHistoryTile extends StatelessWidget {
  final RecentCallEntity call;
  final List<SimCardEntity> simCards;

  const _CallHistoryTile({required this.call, required this.simCards});

  String _getSimSlot(String? simNumber) {
    if (simNumber == null) return '1';
    final match = simCards.firstWhere((sim) => sim.number == simNumber);
    return match.slot;
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = formatDateTime(call.timestamp, context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              formattedTime,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CallTypeIcon(type: call.callType, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _formatCallType(context, call.callType),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.onSurfaceVariantDark,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        _getSimSlot(call.simNumber),
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariantDark,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formatDuration(context, call.durationSeconds),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariantDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Text(
            call.phoneNumber,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _formatCallType(BuildContext context, CallType type) {
    final l10n = AppLocalizations.of(context)!;

    switch (type) {
      case CallType.incoming:
        return l10n.incomingCall;
      case CallType.outgoing:
        return l10n.outgoingCall;
      case CallType.missed:
        return l10n.missedCall;
      case CallType.rejected:
        return l10n.cancelledCall;
      case CallType.blocked:
        return l10n.blockedCall;
    }
  }
}
