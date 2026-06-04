import 'dart:io';

import 'package:dialer/core/exceptions/app_exception.dart';
import 'package:dialer/core/utils/app_logger.dart';
import 'package:dialer/features/contacts/data/models/contacts.dart';
import 'package:dialer/features/contacts/data/models/email.dart';
import 'package:dialer/features/contacts/data/models/phone_numbers.dart';
import 'package:dialer/objectbox.g.dart';
import 'contacts_repository.dart';

class ContactsRepositoryImpl implements ContactsRepository {
  Store? _store;
  Box<ContactEntity>? _box;
  Box<PhoneNumberEntity>? _phoneNumberBox;
  Box<EmailEntity>? _emailBox;
  Future<void>? _initFuture;

  ContactsRepositoryImpl({Store? store}) : _store = store {
    if (store != null) {
      _box = store.box<ContactEntity>();
      _phoneNumberBox = store.box<PhoneNumberEntity>();
      _emailBox = store.box<EmailEntity>();
    }
  }

  Future<void> ensureStoreConnected() async {
    if (_store != null && !_store!.isClosed()) {
      return;
    }

    if (_initFuture != null) {
      await _initFuture;
      return;
    }

    try {
      _initFuture = _initializeStore();
      await _initFuture;
    } catch (e) {
      AppLogger.e('Failed to open ObjectBox store for contacts: $e');
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
      final appDir = Directory('$home/.config/mechanix_contacts/objectbox');
      final exists = await appDir.exists();

      if (!exists) {
        await appDir.create(recursive: true);
      }

      _store = openStore(directory: appDir.path);
      _box = _store!.box<ContactEntity>();
      _phoneNumberBox = _store!.box<PhoneNumberEntity>();
      _emailBox = _store!.box<EmailEntity>();

      AppLogger.i(
        '[ContactsRepository] ObjectBox store opened at ${appDir.path}',
      );
    } catch (e) {
      AppLogger.e('Failed to initialize ObjectBox store for contacts: $e');
      rethrow;
    }
  }

  void closeStore() {
    _store?.close();
    _store = null;
    _box = null;
    _phoneNumberBox = null;
  }

  @override
  Future<List<ContactEntity>> getAll() async {
    await ensureStoreConnected();
    final query = _box!.query().order(ContactEntity_.name).build();

    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  @override
  Future<ContactEntity?> getById(int id) async {
    await ensureStoreConnected();
    return _box!.get(id);
  }

  @override
  Future<void> save(
    ContactEntity contact,
    List<String> numbers,
    List<String>? emails,
  ) async {
    await ensureStoreConnected();

    _store!.runInTransaction(TxMode.write, () {
      // If editing, clear existing numbers, emails of this contact first
      if (contact.id != 0) {
        final existingNumbers = _phoneNumberBox!
            .query(PhoneNumberEntity_.contact.equals(contact.id))
            .build()
            .find();
        _phoneNumberBox!.removeMany(existingNumbers.map((n) => n.id).toList());

        final existingEmails = _emailBox!
            .query(EmailEntity_.contact.equals(contact.id))
            .build()
            .find();
        _emailBox!.removeMany(existingEmails.map((e) => e.id).toList());
      }

      // Save contact first to get an ID
      _box!.put(contact);

      // Save new phone numbers
      for (final numStr in numbers) {
        if (numStr.trim().isEmpty) continue;
        final phone = PhoneNumberEntity(number: numStr.trim());
        phone.contact.target = contact;
        _phoneNumberBox!.put(phone);
      }

      final uniqueEmails = (emails ?? [])
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();

      for (final emailStr in uniqueEmails) {
        final email = EmailEntity(email: emailStr);
        email.contact.target = contact;
        _emailBox!.put(email);
      }
    });
  }

  @override
  Future<void> delete(int id) async {
    await ensureStoreConnected();
    _store!.runInTransaction(TxMode.write, () {
      // Remove all phone numbers, emails for this contact first
      final existingNumbers = _phoneNumberBox!
          .query(PhoneNumberEntity_.contact.equals(id))
          .build()
          .find();
      _phoneNumberBox!.removeMany(existingNumbers.map((n) => n.id).toList());

      final existingEmails = _emailBox!
          .query(EmailEntity_.contact.equals(id))
          .build()
          .find();
      _emailBox!.removeMany(existingEmails.map((e) => e.id).toList());
      // Then remove the contact
      _box!.remove(id);
    });
  }

  @override
  Future<List<ContactEntity>> search(String queryStr) async {
    await ensureStoreConnected();

    if (queryStr.trim().isEmpty) {
      return getAll();
    }

    // Find all contact IDs that have matching phone numbers
    final matchingPhoneNumbers = _phoneNumberBox!
        .query(PhoneNumberEntity_.number.contains(queryStr))
        .build()
        .find();
    final contactIdsFromNumbers = matchingPhoneNumbers
        .map((p) => p.contact.targetId)
        .where((id) => id != 0)
        .toSet();

    // Find all contacts that match name OR have matching phone numbers
    final Condition<ContactEntity> cond;
    if (contactIdsFromNumbers.isNotEmpty) {
      cond = ContactEntity_.name
          .contains(queryStr, caseSensitive: false)
          .or(ContactEntity_.id.oneOf(contactIdsFromNumbers.toList()));
    } else {
      cond = ContactEntity_.name.contains(queryStr, caseSensitive: false);
    }

    final query = _box!.query(cond).order(ContactEntity_.name).build();

    try {
      return query.find();
    } finally {
      query.close();
    }
  }
}
