import 'package:dialer/core/utils/enums.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class RecentCallEntity {
  @Id()
  int id = 0;

  String name;

  String phoneNumber;

  DateTime timestamp;

  int durationSeconds;

  int callTypeIndex;

  String? simNumber;

  RecentCallEntity({
    required this.name,
    required this.phoneNumber,
    required this.timestamp,
    required this.durationSeconds,
    this.callTypeIndex = 0,
    this.simNumber,
  });

  /// App-facing enum getter
  CallType get callType => CallType.values[callTypeIndex];

  /// App-facing enum setter
  set callType(CallType type) {
    callTypeIndex = type.index;
  }
}
