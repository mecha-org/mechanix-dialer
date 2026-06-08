import 'package:mechanix_dialer/core/utils/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:mechanix_dialer/features/recents/data/models/recent_calls.dart';

class RecentCallsState extends Equatable {
  final List<RecentCallEntity> calls;
  final bool hasReachedMax;
  final bool loadingMore;
  final RecentCallsStatus status;
  final String? error;
  final DateTime? lastTimestamp;
  final CallFilter filter;

  const RecentCallsState({
    this.calls = const [],
    this.hasReachedMax = false,
    this.loadingMore = false,
    this.status = RecentCallsStatus.initial,
    this.error,
    this.lastTimestamp,
    this.filter = CallFilter.all,
  });

  RecentCallsState copyWith({
    List<RecentCallEntity>? calls,
    bool? hasReachedMax,
    bool? loadingMore,
    RecentCallsStatus? status,
    String? error,
    DateTime? lastTimestamp,
    CallFilter? filter,
  }) {
    return RecentCallsState(
      calls: calls ?? this.calls,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      loadingMore: loadingMore ?? this.loadingMore,
      status: status ?? this.status,
      error: error,
      lastTimestamp: lastTimestamp ?? this.lastTimestamp,
      filter: filter ?? this.filter,
    );
  }

  @override
  List<Object?> get props => [
    calls,
    hasReachedMax,
    loadingMore,
    status,
    error,
    lastTimestamp,
    filter,
  ];
}
