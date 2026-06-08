import 'package:mechanix_dialer/features/recents/data/models/recent_calls.dart';
import 'package:equatable/equatable.dart';

abstract class RecentCallsEvent extends Equatable {
  const RecentCallsEvent();

  @override
  List<Object?> get props => [];
}

/// Load initial data (watch + first page)
class LoadRecentCalls extends RecentCallsEvent {}

/// Triggered by ObjectBox watch stream
class RecentCallsUpdated extends RecentCallsEvent {
  final List<RecentCallEntity> calls;

  const RecentCallsUpdated(this.calls);

  @override
  List<Object?> get props => [calls];
}

/// Load older calls (pagination)
class LoadMoreRecentCalls extends RecentCallsEvent {}

/// Refresh manually
class RefreshRecentCalls extends RecentCallsEvent {}

/// Filter missed calls
class LoadMissedCalls extends RecentCallsEvent {}

class SearchRecentCalls extends RecentCallsEvent {
  final String query;

  const SearchRecentCalls(this.query);
}
