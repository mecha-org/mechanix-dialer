import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dialer/core/utils/enums.dart';
import 'package:dialer/features/recents/blocs/recent_calls_bloc.dart';
import 'package:dialer/features/recents/blocs/recent_calls_event.dart';
import 'package:dialer/features/recents/blocs/recent_calls_state.dart';
import 'package:dialer/features/recents/data/models/recent_calls.dart';
import 'package:dialer/features/recents/data/repositories/recent_calls_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRecentCallsRepository extends Mock implements RecentCallsRepository {}

void main() {
  late RecentCallsBloc bloc;
  late MockRecentCallsRepository mockRepository;

  setUp(() {
    mockRepository = MockRecentCallsRepository();
    bloc = RecentCallsBloc(mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('RecentCallsBloc', () {
    final now = DateTime.now();
    final call1 = RecentCallEntity(
      name: 'Alice',
      phoneNumber: '123',
      timestamp: now,
      durationSeconds: 10,
    );
    final call2 = RecentCallEntity(
      name: 'Bob',
      phoneNumber: '456',
      timestamp: now.subtract(const Duration(minutes: 5)),
      durationSeconds: 20,
    );

    test('initial state is correct', () {
      expect(bloc.state, const RecentCallsState());
      expect(bloc.state.calls, isEmpty);
      expect(bloc.state.status, RecentCallsStatus.initial);
    });

    blocTest<RecentCallsBloc, RecentCallsState>(
      'emits correct states when LoadRecentCalls is added and succeeds',
      build: () {
        when(() => mockRepository.watchAll(limit: 1)).thenAnswer((_) => const Stream.empty());
        when(() => mockRepository.getPaged(offset: 0, limit: 30)).thenAnswer((_) async => [call1, call2]);
        return bloc;
      },
      act: (bloc) => bloc.add(LoadRecentCalls()),
      expect: () => [
        const RecentCallsState(status: RecentCallsStatus.loading, filter: CallFilter.all),
        RecentCallsState(
          status: RecentCallsStatus.loaded,
          calls: [call1, call2],
          lastTimestamp: call2.timestamp,
          hasReachedMax: true, // 2 items is less than pageLimit (30)
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.watchAll(limit: 1)).called(1);
        verify(() => mockRepository.getPaged(offset: 0, limit: 30)).called(1);
      },
    );

    blocTest<RecentCallsBloc, RecentCallsState>(
      'emits correct states when LoadRecentCalls fails',
      build: () {
        when(() => mockRepository.watchAll(limit: 1)).thenAnswer((_) => const Stream.empty());
        when(() => mockRepository.getPaged(offset: 0, limit: 30)).thenThrow(Exception('DB Error'));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadRecentCalls()),
      expect: () => [
        const RecentCallsState(status: RecentCallsStatus.loading, filter: CallFilter.all),
        const RecentCallsState(status: RecentCallsStatus.error, error: 'Exception: DB Error'),
      ],
    );

    blocTest<RecentCallsBloc, RecentCallsState>(
      'emits updated calls when RecentCallsUpdated is added',
      build: () {
        when(() => mockRepository.getPaged(offset: 0, limit: 30)).thenAnswer((_) async => [call1]);
        return bloc;
      },
      act: (bloc) => bloc.add(RecentCallsUpdated([call1])),
      expect: () => [
        RecentCallsState(
          calls: [call1],
          lastTimestamp: call1.timestamp,
          hasReachedMax: true,
        ),
      ],
    );

    blocTest<RecentCallsBloc, RecentCallsState>(
      'emits missed calls when LoadMissedCalls is added and succeeds',
      build: () {
        when(() => mockRepository.watchAll()).thenAnswer((_) => const Stream.empty());
        when(() => mockRepository.getMissedCalls()).thenAnswer((_) async => [call1]);
        return bloc;
      },
      act: (bloc) => bloc.add(LoadMissedCalls()),
      expect: () => [
        const RecentCallsState(status: RecentCallsStatus.loading, filter: CallFilter.missed),
        RecentCallsState(
          status: RecentCallsStatus.loaded,
          calls: [call1],
          filter: CallFilter.missed,
          hasReachedMax: true,
        ),
      ],
    );

    blocTest<RecentCallsBloc, RecentCallsState>(
      'appends more calls when LoadMoreRecentCalls is added',
      build: () {
        when(() => mockRepository.getBefore(lastTimestamp: any(named: 'lastTimestamp'), limit: 30))
            .thenAnswer((_) async => [call2]);
        return bloc;
      },
      seed: () => RecentCallsState(
        status: RecentCallsStatus.loaded,
        calls: [call1],
        lastTimestamp: call1.timestamp,
        hasReachedMax: false,
      ),
      act: (bloc) => bloc.add(LoadMoreRecentCalls()),
      expect: () => [
        RecentCallsState(
          status: RecentCallsStatus.loaded,
          calls: [call1],
          lastTimestamp: call1.timestamp,
          loadingMore: true,
        ),
        RecentCallsState(
          status: RecentCallsStatus.loaded,
          calls: [call1, call2],
          lastTimestamp: call2.timestamp,
          loadingMore: false,
          hasReachedMax: true,
        ),
      ],
    );

    blocTest<RecentCallsBloc, RecentCallsState>(
      'emits filtered calls when SearchRecentCalls is added with query',
      build: () {
        when(() => mockRepository.search('alice')).thenAnswer((_) async => [call1]);
        return bloc;
      },
      act: (bloc) => bloc.add(SearchRecentCalls('alice')),
      expect: () => [
        const RecentCallsState(status: RecentCallsStatus.loading),
        RecentCallsState(
          status: RecentCallsStatus.loaded,
          calls: [call1],
          hasReachedMax: true,
        ),
      ],
    );
  });
}
