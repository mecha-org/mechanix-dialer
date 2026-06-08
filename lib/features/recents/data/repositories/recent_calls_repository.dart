import 'package:dialer/features/recents/data/models/recent_calls.dart';

abstract class RecentCallsRepository {
  Future<List<RecentCallEntity>> getAll();

  Stream<List<RecentCallEntity>> watchAll({int limit = 30});

  Future<void> add(RecentCallEntity call);

  Future<void> delete(int id);

  Future<void> clear();

  Future<List<RecentCallEntity>> search(String query);

  Future<List<RecentCallEntity>> getMissedCalls();

  Future<List<RecentCallEntity>> getPaged({
    required int offset,
    required int limit,
  });

  Future<List<RecentCallEntity>> getBefore({
    required DateTime lastTimestamp,
    int limit,
  });
}
