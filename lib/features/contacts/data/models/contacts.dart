import 'package:dialer/features/contacts/data/models/email.dart';
import 'package:dialer/features/contacts/data/models/phone_numbers.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class ContactEntity {
  @Id()
  int id = 0;

  /// Contact display name.
  String name;

  /// Whether the contact is marked as a favorite.
  bool favorite;

  /// Reverse relation to all phone numbers linked to this contact.
  ///
  /// ObjectBox automatically populates this collection based on the
  /// `PhoneNumberEntity.contact` ToOne relationship.
  /// No manual management of this list is required.
  @Backlink()
  final phoneNumbers = ToMany<PhoneNumberEntity>();

  @Backlink()
  final emails = ToMany<EmailEntity>();

  ContactEntity({required this.name, this.favorite = false});
}
