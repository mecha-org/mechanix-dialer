import 'dart:async';
import 'dart:io';

import 'package:mechanix_dialer/core/constants/app_constants.dart';
import 'package:mechanix_dialer/core/exceptions/app_exception.dart';
import 'package:mechanix_dialer/core/utils/app_logger.dart';
import 'package:mechanix_dialer/core/utils/enums.dart';
import 'package:mechanix_dialer/features/recents/data/models/recent_calls.dart';
import 'package:mechanix_dialer/objectbox.g.dart';
import 'package:mechanix_contacts/mechanix_contacts.dart'
    hide openStore, getObjectBoxModel;
import 'recent_calls_repository.dart';

class RecentCallsRepositoryImpl implements RecentCallsRepository {
  Store? _store;
  Box<RecentCallEntity>? _box;
  Future<void>? _initFuture;

  final Store? _contactsStore;
  final bool _enableContactsSync;
  StreamSubscription? _contactsSubscription;

  /// Stores the phone-number-to-contact-name mapping from the last sync.
  /// Used to detect contact changes and update only affected recent calls.
  Map<String, String>? _lastSyncedPhoneToNameMap;

  RecentCallsRepositoryImpl({
    Store? store,
    Store? contactsStore,
    bool? enableContactsSync,
  }) : _store = store,
       _contactsStore = contactsStore,
       _enableContactsSync =
           enableContactsSync ?? (store == null || contactsStore != null) {
    if (store != null) {
      _box = store.box<RecentCallEntity>();
      _subscribeToContactChanges();
    }
  }

  Store? get _effectiveContactsStore {
    if (_contactsStore != null) return _contactsStore;
    try {
      return ContactsStoreService.store;
    } catch (_) {
      return null;
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
      final exists = await AppConstants.dialerStoreDir.exists();

      if (!exists) {
        await AppConstants.dialerStoreDir.create(recursive: true);
      }

      _store = openStore(directory: AppConstants.dialerStoreDir.path);
      _box = _store!.box<RecentCallEntity>();

      AppLogger.i(
        '[RecentCallRepository] ObjectBox store opened at ${AppConstants.dialerStoreDir.path}',
      );

      _subscribeToContactChanges();
    } catch (e) {
      AppLogger.e('Failed to initialize ObjectBox store: $e');
      rethrow;
    }
  }

  void closeStore() {
    _contactsSubscription?.cancel();
    _contactsSubscription = null;
    _store?.close();
    _store = null;
    _box = null;
  }

  Future<void> _subscribeToContactChanges() async {
    if (!_enableContactsSync) return;

    _contactsSubscription?.cancel();
    _contactsSubscription = null;

    try {
      if (_contactsStore == null) {
        await ContactsStoreService.ensureConnected();
      }
    } catch (e) {
      AppLogger.e('Failed to connect to contacts store: $e');
      return;
    }

    final contactsStore = _effectiveContactsStore;
    if (contactsStore == null || contactsStore.isClosed()) return;

    _contactsSubscription = contactsStore
        .box<ContactEntity>()
        .query()
        .watch()
        .listen((_) {
          _syncContactNamesToDatabase();
        });

    // Run a one-time sync initially to ensure databases are in sync.
    _syncContactNamesToDatabase();
  }

  Future<void> _syncContactNamesToDatabase() async {
    try {
      final contactsStore = _effectiveContactsStore;
      if (contactsStore == null || contactsStore.isClosed()) return;

      // 1. Fetch all contacts and build mapping of phone number -> contact name
      final phoneBox = contactsStore.box<PhoneNumberEntity>();
      final allPhones = phoneBox.getAll();
      final currentPhoneToName = <String, String>{};

      for (final phone in allPhones) {
        final contact = phone.contact.target;
        if (contact != null) {
          final cleanNum = phone.number.replaceAll(RegExp(r'\D'), '');
          if (cleanNum.isNotEmpty) {
            currentPhoneToName[cleanNum] = contact.name;
          }
          currentPhoneToName[phone.number] = contact.name;
        }
      }

      final isInitialSync = _lastSyncedPhoneToNameMap == null;
      if (isInitialSync) {
        _lastSyncedPhoneToNameMap = {};
      }

      // 2. Identify the changed phone numbers
      final changedPhoneNumbers = <String>{};

      // Check for additions/updates
      currentPhoneToName.forEach((number, name) {
        final oldName = _lastSyncedPhoneToNameMap![number];
        if (oldName != name) {
          changedPhoneNumbers.add(number);
        }
      });

      // Check for deletions
      _lastSyncedPhoneToNameMap!.forEach((number, name) {
        if (!currentPhoneToName.containsKey(number)) {
          changedPhoneNumbers.add(number);
        }
      });

      // Update the cache
      _lastSyncedPhoneToNameMap = currentPhoneToName;

      // If nothing has changed, do not perform any database query or write!
      if (!isInitialSync && changedPhoneNumbers.isEmpty) return;

      // 3. Fetch recent calls
      await ensureStoreConnected();
      final List<RecentCallEntity> callsToCheck;
      if (isInitialSync) {
        callsToCheck = _box!.getAll();
      } else {
        // Query only the recent calls matching the changed phone numbers
        final query = _box!
            .query(
              RecentCallEntity_.phoneNumber.oneOf(changedPhoneNumbers.toList()),
            )
            .build();
        try {
          callsToCheck = query.find();
        } finally {
          query.close();
        }
      }

      final callsToUpdate = <RecentCallEntity>[];

      // 4. Compare and update
      for (final call in callsToCheck) {
        final cleanNum = call.phoneNumber.replaceAll(RegExp(r'\D'), '');
        final matchedName =
            currentPhoneToName[cleanNum] ??
            currentPhoneToName[call.phoneNumber] ??
            '';

        if (call.name != matchedName) {
          call.name = matchedName;
          callsToUpdate.add(call);
        }
      }

      // 5. Save updates back to database
      if (callsToUpdate.isNotEmpty) {
        _store!.runInTransaction(TxMode.write, () {
          _box!.putMany(callsToUpdate);
        });
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to sync contact names to recent calls database: $e',
        stack: stackTrace,
      );
    }
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
  Stream<List<RecentCallEntity>> watchAll({
    int limit = AppConstants.recentCallsPageSize,
  }) async* {
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
    int limit = AppConstants.recentCallsPageSize,
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
