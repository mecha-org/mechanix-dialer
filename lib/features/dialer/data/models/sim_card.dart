import 'package:objectbox/objectbox.dart';

@Entity()
class SimCardEntity {
  @Id()
  int id = 0;

  String slot;
  String name;
  String number;

  SimCardEntity({
    this.id = 0,
    required this.slot,
    required this.name,
    required this.number,
  });
}
