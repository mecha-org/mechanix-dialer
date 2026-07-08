import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_contacts/mechanix_contacts.dart';
import 'package:mechanix_dialer/core/utils/helper.dart';
import 'package:mechanix_dialer/features/contacts/data/repositories/contacts_repository_impl.dart';
import 'package:mechanix_dialer/l10n/app_localizations.dart';

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

    group('Save Duplicate and Format Validation Tests', () {
      test('save throws DuplicateContactException when same name and same number exist', () async {
        final c1 = ContactEntity(name: 'John Doe');
        await repository.save(c1, ['1234567890'], []);

        final c2 = ContactEntity(name: 'John Doe');
        expect(
          () => repository.save(c2, ['1234567890'], []),
          throwsA(isA<DuplicateContactException>()),
        );
      });

      test('save throws DuplicateContactException when same name (case-insensitive) and same number (with formatting) exist', () async {
        final c1 = ContactEntity(name: 'John Doe');
        await repository.save(c1, ['1234567890'], []);

        final c2 = ContactEntity(name: 'john doe');
        expect(
          () => repository.save(c2, ['(123) 456-7890'], []),
          throwsA(isA<DuplicateContactException>()),
        );
      });

      test('save succeeds when same name but different phone numbers', () async {
        final c1 = ContactEntity(name: 'John Doe');
        await repository.save(c1, ['1234567890'], []);

        final c2 = ContactEntity(name: 'John Doe');
        await repository.save(c2, ['9876543210'], []);

        final all = await repository.getAll();
        expect(all.length, 2);
      });

      test('save succeeds when different name but same phone number', () async {
        final c1 = ContactEntity(name: 'John Doe');
        await repository.save(c1, ['1234567890'], []);

        final c2 = ContactEntity(name: 'Jane Doe');
        await repository.save(c2, ['1234567890'], []);

        final all = await repository.getAll();
        expect(all.length, 2);
      });

      test('save succeeds when updating own contact with same name and phone number', () async {
        final contact = ContactEntity(name: 'John Doe');
        await repository.save(contact, ['1234567890'], []);

        // Update the same contact
        await repository.save(contact, ['1234567890'], []);

        final all = await repository.getAll();
        expect(all.length, 1);
        expect(all[0].name, 'John Doe');
        expect(all[0].phoneNumbers[0].number, '1234567890');
      });

      test('save throws DuplicateContactException when updating a contact to match another contact\'s name and number', () async {
        final c1 = ContactEntity(name: 'John Doe');
        await repository.save(c1, ['1234567890'], []);

        final c2 = ContactEntity(name: 'Jane Smith');
        await repository.save(c2, ['9876543210'], []);

        // Attempt to update Jane Smith to match John Doe's name and number
        c2.name = 'John Doe';
        expect(
          () => repository.save(c2, ['1234567890'], []),
          throwsA(isA<DuplicateContactException>()),
        );
      });

      test('save throws DuplicateContactException if one of the multiple numbers matches an existing contact with the same name', () async {
        final c1 = ContactEntity(name: 'John Doe');
        await repository.save(c1, ['123456', '789012'], []);

        final c2 = ContactEntity(name: 'JOHN DOE');
        expect(
          () => repository.save(c2, ['999999', '789012'], []),
          throwsA(isA<DuplicateContactException>()),
        );
      });
    });

    group('validatePhoneNumber Tests', () {
      final l10n = lookupAppLocalizations(const Locale('en'));

      test('returns null for null or empty/whitespace values', () {
        expect(validatePhoneNumber(l10n, null), isNull);
        expect(validatePhoneNumber(l10n, ''), isNull);
        expect(validatePhoneNumber(l10n, '   '), isNull);
      });

      test('trims leading and trailing spaces', () {
        expect(validatePhoneNumber(l10n, ' 123456 '), isNull);
      });

      test('returns error for invalid characters', () {
        expect(validatePhoneNumber(l10n, '123a456'), l10n.invalidPhoneNumber);
        expect(validatePhoneNumber(l10n, '123*456'), l10n.invalidPhoneNumber);
        expect(validatePhoneNumber(l10n, '123#456'), l10n.invalidPhoneNumber);
        expect(validatePhoneNumber(l10n, '123@456'), l10n.invalidPhoneNumber);
      });

      test('returns error for invalid plus sign usage', () {
        // Multiple plus signs
        expect(validatePhoneNumber(l10n, '+123+456'), l10n.invalidPhoneNumberFormat);
        // Plus sign in the middle
        expect(validatePhoneNumber(l10n, '123+456'), l10n.invalidPhoneNumberFormat);
      });

      test('returns error for invalid parentheses usage', () {
        // Unbalanced open parenthesis
        expect(validatePhoneNumber(l10n, '(123456'), l10n.invalidPhoneNumberFormat);
        // Unbalanced close parenthesis
        expect(validatePhoneNumber(l10n, '123456)'), l10n.invalidPhoneNumberFormat);
        // Multiple pairs
        expect(validatePhoneNumber(l10n, '(123)(456)'), l10n.invalidPhoneNumberFormat);
        // Parentheses out of order
        expect(validatePhoneNumber(l10n, ')123456('), l10n.invalidPhoneNumberFormat);
      });

      test('returns error for consecutive symbols', () {
        // Consecutive spaces
        expect(validatePhoneNumber(l10n, '123  456'), l10n.invalidPhoneNumberFormat);
        // Consecutive dashes
        expect(validatePhoneNumber(l10n, '123--456'), l10n.invalidPhoneNumberFormat);
      });

      test('returns error for invalid start or end characters', () {
        // Starts with dash
        expect(validatePhoneNumber(l10n, '-123456'), l10n.invalidPhoneNumberFormat);
        // Ends with dash or plus
        expect(validatePhoneNumber(l10n, '123456-'), l10n.invalidPhoneNumberFormat);
        expect(validatePhoneNumber(l10n, '123456+'), l10n.invalidPhoneNumberFormat);
      });

      test('returns error when digits count is too short or too long', () {
        // Too short (< 3 digits)
        expect(validatePhoneNumber(l10n, '12'), l10n.phoneNumberTooShort);
        expect(validatePhoneNumber(l10n, '+1'), l10n.phoneNumberTooShort);
        
        // Too long (> 15 digits)
        expect(validatePhoneNumber(l10n, '1234567890123456'), l10n.invalidPhoneNumberFormat);
      });

      test('validates international format using phone_numbers_parser', () {
        // Valid international phone number
        expect(validatePhoneNumber(l10n, '+919876543210'), isNull);
        expect(validatePhoneNumber(l10n, '+14155552671'), isNull);

        // Invalid international phone number
        expect(validatePhoneNumber(l10n, '+911234567'), l10n.invalidPhoneNumberFormat);
        expect(validatePhoneNumber(l10n, '+1111111'), l10n.invalidPhoneNumberFormat);
      });

      test('accepts valid local formats and characters', () {
        expect(validatePhoneNumber(l10n, '12345678'), isNull);
        expect(validatePhoneNumber(l10n, '(123) 456-789'), isNull);
        expect(validatePhoneNumber(l10n, '123-456-7890'), isNull);
      });
    });
  });
}
