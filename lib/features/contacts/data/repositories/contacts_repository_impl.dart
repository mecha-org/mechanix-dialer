import 'package:mechanix_dialer/core/utils/app_logger.dart';
import 'package:mechanix_contacts/mechanix_contacts.dart';

import 'contacts_repository.dart';

class ContactsRepositoryImpl implements ContactsRepository {
  /// Optional ObjectBox store used for testing.
  /// When provided, all repository operations use this store instead of the
  /// shared [ContactsStoreService] store.
  final Store? store;

  ContactsRepositoryImpl({this.store});

  /// Returns the active ObjectBox store.
  /// Uses the injected [store] when available; otherwise falls back to the
  /// shared store managed by [ContactsStoreService].
  Store get _dbStore => store ?? ContactsStoreService.store;
  Box<ContactEntity> get _contacts => _dbStore.box<ContactEntity>();
  Box<PhoneNumberEntity> get _phoneNumbers => _dbStore.box<PhoneNumberEntity>();
  Box<EmailEntity> get _emails => _dbStore.box<EmailEntity>();
  Box<SimCardEntity> get _sims => _dbStore.box<SimCardEntity>();

  /// Ensures the shared contacts store is initialized before performing
  /// repository operations.
  /// This is skipped when a test store is injected through the constructor.
  Future<void> _ensureConnected() async {
    try {
      if (store == null) {
        await ContactsStoreService.ensureConnected();
      }
    } catch (e, stackTrace) {
      AppLogger.e('Failed to connect to contacts store: $e', stack: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<ContactEntity>> getAll() async {
    try {
      await _ensureConnected();

      final query = _contacts.query().order(ContactEntity_.name).build();

      try {
        return query.find();
      } finally {
        query.close();
      }
    } catch (e, stackTrace) {
      AppLogger.e('Failed to get contacts: $e', stack: stackTrace);
      rethrow;
    }
  }

  @override
  Future<ContactEntity?> getById(int id) async {
    try {
      await _ensureConnected();
      return _contacts.get(id);
    } catch (e, stackTrace) {
      AppLogger.e('Failed to get contact by id $id: $e', stack: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> save(
    ContactEntity contact,
    List<String> numbers,
    List<String>? emails,
  ) async {
    try {
      await _ensureConnected();

      _dbStore.runInTransaction(TxMode.write, () {
        // Check for duplicates: same name (case-insensitive) and same number (digits only match)
        final sameNameContacts = _contacts
            .query(
              ContactEntity_.name.equals(contact.name, caseSensitive: false),
            )
            .build()
            .find();

        final otherContacts = sameNameContacts
            .where((c) => c.id != contact.id)
            .toList();

        if (otherContacts.isNotEmpty) {
          final otherContactIds = otherContacts.map((c) => c.id).toList();
          final builder = _phoneNumbers.query();

          builder.link(
            PhoneNumberEntity_.contact,
            ContactEntity_.id.oneOf(otherContactIds),
          );

          final matchingPhoneNumbers = builder.build().find();

          final newNumbersNormalized = numbers
              .map((n) => n.replaceAll(RegExp(r'\D'), ''))
              .where((n) => n.isNotEmpty)
              .toSet();

          for (final existingPhone in matchingPhoneNumbers) {
            final existingNormalized = existingPhone.number.replaceAll(
              RegExp(r'\D'),
              '',
            );
            if (newNumbersNormalized.contains(existingNormalized)) {
              throw DuplicateContactException();
            }
          }
        }

        if (contact.id != 0) {
          final existingNumbers = _phoneNumbers
              .query(PhoneNumberEntity_.contact.equals(contact.id))
              .build()
              .find();

          _phoneNumbers.removeMany(existingNumbers.map((n) => n.id).toList());

          final existingEmails = _emails
              .query(EmailEntity_.contact.equals(contact.id))
              .build()
              .find();

          _emails.removeMany(existingEmails.map((e) => e.id).toList());
        }

        _contacts.put(contact);

        for (final numStr in numbers) {
          if (numStr.trim().isEmpty) continue;

          final phone = PhoneNumberEntity(number: numStr.trim());
          phone.contact.target = contact;

          _phoneNumbers.put(phone);
        }

        final uniqueEmails = (emails ?? [])
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet();

        for (final emailStr in uniqueEmails) {
          final email = EmailEntity(email: emailStr);
          email.contact.target = contact;

          _emails.put(email);
        }
      });
    } catch (e, stackTrace) {
      AppLogger.e('Failed to save contact: $e', stack: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      await _ensureConnected();

      _dbStore.runInTransaction(TxMode.write, () {
        final existingNumbers = _phoneNumbers
            .query(PhoneNumberEntity_.contact.equals(id))
            .build()
            .find();

        _phoneNumbers.removeMany(existingNumbers.map((n) => n.id).toList());

        final existingEmails = _emails
            .query(EmailEntity_.contact.equals(id))
            .build()
            .find();

        _emails.removeMany(existingEmails.map((e) => e.id).toList());

        _contacts.remove(id);
      });
    } catch (e, stackTrace) {
      AppLogger.e('Failed to delete contact $id: $e', stack: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<ContactEntity>> search(String queryStr) async {
    try {
      await _ensureConnected();

      if (queryStr.trim().isEmpty) {
        return getAll();
      }

      final matchingPhoneNumbers = _phoneNumbers
          .query(PhoneNumberEntity_.number.contains(queryStr))
          .build()
          .find();

      final contactIdsFromNumbers = matchingPhoneNumbers
          .map((p) => p.contact.targetId)
          .where((id) => id != 0)
          .toSet();

      final Condition<ContactEntity> condition;

      if (contactIdsFromNumbers.isNotEmpty) {
        condition = ContactEntity_.name
            .contains(queryStr, caseSensitive: false)
            .or(ContactEntity_.id.oneOf(contactIdsFromNumbers.toList()));
      } else {
        condition = ContactEntity_.name.contains(
          queryStr,
          caseSensitive: false,
        );
      }

      final query = _contacts
          .query(condition)
          .order(ContactEntity_.name)
          .build();

      try {
        return query.find();
      } finally {
        query.close();
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to search contacts with query "$queryStr": $e',
        stack: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<List<SimCardEntity>> getSimCards() async {
    try {
      await _ensureConnected();

      final count = _sims.count();

      if (count == 0) {
        // TODO: Remove this once SIM data comes from system APIs
        _dbStore.runInTransaction(TxMode.write, () {
          _sims.put(
            SimCardEntity(slot: '1', name: 'Primary', number: '01-554738'),
          );

          _sims.put(
            SimCardEntity(slot: '2', name: 'Secondary', number: '01-626262'),
          );
        });
      }

      return _sims.getAll();
    } catch (e, stackTrace) {
      AppLogger.e('Failed to get SIM cards: $e', stack: stackTrace);
      rethrow;
    }
  }
}
