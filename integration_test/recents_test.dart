import 'dart:io';
import 'package:mechanix_dialer/core/constants/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mechanix_dialer/main.dart';
import 'package:mechanix_dialer/features/recents/presentation/screens/recent_calls_screen.dart';
import 'package:mechanix_dialer/features/recents/presentation/screens/recent_call_info_screen.dart';
import 'package:mechanix_dialer/features/recents/data/models/recent_calls.dart';
import 'package:mechanix_dialer/features/recents/data/repositories/recent_calls_repository.dart';
import 'package:mechanix_dialer/features/recents/data/repositories/recent_calls_repository_impl.dart';
import 'package:mechanix_dialer/features/contacts/data/repositories/contacts_repository.dart';
import 'package:mechanix_dialer/features/contacts/data/repositories/contacts_repository_impl.dart';
import 'package:mechanix_dialer/features/dialer/blocs/dialer_bloc.dart';
import 'package:mechanix_dialer/features/recents/blocs/recent_calls_bloc.dart';
import 'package:mechanix_dialer/features/contacts/blocs/contacts_bloc.dart';
import 'package:mechanix_dialer/objectbox.g.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Recent Calls Feature Integration Tests', () {
    late Directory contactsTempDir;
    late Directory recentsTempDir;
    late Store contactsStore;
    late Store recentsStore;

    setUp(() async {
      contactsTempDir = await Directory.systemTemp.createTemp('contacts_test_');
      recentsTempDir = await Directory.systemTemp.createTemp('recents_test_');

      contactsStore = openStore(directory: contactsTempDir.path);
      recentsStore = openStore(directory: recentsTempDir.path);

      // Seed mock recent calls:
      // Outgoing call to Alice
      final box = recentsStore.box<RecentCallEntity>();
      final c1 = RecentCallEntity(
        name: 'Alice',
        phoneNumber: '123456789',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        durationSeconds: 45,
        callTypeIndex: 1, // outgoing
      );

      // Missed call from Bob
      final c2 = RecentCallEntity(
        name: 'Bob',
        phoneNumber: '987654321',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        durationSeconds: 0,
        callTypeIndex: 2, // missed
      );

      box.putMany([c1, c2]);
    });

    tearDown(() async {
      contactsStore.close();
      recentsStore.close();
      if (await contactsTempDir.exists()) {
        await contactsTempDir.delete(recursive: true);
      }
      if (await recentsTempDir.exists()) {
        await recentsTempDir.delete(recursive: true);
      }
    });

    Widget createTestApp() {
      final contactsRepo = ContactsRepositoryImpl(store: contactsStore);
      final recentsRepo = RecentCallsRepositoryImpl(store: recentsStore);

      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider<RecentCallsRepository>.value(value: recentsRepo),
          RepositoryProvider<ContactsRepository>.value(value: contactsRepo),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => DialerBloc(
                contactsRepository: context.read<ContactsRepository>(),
                recentCallsRepository: context.read<RecentCallsRepository>(),
              ),
            ),
            BlocProvider(
              create: (context) =>
                  RecentCallsBloc(context.read<RecentCallsRepository>()),
            ),
            BlocProvider(
              create: (context) =>
                  ContactsBloc(context.read<ContactsRepository>()),
            ),
          ],
          child: const DialerApp(),
        ),
      );
    }

    Finder findImageByAsset(String assetPath) {
      return find.byWidgetPredicate((widget) {
        if (widget is! Image) return false;
        final imageProvider = widget.image;
        return imageProvider is AssetImage &&
            imageProvider.assetName == assetPath;
      });
    }

    testWidgets(
      'Verify recents listing, missed filtering, call log search, and info page details',
      (WidgetTester tester) async {
        // 1. Launch the app
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Verify RecentCallsScreen is shown (should be default tab: index 0)
        expect(find.byType(RecentCallsScreen), findsOneWidget);

        // Verify Alice and Bob are in the list
        expect(find.widgetWithText(ListTile, 'Alice'), findsOneWidget);
        expect(find.widgetWithText(ListTile, 'Bob'), findsOneWidget);

        // 2. Test Filtering: Missed calls
        final missedFilterBtn = find.text('Missed');
        expect(missedFilterBtn, findsOneWidget);
        await tester.tap(missedFilterBtn);
        await tester.pumpAndSettle();

        // Bob (missed) should be present, Alice (outgoing) should be hidden
        expect(find.widgetWithText(ListTile, 'Bob'), findsOneWidget);
        expect(find.widgetWithText(ListTile, 'Alice'), findsNothing);

        // Change filter back to All
        final allFilterBtn = find.text('All');
        expect(allFilterBtn, findsOneWidget);
        await tester.tap(allFilterBtn);
        await tester.pumpAndSettle();

        expect(find.widgetWithText(ListTile, 'Alice'), findsOneWidget);
        expect(find.widgetWithText(ListTile, 'Bob'), findsOneWidget);

        // 3. Test Searching
        final searchField = find.widgetWithText(
          TextField,
          'Search in call log',
        );
        expect(searchField, findsOneWidget);

        // Search query 'Alice'
        await tester.enterText(searchField, 'Alice');
        await tester.pumpAndSettle();

        // Alice should be shown, Bob should be hidden
        expect(find.widgetWithText(ListTile, 'Alice'), findsOneWidget);
        expect(find.widgetWithText(ListTile, 'Bob'), findsNothing);

        // Clear search
        await tester.enterText(searchField, '');
        await tester.pumpAndSettle();

        expect(find.widgetWithText(ListTile, 'Alice'), findsOneWidget);
        expect(find.widgetWithText(ListTile, 'Bob'), findsOneWidget);

        // 4. Test View Info Screen
        // Tap on Alice call item
        await tester.tap(find.widgetWithText(ListTile, 'Alice'));
        await tester.pumpAndSettle();

        // Verify RecentCallsInfoScreen is opened
        expect(find.byType(RecentCallsInfoScreen), findsOneWidget);
        expect(find.text('Alice'), findsOneWidget);
        expect(find.text('123456789'), findsAtLeastNWidgets(1));

        // Go back
        final backBtn = findImageByAsset(AppIcons.back);
        expect(backBtn, findsOneWidget);
        await tester.tap(backBtn);
        await tester.pumpAndSettle();

        expect(find.byType(RecentCallsInfoScreen), findsNothing);
        expect(find.byType(RecentCallsScreen), findsOneWidget);
      },
    );
  });
}
