import 'dart:io';

import 'package:mechanix_dialer/core/utils/enums.dart';
import 'package:mechanix_dialer/features/recents/data/models/recent_calls.dart';
import 'package:mechanix_dialer/features/recents/data/repositories/recent_calls_repository_impl.dart';
import 'package:mechanix_dialer/objectbox.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_contacts/mechanix_contacts.dart' as contacts_pkg;

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

    group('dynamic contact name resolution', () {
      late Store contactsStore;
      late Directory contactsTempDir;

      setUp(() async {
        contactsTempDir = await Directory.systemTemp.createTemp('objectbox_contacts_test_');
        contactsStore = contacts_pkg.openStore(directory: contactsTempDir.path);
        repository = RecentCallsRepositoryImpl(store: store, contactsStore: contactsStore);
      });

      tearDown(() async {
        contactsStore.close();
        if (await contactsTempDir.exists()) {
          await contactsTempDir.delete(recursive: true);
        }
      });

      test('resolves and updates name from contacts store dynamically', () async {
        // 1. Add recent call logs (without contact name, or with old name)
        final call1 = RecentCallEntity(
          name: 'Old Name',
          phoneNumber: '123456789',
          timestamp: DateTime.now(),
          durationSeconds: 60,
        );
        final call2 = RecentCallEntity(
          name: '',
          phoneNumber: '987654321',
          timestamp: DateTime.now(),
          durationSeconds: 120,
        );
        await repository.add(call1);
        await repository.add(call2);

        // 2. Add contact in contactsStore matching call1 and call2
        final contactBox = contactsStore.box<contacts_pkg.ContactEntity>();
        final phoneBox = contactsStore.box<contacts_pkg.PhoneNumberEntity>();

        final contact1 = contacts_pkg.ContactEntity(name: 'Updated John');
        contactBox.put(contact1);
        final phone1 = contacts_pkg.PhoneNumberEntity(number: '123456789');
        phone1.contact.target = contact1;
        phoneBox.put(phone1);

        final contact2 = contacts_pkg.ContactEntity(name: 'New Bob');
        contactBox.put(contact2);
        final phone2 = contacts_pkg.PhoneNumberEntity(number: '987-654-321'); // different formatting
        phone2.contact.target = contact2;
        phoneBox.put(phone2);

        // Wait for asynchronous sync listener
        await Future.delayed(const Duration(milliseconds: 100));

        // 3. Fetch from repository
        final results = await repository.getAll();

        expect(results.length, 2);
        
        // Find by phone number to check values
        final resJohn = results.firstWhere((r) => r.phoneNumber == '123456789');
        final resBob = results.firstWhere((r) => r.phoneNumber == '987654321');

        expect(resJohn.name, 'Updated John'); // name is updated dynamically
        expect(resBob.name, 'New Bob'); // formatted number matches and name is updated
      });

      test('clears contact name if contact is deleted', () async {
        // 1. Add call log
        final call = RecentCallEntity(
          name: 'Some Name',
          phoneNumber: '123456',
          timestamp: DateTime.now(),
          durationSeconds: 10,
        );
        await repository.add(call);

        // 2. Add contact
        final contactBox = contactsStore.box<contacts_pkg.ContactEntity>();
        final phoneBox = contactsStore.box<contacts_pkg.PhoneNumberEntity>();

        final contact = contacts_pkg.ContactEntity(name: 'Alice');
        contactBox.put(contact);
        final phone = contacts_pkg.PhoneNumberEntity(number: '123456');
        phone.contact.target = contact;
        phoneBox.put(phone);

        // Wait for sync listener
        await Future.delayed(const Duration(milliseconds: 100));

        // Fetch to ensure name resolved
        var results = await repository.getAll();
        expect(results.first.name, 'Alice');

        // 3. Delete contact
        contactBox.remove(contact.id);
        phoneBox.remove(phone.id);

        // Wait a tiny bit for the subscription event to fire and clear the cache
        await Future.delayed(const Duration(milliseconds: 100));

        // Fetch again and verify name is cleared
        results = await repository.getAll();
        expect(results.first.name, '');
      });

      test('searches recent calls by updated contact name', () async {
        final call = RecentCallEntity(
          name: 'Old Name',
          phoneNumber: '555-555',
          timestamp: DateTime.now(),
          durationSeconds: 15,
        );
        await repository.add(call);

        final contactBox = contactsStore.box<contacts_pkg.ContactEntity>();
        final phoneBox = contactsStore.box<contacts_pkg.PhoneNumberEntity>();

        final contact = contacts_pkg.ContactEntity(name: 'Charlie Brown');
        contactBox.put(contact);
        final phone = contacts_pkg.PhoneNumberEntity(number: '555-555');
        phone.contact.target = contact;
        phoneBox.put(phone);

        // Wait for sync listener
        await Future.delayed(const Duration(milliseconds: 100));

        // Search for 'Charlie' should find the call log of 555-555
        final results = await repository.search('Charlie');
        expect(results.length, 1);
        expect(results.first.name, 'Charlie Brown');
        expect(results.first.phoneNumber, '555-555');
      });
    });
  });
}
