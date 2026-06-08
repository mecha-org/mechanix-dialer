import 'dart:io';

import 'package:dialer/core/exceptions/app_exception.dart';
import 'package:dialer/core/utils/app_logger.dart';
import 'package:dialer/core/utils/enums.dart';
import 'package:dialer/features/recents/data/models/recent_calls.dart';
import 'package:dialer/objectbox.g.dart';
import 'recent_calls_repository.dart';

class RecentCallsRepositoryImpl implements RecentCallsRepository {
  Store? _store;
  Box<RecentCallEntity>? _box;
  Future<void>? _initFuture;

  RecentCallsRepositoryImpl({Store? store}) : _store = store {
    if (store != null) {
      _box = store.box<RecentCallEntity>();
    }
  }

  Future<void> ensureStoreConnected() async {
    // already initialized
    if (_store != null && !_store!.isClosed()) {
      return;
    }

    // initialization already running
    if (_initFuture != null) {
      await _initFuture;
      return;
    }

    try {
      _initFuture = _initializeStore();
      await _initFuture;
    } catch (e) {
      AppLogger.e('Failed to open ObjectBox store: $e');
      if (e is FileSystemException && e.message.contains('lock failed')) {
        throw AppAlreadyRunningException();
      }
      rethrow;
    } finally {
      _initFuture = null;
    }
  }

  Future<void> _initializeStore() async {
    try {
      final home = Platform.environment['HOME'];
      final appDir = Directory('$home/.config/mechanix_dialer/objectbox');
      final exists = await appDir.exists();

      if (!exists) {
        await appDir.create(recursive: true);
      }

      _store = openStore(directory: appDir.path);
      _box = _store!.box<RecentCallEntity>();

      AppLogger.i(
        '[RecentCallRepository] ObjectBox store opened at ${appDir.path}',
      );
    } catch (e) {
      AppLogger.e('Failed to initialize ObjectBox store: $e');
      rethrow;
    }
  }

  void closeStore() {
    _store?.close();
    _store = null;
    _box = null;
  }

  @override
  Future<List<RecentCallEntity>> getAll() async {
    await ensureStoreConnected();
    final query = _box!
        .query()
        .order(RecentCallEntity_.timestamp, flags: Order.descending)
        .build();

    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  @override
  Stream<List<RecentCallEntity>> watchAll({int limit = 30}) async* {
    await ensureStoreConnected();
    final builder = _box!.query().order(
      RecentCallEntity_.timestamp,
      flags: Order.descending,
    );

    yield* builder
        .watch(triggerImmediately: false)
        .map((q) => q.find().take(limit).toList());
  }

  @override
  Future<void> add(RecentCallEntity call) async {
    await ensureStoreConnected();

    _store!.runInTransaction(TxMode.write, () {
      _box!.put(call);
    });
  }

  @override
  Future<void> delete(int id) async {
    await ensureStoreConnected();
    _store!.runInTransaction(TxMode.write, () {
      _box!.remove(id);
    });
  }

  @override
  Future<void> clear() async {
    await ensureStoreConnected();
    _store!.runInTransaction(TxMode.write, () {
      _box!.removeAll();
    });
  }

  @override
  Future<List<RecentCallEntity>> search(String queryStr) async {
    await ensureStoreConnected();
    final query = _box!
        .query(
          RecentCallEntity_.name.contains(queryStr, caseSensitive: false) |
              RecentCallEntity_.phoneNumber.contains(queryStr),
        )
        .order(RecentCallEntity_.timestamp, flags: Order.descending)
        .build();

    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  @override
  Future<List<RecentCallEntity>> getMissedCalls() async {
    await ensureStoreConnected();
    final query = _box!
        .query(RecentCallEntity_.callTypeIndex.equals(CallType.missed.index))
        .order(RecentCallEntity_.timestamp, flags: Order.descending)
        .build();

    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  @override
  Future<List<RecentCallEntity>> getPaged({
    required int offset,
    required int limit,
  }) async {
    await ensureStoreConnected();
    final query =
        _box!
            .query()
            .order(RecentCallEntity_.timestamp, flags: Order.descending)
            .build()
          ..offset = offset
          ..limit = limit;

    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  @override
  Future<List<RecentCallEntity>> getBefore({
    required DateTime lastTimestamp,
    int limit = 30,
  }) async {
    await ensureStoreConnected();
    final query =
        _box!
            .query(
              RecentCallEntity_.timestamp.lessThan(
                lastTimestamp.millisecondsSinceEpoch,
              ),
            )
            .order(RecentCallEntity_.timestamp, flags: Order.descending)
            .build()
          ..limit = limit;

    try {
      return query.find();
    } finally {
      query.close();
    }
  }
}
