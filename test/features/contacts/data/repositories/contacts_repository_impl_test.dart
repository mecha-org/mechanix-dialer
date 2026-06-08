import 'dart:io';
import 'package:mechanix_contacts/objectbox.g.dart';
import 'package:mechanix_dialer/features/contacts/data/repositories/contacts_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_contacts/features/contacts/data/models/contacts.dart';
import 'package:mechanix_contacts/features/contacts/data/models/phone_numbers.dart';

void main() {
  late Store store;
  late ContactsRepositoryImpl repository;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('objectbox_contacts_test_');
    store = openStore(directory: tempDir.path);
    repository = ContactsRepositoryImpl(store: store);
  });

  tearDown(() async {
    store.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ContactsRepositoryImpl', () {
    test('getAll returns contacts ordered by name', () async {
      final box = store.box<ContactEntity>();

      final c1 = ContactEntity(name: 'Charlie');
      final c2 = ContactEntity(name: 'Alice');
      final c3 = ContactEntity(name: 'Bob');

      box.putMany([c1, c2, c3]);

      final results = await repository.getAll();

      expect(results.length, 3);
      expect(results[0].name, 'Alice');
      expect(results[1].name, 'Bob');
      expect(results[2].name, 'Charlie');
    });

    test('getById returns correct contact or null', () async {
      final box = store.box<ContactEntity>();
      final contact = ContactEntity(name: 'David');
      final id = box.put(contact);

      final found = await repository.getById(id);
      expect(found, isNotNull);
      expect(found!.name, 'David');

      final notFound = await repository.getById(999);
      expect(notFound, isNull);
    });

    test('save saves contact and its numbers, emails', () async {
      final contact = ContactEntity(name: 'Eva');
      await repository.save(
        contact,
        ['123456', '987654'],
        ['john@testemail.com'],
      );

      final saved = await repository.getById(contact.id);
      expect(saved, isNotNull);
      expect(saved!.name, 'Eva');
      expect(saved.phoneNumbers.length, 2);
      expect(
        saved.phoneNumbers.map((p) => p.number),
        containsAll(['123456', '987654']),
      );
    });

    test('save removes old numbers when updating', () async {
      final contact = ContactEntity(name: 'Frank');
      await repository.save(contact, ['111111'], []);

      // update numbers
      await repository.save(contact, ['222222', '333333'], []);

      final saved = await repository.getById(contact.id);
      expect(saved!.phoneNumbers.length, 2);
      expect(
        saved.phoneNumbers.map((p) => p.number),
        containsAll(['222222', '333333']),
      );
      expect(
        saved.phoneNumbers.map((p) => p.number),
        isNot(contains('111111')),
      );
    });

    test('delete removes contact and phone numbers', () async {
      final contact = ContactEntity(name: 'Grace');
      await repository.save(contact, ['999999'], []);

      final contactId = contact.id;
      final phoneBox = store.box<PhoneNumberEntity>();

      expect(phoneBox.query().build().find().length, 1);

      await repository.delete(contactId);

      final deletedContact = await repository.getById(contactId);
      expect(deletedContact, isNull);
      expect(phoneBox.query().build().find().length, 0);
    });

    test('search finds contact by name case insensitively', () async {
      final c1 = ContactEntity(name: 'John Doe');
      final c2 = ContactEntity(name: 'Jane Smith');

      await repository.save(c1, ['123'], []);
      await repository.save(c2, ['456'], []);

      final results = await repository.search('john');
      expect(results.length, 1);
      expect(results[0].name, 'John Doe');
    });

    test('search finds contact by phone number', () async {
      final c1 = ContactEntity(name: 'John Doe');
      final c2 = ContactEntity(name: 'Jane Smith');

      await repository.save(c1, ['123456789'], []);
      await repository.save(c2, ['987654321'], []);

      final results = await repository.search('456');
      expect(results.length, 1);
      expect(results[0].name, 'John Doe');
    });

    test('search returns all when query is empty', () async {
      final c1 = ContactEntity(name: 'Alice');
      final c2 = ContactEntity(name: 'Bob');

      await repository.save(c1, ['123'], []);
      await repository.save(c2, ['456'], []);

      final results = await repository.search('   ');
      expect(results.length, 2);
    });
  });
}
