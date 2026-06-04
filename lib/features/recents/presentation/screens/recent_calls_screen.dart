import 'dart:ui';

import 'package:dialer/core/constants/icons.dart';
import 'package:dialer/core/theme/app_theme.dart';
import 'package:dialer/core/utils/enums.dart';
import 'package:dialer/core/widgets/custom_image_asset.dart';
import 'package:dialer/features/dialer/blocs/dialer_bloc.dart';
import 'package:dialer/features/dialer/blocs/dialer_state.dart';
import 'package:dialer/features/recents/blocs/recent_calls_bloc.dart';
import 'package:dialer/features/recents/blocs/recent_calls_event.dart';
import 'package:dialer/features/recents/blocs/recent_calls_state.dart';
import 'package:dialer/features/recents/presentation/widgets/recent_call_filter_tab.dart';
import 'package:dialer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dialer/features/recents/presentation/widgets/recent_calls_list_section.dart';

class RecentCallsScreen extends StatefulWidget {
  const RecentCallsScreen({super.key});

  @override
  State<RecentCallsScreen> createState() => _RecentCallsScreenState();
}

class _RecentCallsScreenState extends State<RecentCallsScreen> {
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _searchController = TextEditingController();

  CallFilter selectedFilter = CallFilter.all;

  @override
  void initState() {
    super.initState();

    context.read<RecentCallsBloc>().add(LoadRecentCalls());

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final bloc = context.read<RecentCallsBloc>();

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!bloc.state.loadingMore && !bloc.state.hasReachedMax) {
        bloc.add(LoadMoreRecentCalls());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DialerBloc, DialerState>(
      listenWhen: (previous, current) =>
          previous.callStatus != CallStatus.none &&
          current.callStatus == CallStatus.none,
      listener: (context, state) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.recentCalls),
          titleTextStyle: Theme.of(context).textTheme.displaySmall,
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RecentCallFilterTab(
                    label: AppLocalizations.of(context)!.allCalls,
                    selected: selectedFilter == CallFilter.all,
                    onTap: () {
                      setState(() {
                        selectedFilter = CallFilter.all;
                      });

                      context.read<RecentCallsBloc>().add(LoadRecentCalls());
                    },
                  ),

                  RecentCallFilterTab(
                    label: AppLocalizations.of(context)!.missedCalls,
                    selected: selectedFilter == CallFilter.missed,
                    onTap: () {
                      setState(() {
                        selectedFilter = CallFilter.missed;
                      });

                      context.read<RecentCallsBloc>().add(LoadMissedCalls());
                    },
                  ),
                ],
              ),
            ),
          ],

          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  final query = value.trim();

                  if (query.length > 2) {
                    context.read<RecentCallsBloc>().add(
                      SearchRecentCalls(query),
                    );
                  } else if (query.isEmpty) {
                    context.read<RecentCallsBloc>().add(LoadRecentCalls());
                  }
                },
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchInCallLog,
                  hintStyle: Theme.of(context).textTheme.labelMedium,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(8),
                    child: CustomImage(assetPath: AppIcons.search, size: 20),
                  ),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),

                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  fillColor: AppColors.backgroundVariantDark,
                ),
              ),
            ),
          ),
        ),

        body: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
          ),
          child: BlocBuilder<RecentCallsBloc, RecentCallsState>(
            buildWhen: (previous, current) =>
                previous.status != current.status ||
                previous.calls != current.calls ||
                previous.error != current.error,
            builder: (context, state) {
              if (state.status == RecentCallsStatus.loading &&
                  state.calls.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.status == RecentCallsStatus.loaded &&
                  state.calls.isEmpty) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context)!.noRecentCalls,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                );
              }

              return RecentCallsListSection(
                calls: state.calls,
                scrollController: _scrollController,
              );
            },
          ),
        ),
      ),
    );
  }
}
