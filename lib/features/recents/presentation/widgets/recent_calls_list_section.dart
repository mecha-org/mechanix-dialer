import 'package:dialer/core/utils/helper.dart';
import 'package:dialer/features/recents/data/models/recent_calls.dart';
import 'package:dialer/core/theme/app_theme.dart';
import 'package:dialer/features/recents/presentation/screens/recent_call_info_screen.dart';
import 'package:dialer/features/recents/presentation/widgets/call_type_icon.dart';
import 'package:dialer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class RecentCallsListSection extends StatefulWidget {
  final List<RecentCallEntity> calls;
  final ScrollController scrollController;
  final void Function(RecentCallEntity call)? onTap;
  final void Function(RecentCallEntity call)? onLongPress;

  const RecentCallsListSection({
    super.key,
    required this.calls,
    required this.scrollController,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<RecentCallsListSection> createState() => _RecentCallsListSectionState();
}

class _RecentCallsListSectionState extends State<RecentCallsListSection> {
  int? expandedIndex;
  final Map<String, ExpansibleController> _controllers = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.calls.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.allCalls,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      );
    }

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: widget.calls.length,
      itemBuilder: (context, index) {
        final call = widget.calls[index];

        return ListTile(
          key: ValueKey(call.id),
          shape: const Border(),
          minTileHeight: 70,
          leading: Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.backgroundVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: CallTypeIcon(type: call.callType)),
          ),

          title: Text(
            (call.name.isEmpty) ? call.phoneNumber : call.name,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),

          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatDateTime(call.timestamp, context),
                style: Theme.of(context).textTheme.labelSmall,
              ),

              const SizedBox(width: 8),

              AnimatedRotation(
                turns: expandedIndex == index ? 0.25 : 0,
                duration: const Duration(milliseconds: 200),

                child: const Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),

          onTap: () {
            if (widget.onTap != null) {
              widget.onTap!(call);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecentCallsInfoScreen(call: call),
                ),
              );
            }
          },
        );
      },
    );
  }
}
