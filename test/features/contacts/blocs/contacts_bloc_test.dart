import 'package:bloc_test/bloc_test.dart';
import 'package:dialer/core/utils/enums.dart';
import 'package:dialer/features/contacts/blocs/contacts_bloc.dart';
import 'package:dialer/features/contacts/blocs/contacts_event.dart';
import 'package:dialer/features/contacts/blocs/contacts_state.dart';
import 'package:dialer/features/contacts/data/models/contacts.dart';
import 'package:dialer/features/contacts/data/repositories/contacts_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockContactsRepository extends Mock implements ContactsRepository {}

class FakeContactEntity extends Fake implements ContactEntity {}

void main() {
  late ContactsBloc bloc;
  late MockContactsRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeContactEntity());
  });

  setUp(() {
    mockRepository = MockContactsRepository();
    bloc = ContactsBloc(mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('ContactsBloc', () {
    final contactsList = [
      ContactEntity(name: 'Alice'),
      ContactEntity(name: 'Bob'),
    ];

    test('initial state is correct', () {
      expect(bloc.state, const ContactsState());
      expect(bloc.state.contacts, isEmpty);
      expect(bloc.state.status, ContactsStatus.initial);
      expect(bloc.state.error, isNull);
    });

    blocTest<ContactsBloc, ContactsState>(
      'emits [loading, loaded] when LoadContacts is added and succeeds',
      build: () {
        when(
          () => mockRepository.getAll(),
        ).thenAnswer((_) async => contactsList);
        return bloc;
      },
      act: (bloc) => bloc.add(LoadContacts()),
      expect: () => [
        const ContactsState(status: ContactsStatus.loading),
        ContactsState(status: ContactsStatus.loaded, contacts: contactsList),
      ],
      verify: (_) {
        verify(() => mockRepository.getAll()).called(1);
      },
    );

    blocTest<ContactsBloc, ContactsState>(
      'emits [loading, error] when LoadContacts is added and fails',
      build: () {
        when(
          () => mockRepository.getAll(),
        ).thenThrow(Exception('Failed to load'));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadContacts()),
      expect: () => [
        const ContactsState(status: ContactsStatus.loading),
        const ContactsState(
          status: ContactsStatus.error,
          error: 'Exception: Failed to load',
        ),
      ],
    );

    blocTest<ContactsBloc, ContactsState>(
      'emits [loading, loaded] when SaveContact is added and succeeds',
      build: () {
        when(
          () => mockRepository.save(any(), any(), any()),
        ).thenAnswer((_) async {});
        when(
          () => mockRepository.getAll(),
        ).thenAnswer((_) async => contactsList);
        return bloc;
      },
      act: (bloc) => bloc.add(
        SaveContact(
          contact: ContactEntity(name: 'Alice'),
          phoneNumbers: const ['12345'],
        ),
      ),
      expect: () => [
        const ContactsState(status: ContactsStatus.loading),
        ContactsState(status: ContactsStatus.loaded, contacts: contactsList),
      ],
      verify: (_) {
        verify(() => mockRepository.save(any(), ['12345'], null)).called(1);
        verify(() => mockRepository.getAll()).called(1);
      },
    );

    blocTest<ContactsBloc, ContactsState>(
      'emits [loading, loaded] when DeleteContact is added and succeeds',
      build: () {
        when(() => mockRepository.delete(any())).thenAnswer((_) async {});
        when(
          () => mockRepository.getAll(),
        ).thenAnswer((_) async => contactsList);
        return bloc;
      },
      act: (bloc) => bloc.add(const DeleteContact(42)),
      expect: () => [
        const ContactsState(status: ContactsStatus.loading),
        ContactsState(status: ContactsStatus.loaded, contacts: contactsList),
      ],
      verify: (_) {
        verify(() => mockRepository.delete(42)).called(1);
        verify(() => mockRepository.getAll()).called(1);
      },
    );

    blocTest<ContactsBloc, ContactsState>(
      'emits [loading, loaded] when SearchContacts is added and succeeds',
      build: () {
        when(
          () => mockRepository.search('alice'),
        ).thenAnswer((_) async => [contactsList.first]);
        return bloc;
      },
      act: (bloc) => bloc.add(const SearchContacts('alice')),
      expect: () => [
        const ContactsState(status: ContactsStatus.loading),
        ContactsState(
          status: ContactsStatus.loaded,
          contacts: [contactsList.first],
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.search('alice')).called(1);
      },
    );
  });
}
