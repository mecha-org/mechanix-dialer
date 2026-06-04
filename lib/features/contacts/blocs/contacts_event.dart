import 'package:dialer/features/contacts/data/models/contacts.dart';
import 'package:equatable/equatable.dart';

abstract class ContactsEvent extends Equatable {
  const ContactsEvent();

  @override
  List<Object?> get props => [];
}

class LoadContacts extends ContactsEvent {}

class SaveContact extends ContactsEvent {
  final ContactEntity contact;
  final List<String> phoneNumbers;
  final List<String>? emails;

  const SaveContact({
    required this.contact,
    required this.phoneNumbers,
    this.emails,
  });

  @override
  List<Object?> get props => [contact, phoneNumbers];
}

class DeleteContact extends ContactsEvent {
  final int id;

  const DeleteContact(this.id);

  @override
  List<Object?> get props => [id];
}

class SearchContacts extends ContactsEvent {
  final String query;

  const SearchContacts(this.query);

  @override
  List<Object?> get props => [query];
}
