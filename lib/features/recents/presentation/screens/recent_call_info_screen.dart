import 'package:dialer/core/constants/icons.dart';
import 'package:dialer/core/theme/app_theme.dart';
import 'package:dialer/core/utils/helper.dart';
import 'package:dialer/core/widgets/custom_image_asset.dart';
import 'package:dialer/features/contacts/data/repositories/contacts_repository.dart';
import 'package:dialer/features/recents/data/models/recent_calls.dart';
import 'package:dialer/features/recents/data/repositories/recent_calls_repository.dart';
import 'package:dialer/features/recents/presentation/widgets/info_bottom_bar.dart';
import 'package:dialer/features/recents/presentation/widgets/info_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_contacts/features/contacts/data/models/sim_card.dart';

class RecentCallsInfoScreen extends StatefulWidget {
  final RecentCallEntity call;

  const RecentCallsInfoScreen({super.key, required this.call});

  @override
  State<RecentCallsInfoScreen> createState() => _RecentCallsInfoScreenState();
}

class _RecentCallsInfoScreenState extends State<RecentCallsInfoScreen> {
  final ScrollController _scrollController = ScrollController();
  List<RecentCallEntity> _contactCalls = [];
  List<SimCardEntity> _simCards = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContactHistory();
  }

  Future<void> _loadContactHistory() async {
    try {
      final recentsRepo = context.read<RecentCallsRepository>();
      final contactsRepo = context.read<ContactsRepository>();

      final allCalls = await recentsRepo.getAll();
      final simCards = await contactsRepo.getSimCards();

      final targetName = widget.call.name;
      final targetPhone = widget.call.phoneNumber;

      setState(() {
        _simCards = simCards;
        if (targetName.isNotEmpty) {
          _contactCalls = allCalls
              .where(
                (c) => c.name == targetName || c.phoneNumber == targetPhone,
              )
              .toList();
        } else {
          _contactCalls = allCalls
              .where((c) => c.phoneNumber == targetPhone)
              .toList();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.call.name.isNotEmpty
        ? widget.call.name
        : widget.call.phoneNumber;
    final initials = widget.call.name.isNotEmpty
        ? getInitials(widget.call.name)
        : "";

    final phoneNumbers = <String>{
      widget.call.phoneNumber,
      ..._contactCalls.map((c) => c.phoneNumber),
    }.toList();

    return Scaffold(
      appBar: AppBar(
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
              child: (initials.trim().isEmpty)
                  ? const CustomImage(
                      size: 28,
                      color: AppColors.onSurface,
                      assetPath: AppIcons.person,
                    )
                  : Text(
                      initials,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RecentCallInfoContent(
              scrollController: _scrollController,
              phoneNumbers: phoneNumbers,
              recentCalls: _contactCalls,
              simCards: _simCards,
            ),
      bottomNavigationBar: const RecentInfoBottomBar(),
    );
  }
}
