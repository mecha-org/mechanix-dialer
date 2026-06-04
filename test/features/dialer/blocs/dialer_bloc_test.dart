import 'package:bloc_test/bloc_test.dart';
import 'package:dialer/core/utils/enums.dart';
import 'package:dialer/features/contacts/data/models/contacts.dart';
import 'package:dialer/features/contacts/data/models/phone_numbers.dart';
import 'package:dialer/features/contacts/data/repositories/contacts_repository.dart';
import 'package:dialer/features/dialer/blocs/dialer_bloc.dart';
import 'package:dialer/features/dialer/blocs/dialer_event.dart';
import 'package:dialer/features/dialer/blocs/dialer_state.dart';
import 'package:dialer/features/recents/data/models/recent_calls.dart';
import 'package:dialer/features/recents/data/repositories/recent_calls_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockContactsRepository extends Mock implements ContactsRepository {}

class MockRecentCallsRepository extends Mock implements RecentCallsRepository {}

class FakeRecentCallEntity extends Fake implements RecentCallEntity {}

class FakeContactEntity extends Fake implements ContactEntity {}

void main() {
  late DialerBloc bloc;
  late MockContactsRepository mockContactsRepo;
  late MockRecentCallsRepository mockRecentCallsRepo;

  setUpAll(() {
    registerFallbackValue(FakeRecentCallEntity());
    registerFallbackValue(FakeContactEntity());
  });

  setUp(() {
    mockContactsRepo = MockContactsRepository();
    mockRecentCallsRepo = MockRecentCallsRepository();

    bloc = DialerBloc(
      contactsRepository: mockContactsRepo,
      recentCallsRepository: mockRecentCallsRepo,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('DialerBloc', () {
    test('initial state is correct', () {
      expect(bloc.state, const DialerState());
      expect(bloc.state.callStatus, CallStatus.none);
      expect(bloc.state.callerNumber, '');
      expect(bloc.state.callerName, isNull);
      expect(bloc.state.callDuration, 0);
      expect(bloc.state.isMuted, false);
      expect(bloc.state.isSpeakerOn, false);
    });

    blocTest<DialerBloc, DialerState>(
      'emits calling state with matched contact name on StartOutgoingCall',
      build: () {
        final contact = ContactEntity(name: 'John Doe');
        contact.phoneNumbers.add(PhoneNumberEntity(number: '12345'));

        when(
          () => mockContactsRepo.search('12345'),
        ).thenAnswer((_) async => [contact]);

        return bloc;
      },
      act: (bloc) => bloc.add(StartOutgoingCall('12345')),
      expect: () => [
        const DialerState(
          callStatus: CallStatus.calling,
          callerNumber: '12345',
          callerName: 'John Doe',
        ),
      ],
    );

    blocTest<DialerBloc, DialerState>(
      'auto connects after 3 seconds',
      build: () {
        when(
          () => mockContactsRepo.search('12345'),
        ).thenAnswer((_) async => []);

        return bloc;
      },
      act: (bloc) => bloc.add(StartOutgoingCall('12345')),
      wait: const Duration(seconds: 3),
      verify: (bloc) {
        expect(bloc.state.callStatus, CallStatus.active);
        expect(bloc.state.callerNumber, '12345');
      },
    );

    blocTest<DialerBloc, DialerState>(
      'emits incoming state with matched contact name',
      build: () {
        final contact = ContactEntity(name: 'Jane Smith');
        contact.phoneNumbers.add(PhoneNumberEntity(number: '98765'));

        when(
          () => mockContactsRepo.search('98765'),
        ).thenAnswer((_) async => [contact]);

        return bloc;
      },
      act: (bloc) {
        bloc.add(ReceiveIncomingCall(phoneNumber: '98765'));
      },
      expect: () => [
        const DialerState(
          callStatus: CallStatus.incoming,
          callerNumber: '98765',
          callerName: 'Jane Smith',
        ),
      ],
    );

    blocTest<DialerBloc, DialerState>(
      'AcceptCall activates call',
      build: () => bloc,
      act: (bloc) => bloc.add(AcceptCall()),
      expect: () => [const DialerState(callStatus: CallStatus.active)],
    );

    blocTest<DialerBloc, DialerState>(
      'AcceptCall starts duration timer',
      build: () => bloc,
      act: (bloc) => bloc.add(AcceptCall()),
      wait: const Duration(seconds: 3),
      verify: (bloc) {
        expect(bloc.state.callStatus, CallStatus.active);
        expect(bloc.state.callDuration, 3);
      },
    );

    blocTest<DialerBloc, DialerState>(
      'RejectCall logs call and clears state after timeout',
      build: () {
        when(() => mockRecentCallsRepo.add(any())).thenAnswer((_) async {});

        return bloc;
      },
      act: (bloc) => bloc.add(RejectCall()),
      wait: const Duration(seconds: 2),
      verify: (_) {
        verify(() => mockRecentCallsRepo.add(any())).called(1);
      },
    );

    blocTest<DialerBloc, DialerState>(
      'EndCall logs call and clears state after timeout',
      build: () {
        when(() => mockRecentCallsRepo.add(any())).thenAnswer((_) async {});

        return bloc;
      },
      act: (bloc) => bloc.add(EndCall()),
      wait: const Duration(seconds: 2),
      verify: (_) {
        verify(() => mockRecentCallsRepo.add(any())).called(1);
      },
    );

    blocTest<DialerBloc, DialerState>(
      'ToggleMute toggles mute status',
      build: () => bloc,
      act: (bloc) => bloc.add(ToggleMute()),
      expect: () => [const DialerState(isMuted: true)],
    );

    blocTest<DialerBloc, DialerState>(
      'ToggleSpeaker toggles speaker status',
      build: () => bloc,
      act: (bloc) => bloc.add(ToggleSpeaker()),
      expect: () => [const DialerState(isSpeakerOn: true)],
    );

    blocTest<DialerBloc, DialerState>(
      'TickCallDuration increments duration when call is active',
      build: () => bloc,
      seed: () =>
          const DialerState(callStatus: CallStatus.active, callDuration: 1),
      act: (bloc) => bloc.add(TickCallDuration()),
      expect: () => [
        const DialerState(callStatus: CallStatus.active, callDuration: 2),
      ],
    );

    blocTest<DialerBloc, DialerState>(
      'ClearCallState resets all fields',
      build: () => bloc,
      seed: () => const DialerState(
        callStatus: CallStatus.active,
        callerNumber: '1234',
        callerName: 'Jane',
        callDuration: 120,
        isMuted: true,
        isSpeakerOn: true,
      ),
      act: (bloc) => bloc.add(ClearCallState()),
      expect: () => [const DialerState()],
    );
  });
}
