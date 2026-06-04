import 'package:dialer/features/contacts/data/models/contacts.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class PhoneNumberEntity {
  @Id()
  int id = 0;

  String number;

  String label;

  final contact = ToOne<ContactEntity>();

  PhoneNumberEntity({required this.number, this.label = 'mobile'});
}
