import 'package:dialer/core/utils/enums.dart';
import 'package:dialer/features/contacts/data/models/contacts.dart';
import 'package:equatable/equatable.dart';

class ContactsState extends Equatable {
  final List<ContactEntity> contacts;
  final ContactsStatus status;
  final String? error;

  const ContactsState({
    this.contacts = const [],
    this.status = ContactsStatus.initial,
    this.error,
  });

  ContactsState copyWith({
    List<ContactEntity>? contacts,
    ContactsStatus? status,
    String? error,
  }) {
    return ContactsState(
      contacts: contacts ?? this.contacts,
      status: status ?? this.status,
      error: error,
    );
  }

  @override
  List<Object?> get props => [contacts, status, error];
}
