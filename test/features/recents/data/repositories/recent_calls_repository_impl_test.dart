import 'dart:io';

import 'package:mechanix_dialer/core/utils/enums.dart';
import 'package:mechanix_dialer/features/recents/data/models/recent_calls.dart';
import 'package:mechanix_dialer/features/recents/data/repositories/recent_calls_repository_impl.dart';
import 'package:mechanix_dialer/objectbox.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Store store;
  late RecentCallsRepositoryImpl repository;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('objectbox_recents_test_');
    store = openStore(directory: tempDir.path);
    repository = RecentCallsRepositoryImpl(store: store);
  });

  tearDown(() async {
    store.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('RecentCallsRepositoryImpl', () {
    test('add saves recent call log', () async {
      final call = RecentCallEntity(
        name: 'Alice',
        phoneNumber: '12345',
        timestamp: DateTime.now(),
        durationSeconds: 120,
        callTypeIndex: CallType.outgoing.index,
      );

      await repository.add(call);

      final box = store.box<RecentCallEntity>();
      final results = box.getAll();
      expect(results.length, 1);
      expect(results.first.name, 'Alice');
      expect(results.first.durationSeconds, 120);
    });

    test('getAll returns logs sorted by timestamp descending', () async {
      final now = DateTime.now();
      final call1 = RecentCallEntity(
        name: 'Alice',
        phoneNumber: '123',
        timestamp: now.subtract(const Duration(minutes: 10)),
        durationSeconds: 30,
      );
      final call2 = RecentCallEntity(
        name: 'Bob',
        phoneNumber: '456',
        timestamp: now,
        durationSeconds: 45,
      );

      await repository.add(call1);
      await repository.add(call2);

      final results = await repository.getAll();
      expect(results.length, 2);
      expect(results[0].name, 'Bob'); // latest first
      expect(results[1].name, 'Alice');
    });

    test('delete removes specified call log', () async {
      final call = RecentCallEntity(
        name: 'Charlie',
        phoneNumber: '789',
        timestamp: DateTime.now(),
        durationSeconds: 10,
      );
      await repository.add(call);
      expect(call.id, isNot(0));

      await repository.delete(call.id);

      final box = store.box<RecentCallEntity>();
      expect(box.get(call.id), isNull);
    });

    test('clear removes all call logs', () async {
      await repository.add(
        RecentCallEntity(
          name: 'A',
          phoneNumber: '1',
          timestamp: DateTime.now(),
          durationSeconds: 10,
        ),
      );
      await repository.add(
        RecentCallEntity(
          name: 'B',
          phoneNumber: '2',
          timestamp: DateTime.now(),
          durationSeconds: 15,
        ),
      );

      await repository.clear();

      final results = await repository.getAll();
      expect(results.isEmpty, true);
    });

    test('search filters logs by name or phone number', () async {
      final call1 = RecentCallEntity(
        name: 'Alice Cooper',
        phoneNumber: '999888',
        timestamp: DateTime.now(),
        durationSeconds: 10,
      );
      final call2 = RecentCallEntity(
        name: 'Bob Marley',
        phoneNumber: '777666',
        timestamp: DateTime.now(),
        durationSeconds: 10,
      );

      await repository.add(call1);
      await repository.add(call2);

      // Search by name (case-insensitive)
      var results = await repository.search('alice');
      expect(results.length, 1);
      expect(results.first.name, 'Alice Cooper');

      // Search by phone number
      results = await repository.search('666');
      expect(results.length, 1);
      expect(results.first.name, 'Bob Marley');
    });

    test('getMissedCalls returns only missed calls', () async {
      final now = DateTime.now();
      await repository.add(
        RecentCallEntity(
          name: 'A',
          phoneNumber: '1',
          timestamp: now,
          durationSeconds: 10,
          callTypeIndex: CallType.missed.index,
        ),
      );
      await repository.add(
        RecentCallEntity(
          name: 'B',
          phoneNumber: '2',
          timestamp: now.subtract(const Duration(seconds: 5)),
          durationSeconds: 15,
          callTypeIndex: CallType.incoming.index,
        ),
      );

      final missed = await repository.getMissedCalls();
      expect(missed.length, 1);
      expect(missed.first.name, 'A');
    });

    test('getPaged performs correct offset and limit pagination', () async {
      final now = DateTime.now();
      for (int i = 0; i < 5; i++) {
        await repository.add(
          RecentCallEntity(
            name: 'Person $i',
            phoneNumber: '$i',
            timestamp: now.subtract(Duration(minutes: i)),
            durationSeconds: 10,
          ),
        );
      }

      // Latest call has offset index 0 (Person 0)
      final page1 = await repository.getPaged(offset: 1, limit: 2);
      expect(page1.length, 2);
      expect(page1[0].name, 'Person 1');
      expect(page1[1].name, 'Person 2');
    });

    test('getBefore returns calls older than given timestamp', () async {
      final now = DateTime.now();
      final call1 = RecentCallEntity(
        name: 'Newest',
        phoneNumber: '1',
        timestamp: now,
        durationSeconds: 10,
      );
      final call2 = RecentCallEntity(
        name: 'Middle',
        phoneNumber: '2',
        timestamp: now.subtract(const Duration(minutes: 5)),
        durationSeconds: 10,
      );
      final call3 = RecentCallEntity(
        name: 'Oldest',
        phoneNumber: '3',
        timestamp: now.subtract(const Duration(minutes: 10)),
        durationSeconds: 10,
      );

      await repository.add(call1);
      await repository.add(call2);
      await repository.add(call3);

      final results = await repository.getBefore(
        lastTimestamp: now.subtract(const Duration(minutes: 2)),
        limit: 2,
      );

      expect(results.length, 2);
      expect(results[0].name, 'Middle');
      expect(results[1].name, 'Oldest');
    });

    test('watchAll returns a stream of recent calls', () {
      final watchStream = repository.watchAll(limit: 2);
      expect(watchStream, isA<Stream<List<RecentCallEntity>>>());
    });
  });
}
