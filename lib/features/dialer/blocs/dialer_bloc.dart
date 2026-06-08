import 'dart:async';
import 'package:mechanix_dialer/core/utils/app_logger.dart';
import 'package:mechanix_dialer/core/utils/enums.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_dialer/features/contacts/data/repositories/contacts_repository.dart';
import 'package:mechanix_dialer/features/recents/data/repositories/recent_calls_repository.dart';
import 'package:mechanix_dialer/features/recents/data/models/recent_calls.dart';
import 'dialer_event.dart';
import 'dialer_state.dart';

class DialerBloc extends Bloc<DialerEvent, DialerState> {
  final ContactsRepository contactsRepository;
  final RecentCallsRepository recentCallsRepository;

  Timer? _callTimer;
  Timer? _connectTimer;

  DialerBloc({
    required this.contactsRepository,
    required this.recentCallsRepository,
  }) : super(const DialerState()) {
    on<StartOutgoingCall>(_onStartOutgoingCall);
    on<ReceiveIncomingCall>(_onReceiveIncomingCall);
    on<AcceptCall>(_onAcceptCall);
    on<RejectCall>(_onRejectCall);
    on<EndCall>(_onEndCall);
    on<ToggleMute>(_onToggleMute);
    on<ToggleSpeaker>(_onToggleSpeaker);
    on<TickCallDuration>(_onTickCallDuration);
    on<ClearCallState>(_onClearCallState);
  }

  Future<void> _onStartOutgoingCall(
    StartOutgoingCall event,
    Emitter<DialerState> emit,
  ) async {
    _cancelTimers();
    final matchedName = await _lookupContactName(event.phoneNumber);
    emit(
      state.copyWith(
        callStatus: CallStatus.calling,
        callerNumber: event.phoneNumber,
        callerName: matchedName,
        clearCallerName: matchedName == null,
        callDuration: 0,
        isMuted: false,
        isSpeakerOn: false,
        simNumber: event.simNumber,
      ),
    );

    // Simulate connection after 3 seconds
    _connectTimer = Timer(const Duration(seconds: 3), () {
      add(AcceptCall());
    });
  }

  Future<void> _onReceiveIncomingCall(
    ReceiveIncomingCall event,
    Emitter<DialerState> emit,
  ) async {
    _cancelTimers();
    final matchedName =
        event.callerName ?? await _lookupContactName(event.phoneNumber);
    emit(
      state.copyWith(
        callStatus: CallStatus.incoming,
        callerNumber: event.phoneNumber,
        callerName: matchedName,
        clearCallerName: matchedName == null,
        callDuration: 0,
        isMuted: false,
        isSpeakerOn: false,
        simNumber: event.simNumber,
      ),
    );
  }

  void _onAcceptCall(AcceptCall event, Emitter<DialerState> emit) {
    _connectTimer?.cancel();
    emit(state.copyWith(callStatus: CallStatus.active, callDuration: 0));

    // Start ticking call duration
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      add(TickCallDuration());
    });
  }

  Future<void> _onRejectCall(
    RejectCall event,
    Emitter<DialerState> emit,
  ) async {
    _cancelTimers();
    emit(state.copyWith(callStatus: CallStatus.cancelled));

    // Log the rejected incoming call
    await _saveCallLog(CallType.rejected, 0);

    // Auto clear/return to dial pad after 2 seconds
    _connectTimer = Timer(const Duration(seconds: 2), () {
      add(ClearCallState());
    });
  }

  Future<void> _onEndCall(EndCall event, Emitter<DialerState> emit) async {
    final activeDuration = state.callDuration;
    final previousStatus = state.callStatus;
    _cancelTimers();
    emit(state.copyWith(callStatus: CallStatus.cancelled));

    // Log the call
    final CallType type = previousStatus == CallStatus.calling
        ? CallType
              .outgoing // cancelled before connecting
        : CallType.outgoing;
    await _saveCallLog(type, activeDuration);

    _connectTimer = Timer(const Duration(seconds: 2), () {
      add(ClearCallState());
    });
  }

  void _onToggleMute(ToggleMute event, Emitter<DialerState> emit) {
    emit(state.copyWith(isMuted: !state.isMuted));
  }

  void _onToggleSpeaker(ToggleSpeaker event, Emitter<DialerState> emit) {
    emit(state.copyWith(isSpeakerOn: !state.isSpeakerOn));
  }

  void _onTickCallDuration(TickCallDuration event, Emitter<DialerState> emit) {
    if (state.callStatus == CallStatus.active) {
      emit(state.copyWith(callDuration: state.callDuration + 1));
    }
  }

  void _onClearCallState(ClearCallState event, Emitter<DialerState> emit) {
    _cancelTimers();
    emit(
      state.copyWith(
        callStatus: CallStatus.none,
        callerNumber: '',
        clearCallerName: true,
        callDuration: 0,
        isMuted: false,
        isSpeakerOn: false,
        clearSimNumber: true,
      ),
    );
  }

  void _cancelTimers() {
    _connectTimer?.cancel();
    _callTimer?.cancel();
  }

  Future<void> _saveCallLog(CallType type, int duration) async {
    try {
      final name = state.callerName ?? '';
      final number = state.callerNumber;
      final recentCall = RecentCallEntity(
        name: name,
        phoneNumber: number,
        timestamp: DateTime.now(),
        durationSeconds: duration,
        callTypeIndex: type.index,
        simNumber: state.simNumber,
      );
      recentCallsRepository.add(recentCall);
    } catch (e) {
      // ignore
    }
  }

  Future<String?> _lookupContactName(String number) async {
    if (number.isEmpty) return null;
    try {
      final contacts = await contactsRepository.search(number);
      for (final contact in contacts) {
        for (final phone in contact.phoneNumbers) {
          final cleanPhone = phone.number.replaceAll(RegExp(r'\D'), '');
          final cleanNumber = number.replaceAll(RegExp(r'\D'), '');
          if (cleanPhone == cleanNumber || phone.number == number) {
            return contact.name;
          }
        }
      }
    } catch (e) {
      AppLogger.e('Failed to lookup contact name: $e');
    }
    return null;
  }

  @override
  Future<void> close() {
    _cancelTimers();
    return super.close();
  }
}
