import 'dart:async';

import 'package:mechanix_dialer/core/utils/app_logger.dart';
import 'package:mechanix_dialer/core/utils/enums.dart';
import 'package:mechanix_dialer/features/recents/data/repositories/recent_calls_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'recent_calls_event.dart';
import 'recent_calls_state.dart';

class RecentCallsBloc extends Bloc<RecentCallsEvent, RecentCallsState> {
  final RecentCallsRepository repository;

  StreamSubscription? _watchSub;

  static const int pageLimit = 30;

  RecentCallsBloc(this.repository) : super(const RecentCallsState()) {
    on<LoadRecentCalls>(_onLoad);
    on<RecentCallsUpdated>(_onUpdated);
    on<LoadMoreRecentCalls>(_onLoadMore);
    on<RefreshRecentCalls>(_onRefresh);
    on<LoadMissedCalls>(_onMissed);
    on<SearchRecentCalls>(_onSearch);
  }

  // ---------------------------
  // INITIAL LOAD
  // ---------------------------
  Future<void> _onLoad(
    LoadRecentCalls event,
    Emitter<RecentCallsState> emit,
  ) async {
    emit(
      state.copyWith(status: RecentCallsStatus.loading, filter: CallFilter.all),
    );

    await _cancelWatch();

    _watchSub = repository.watchAll(limit: 1).listen((calls) {
      add(RecentCallsUpdated(calls));
    });

    try {
      final initial = await repository.getPaged(offset: 0, limit: pageLimit);

      emit(
        state.copyWith(
          status: RecentCallsStatus.loaded,
          calls: initial,
          lastTimestamp: initial.isNotEmpty ? initial.last.timestamp : null,
          hasReachedMax: initial.length < pageLimit,
        ),
      );
    } catch (e) {
      AppLogger.e('Failed to load recent calls: $e');
      emit(
        state.copyWith(status: RecentCallsStatus.error, error: e.toString()),
      );
    }
  }

  Future<void> _onUpdated(
    RecentCallsUpdated event,
    Emitter<RecentCallsState> emit,
  ) async {
    int currentCount = state.calls.isEmpty ? pageLimit : state.calls.length;

    // If a new call was added, increment currentCount to include it
    if (event.calls.isNotEmpty && state.calls.isNotEmpty) {
      final latestDbCall = event.calls.first;
      final latestStateCall = state.calls.first;
      if (latestDbCall.id != latestStateCall.id &&
          latestDbCall.timestamp.isAfter(latestStateCall.timestamp)) {
        currentCount++;
      }
    }

    try {
      if (state.filter == CallFilter.missed) {
        final missedCalls = await repository.getMissedCalls();
        emit(state.copyWith(calls: missedCalls, lastTimestamp: null));
      } else {
        final updatedCalls = await repository.getPaged(
          offset: 0,
          limit: currentCount,
        );
        emit(
          state.copyWith(
            calls: updatedCalls,
            lastTimestamp: updatedCalls.isNotEmpty
                ? updatedCalls.last.timestamp
                : null,
            hasReachedMax: updatedCalls.length < currentCount,
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Failed to update recent calls: $e');
    }
  }

  Future<void> _onLoadMore(
    LoadMoreRecentCalls event,
    Emitter<RecentCallsState> emit,
  ) async {
    if (state.loadingMore || state.hasReachedMax) {
      return;
    }

    emit(state.copyWith(loadingMore: true));

    try {
      final last = state.lastTimestamp;
      if (last == null) {
        emit(state.copyWith(loadingMore: false));
        return;
      }

      final more = await repository.getBefore(
        lastTimestamp: last,
        limit: pageLimit,
      );

      emit(
        state.copyWith(
          loadingMore: false,
          calls: [...state.calls, ...more],
          hasReachedMax: more.length < pageLimit,
          lastTimestamp: more.isNotEmpty
              ? more.last.timestamp
              : state.lastTimestamp,
        ),
      );
    } finally {
      emit(state.copyWith(loadingMore: false));
    }
  }

  // ---------------------------
  // REFRESH (SAFE RELOAD)
  // ---------------------------
  Future<void> _onRefresh(
    RefreshRecentCalls event,
    Emitter<RecentCallsState> emit,
  ) async {
    add(LoadRecentCalls());
  }

  // ---------------------------
  // MISSED CALLS FILTER
  // ---------------------------
  Future<void> _onMissed(
    LoadMissedCalls event,
    Emitter<RecentCallsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: RecentCallsStatus.loading,
        filter: CallFilter.missed,
      ),
    );

    _watchSub ??= repository.watchAll().listen((calls) {
      add(RecentCallsUpdated(calls));
    });

    try {
      final missed = await repository.getMissedCalls();

      emit(
        state.copyWith(
          status: RecentCallsStatus.loaded,
          calls: missed,
          hasReachedMax: true,
        ),
      );
    } catch (e) {
      AppLogger.e('Failed to load missed calls: $e');
      emit(
        state.copyWith(status: RecentCallsStatus.error, error: e.toString()),
      );
    }
  }

  // ---------------------------
  // SAFE STREAM CANCEL
  // ---------------------------
  Future<void> _cancelWatch() async {
    await _watchSub?.cancel();
    _watchSub = null;
  }

  @override
  Future<void> close() {
    _cancelWatch();
    return super.close();
  }

  Future<void> _onSearch(
    SearchRecentCalls event,
    Emitter<RecentCallsState> emit,
  ) async {
    final query = event.query.trim();

    if (query.isEmpty) {
      add(LoadRecentCalls());
      return;
    }

    emit(state.copyWith(status: RecentCallsStatus.loading));

    try {
      final results = await repository.search(query);

      emit(
        state.copyWith(
          status: RecentCallsStatus.loaded,
          calls: results,
          hasReachedMax: true,
        ),
      );
    } catch (e) {
      AppLogger.e('Failed to search recent calls: $e');
      emit(
        state.copyWith(status: RecentCallsStatus.error, error: e.toString()),
      );
    }
  }
}
