import 'package:mechanix_dialer/core/utils/enums.dart';
import 'package:equatable/equatable.dart';

class DialerState extends Equatable {
  final CallStatus callStatus;
  final String callerNumber;
  final String? callerName;
  final int callDuration;
  final bool isMuted;
  final bool isSpeakerOn;
  final String? simNumber;

  const DialerState({
    this.callStatus = CallStatus.none,
    this.callerNumber = '',
    this.callerName,
    this.callDuration = 0,
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.simNumber,
  });

  DialerState copyWith({
    CallStatus? callStatus,
    String? callerNumber,
    String? callerName,
    int? callDuration,
    bool? isMuted,
    bool? isSpeakerOn,
    String? simNumber,
    bool clearCallerName = false,
    bool clearSimNumber = false,
  }) {
    return DialerState(
      callStatus: callStatus ?? this.callStatus,
      callerNumber: callerNumber ?? this.callerNumber,
      callerName: clearCallerName ? null : (callerName ?? this.callerName),
      callDuration: callDuration ?? this.callDuration,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      simNumber: clearSimNumber ? null : (simNumber ?? this.simNumber),
    );
  }

  @override
  List<Object?> get props => [
    callStatus,
    callerNumber,
    callerName,
    callDuration,
    isMuted,
    isSpeakerOn,
    simNumber,
  ];
}
