abstract class DialerEvent {}

class StartOutgoingCall extends DialerEvent {
  final String phoneNumber;
  final String? simNumber;
  StartOutgoingCall(this.phoneNumber, {this.simNumber});
}

class ReceiveIncomingCall extends DialerEvent {
  final String phoneNumber;
  final String? callerName;
  final String? simNumber;
  ReceiveIncomingCall({required this.phoneNumber, this.callerName, this.simNumber});
}

class AcceptCall extends DialerEvent {}

class RejectCall extends DialerEvent {}

class EndCall extends DialerEvent {}

class ToggleMute extends DialerEvent {}

class ToggleSpeaker extends DialerEvent {}

class TickCallDuration extends DialerEvent {}

class ClearCallState extends DialerEvent {}
