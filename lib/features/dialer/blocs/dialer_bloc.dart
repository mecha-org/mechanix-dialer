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
    try {
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

      _connectTimer = Timer(const Duration(seconds: 3), () {
        add(AcceptCall());
      });
    } catch (e, stackTrace) {
      AppLogger.e('Failed to start outgoing call: $e', stack: stackTrace);
    }
  }

  Future<void> _onReceiveIncomingCall(
    ReceiveIncomingCall event,
    Emitter<DialerState> emit,
  ) async {
    try {
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
    } catch (e, stackTrace) {
      AppLogger.e('Failed to receive incoming call: $e', stack: stackTrace);
    }
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
    try {
      _cancelTimers();

      emit(state.copyWith(callStatus: CallStatus.cancelled));

      await _saveCallLog(CallType.rejected, 0);

      _connectTimer = Timer(const Duration(seconds: 2), () {
        add(ClearCallState());
      });
    } catch (e, stackTrace) {
      AppLogger.e('Failed to reject call: $e', stack: stackTrace);
    }
  }

  Future<void> _onEndCall(EndCall event, Emitter<DialerState> emit) async {
    try {
      final activeDuration = state.callDuration;
      final previousStatus = state.callStatus;

      _cancelTimers();

      emit(state.copyWith(callStatus: CallStatus.cancelled));

      final CallType type = previousStatus == CallStatus.calling
          ? CallType.outgoing
          : CallType.outgoing;

      await _saveCallLog(type, activeDuration);

      _connectTimer = Timer(const Duration(seconds: 2), () {
        add(ClearCallState());
      });
    } catch (e, stackTrace) {
      AppLogger.e('Failed to end call: $e', stack: stackTrace);
    }
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
      final recentCall = RecentCallEntity(
        name: state.callerName ?? '',
        phoneNumber: state.callerNumber,
        timestamp: DateTime.now(),
        durationSeconds: duration,
        callTypeIndex: type.index,
        simNumber: state.simNumber,
      );

      await recentCallsRepository.add(recentCall);
    } catch (e, stackTrace) {
      AppLogger.e('Failed to save call log: $e', stack: stackTrace);
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
    } catch (e, stackTrace) {
      AppLogger.e('Failed to lookup contact name: $e', stack: stackTrace);
    }
    return null;
  }

  @override
  Future<void> close() {
    _cancelTimers();
    return super.close();
  }
}
