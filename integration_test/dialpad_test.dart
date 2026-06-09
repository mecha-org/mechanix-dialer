import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mechanix_dialer/main.dart';
import 'package:mechanix_dialer/core/constants/icons.dart';
import 'package:mechanix_dialer/features/dialer/presentation/widgets/dial_button.dart';
import 'package:mechanix_dialer/features/dialer/presentation/screens/dialer_screen.dart';
import 'package:mechanix_dialer/features/dialer/presentation/screens/call_screen.dart';
import 'package:mechanix_dialer/features/contacts/presentation/screens/contact_form_screen.dart';
import 'package:mechanix_dialer/features/contacts/data/repositories/contacts_repository.dart';
import 'package:mechanix_dialer/features/contacts/data/repositories/contacts_repository_impl.dart';
import 'package:mechanix_dialer/features/recents/data/repositories/recent_calls_repository.dart';
import 'package:mechanix_dialer/features/recents/data/repositories/recent_calls_repository_impl.dart';
import 'package:mechanix_dialer/features/dialer/blocs/dialer_bloc.dart';
import 'package:mechanix_dialer/features/recents/blocs/recent_calls_bloc.dart';
import 'package:mechanix_dialer/features/contacts/blocs/contacts_bloc.dart';
import 'package:objectbox/objectbox.dart';
import 'package:mechanix_dialer/objectbox.g.dart' as dialer_ob;
import 'package:mechanix_contacts/objectbox.g.dart' as contacts_ob;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Dialpad Feature Integration Tests', () {
    late Directory contactsTempDir;
    late Directory recentsTempDir;
    late Store contactsStore;
    late Store recentsStore;

    setUp(() async {
      contactsTempDir = await Directory.systemTemp.createTemp('contacts_test_');
      recentsTempDir = await Directory.systemTemp.createTemp('recents_test_');

      contactsStore = contacts_ob.openStore(directory: contactsTempDir.path);
      recentsStore = dialer_ob.openStore(directory: recentsTempDir.path);
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
      'Verify digits typing, backspacing, outgoing call, incoming call simulation, and add contact redirection',
      (WidgetTester tester) async {
        // 1. Launch the app
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // 2. Switch to Dialpad tab (default tab is recents: index 0)
        final dialpadTabFinder = findImageByAsset(AppIcons.dialpad);
        expect(dialpadTabFinder, findsOneWidget);
        await tester.tap(dialpadTabFinder);
        await tester.pumpAndSettle();

        // Verify DialerScreen is displayed
        expect(find.byType(DialerScreen), findsOneWidget);

        // 3. Test typing digits: "1234"
        await tester.tap(find.widgetWithText(DialButton, '1'));
        await tester.pump();
        await tester.tap(find.widgetWithText(DialButton, '2'));
        await tester.pump();
        await tester.tap(find.widgetWithText(DialButton, '3'));
        await tester.pump();
        await tester.tap(find.widgetWithText(DialButton, '4'));
        await tester.pumpAndSettle();

        // Verify display shows typed digits
        expect(find.text('1234'), findsOneWidget);

        // 4. Test backspacing
        final backspaceFinder = findImageByAsset(AppIcons.backspace);
        expect(backspaceFinder, findsOneWidget);

        // Backspace '4'
        await tester.tap(backspaceFinder);
        await tester.pumpAndSettle();
        expect(find.text('123'), findsOneWidget);

        // Clear the rest
        await tester.tap(backspaceFinder);
        await tester.pump();
        await tester.tap(backspaceFinder);
        await tester.pump();
        await tester.tap(backspaceFinder);
        await tester.pump();
        await tester.pumpAndSettle();

        // 5. Test simulating incoming call (only shows when dial pad display is empty)
        final simulateBtn = find.text('Simulate Incoming Call');
        expect(simulateBtn, findsOneWidget);
        await tester.tap(simulateBtn);
        await tester.pumpAndSettle();

        // Verify CallScreen is opened
        expect(find.byType(CallScreen), findsOneWidget);
        expect(find.text('Incoming call'), findsOneWidget);
        expect(find.text('John Doe'), findsOneWidget);

        // Tap Accept
        final acceptCallFinder = findImageByAsset(AppIcons.call);
        expect(acceptCallFinder, findsOneWidget);
        await tester.tap(acceptCallFinder);
        await tester.pumpAndSettle();

        // Verify call is accepted (status becomes duration, e.g. "00:00")
        expect(find.text('Incoming call'), findsNothing);

        // Hang up
        final endCallFinder = findImageByAsset(AppIcons.endcall);
        expect(endCallFinder, findsOneWidget);
        await tester.tap(endCallFinder);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Verify CallScreen is closed and we are navigated to RecentCallsScreen
        expect(find.byType(CallScreen), findsNothing);
        expect(
          find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == 'RecentCallsScreen',
          ),
          findsOneWidget,
        );

        // Tap dialpad tab to switch back to DialerScreen for outgoing call test
        await tester.tap(dialpadTabFinder);
        await tester.pumpAndSettle();
        expect(find.byType(DialerScreen), findsOneWidget);

        // 6. Test outgoing call
        await tester.tap(find.widgetWithText(DialButton, '9'));
        await tester.pump();
        await tester.tap(find.widgetWithText(DialButton, '1'));
        await tester.pump();
        await tester.tap(find.widgetWithText(DialButton, '1'));
        await tester.pumpAndSettle();
        expect(find.text('911'), findsOneWidget);

        // Tap Call Button in dial pad
        final callBtnFinder = findImageByAsset(AppIcons.call);
        expect(callBtnFinder, findsOneWidget);
        await tester.tap(callBtnFinder);
        await tester.pumpAndSettle();

        // Verify CallScreen is opened and status is "Calling..."
        expect(find.byType(CallScreen), findsOneWidget);
        expect(find.text('Calling...'), findsOneWidget);

        // Hang up outgoing call
        final endCallFinder2 = findImageByAsset(AppIcons.endcall);
        expect(endCallFinder2, findsOneWidget);
        await tester.tap(endCallFinder2);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Verify CallScreen is closed and we are navigated to RecentCallsScreen
        expect(find.byType(CallScreen), findsNothing);
        expect(
          find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == 'RecentCallsScreen',
          ),
          findsOneWidget,
        );

        // Tap dialpad tab to switch back to DialerScreen for Add Contact redirection
        await tester.tap(dialpadTabFinder);
        await tester.pumpAndSettle();
        expect(find.byType(DialerScreen), findsOneWidget);

        // 7. Test Add Contact redirection
        await tester.tap(find.widgetWithText(DialButton, '5'));
        await tester.pump();
        await tester.tap(find.widgetWithText(DialButton, '5'));
        await tester.pump();
        await tester.tap(find.widgetWithText(DialButton, '5'));
        await tester.pumpAndSettle();
        expect(find.text('555'), findsOneWidget);
        await tester.pumpAndSettle();
        expect(find.byType(ContactFormScreen), findsNothing);
      },
    );
  });
}
