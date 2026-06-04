import 'package:objectbox/objectbox.dart';
import 'contacts.dart';

@Entity()
class EmailEntity {
  @Id()
  int id = 0;

  String email;

  String label;

  final contact = ToOne<ContactEntity>();

  EmailEntity({required this.email, this.label = 'Home'});
}
