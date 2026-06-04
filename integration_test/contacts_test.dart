import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:dialer/main.dart';
import 'package:dialer/core/constants/icons.dart';
import 'package:dialer/features/contacts/presentation/screens/contacts_screen.dart';
import 'package:dialer/features/contacts/presentation/screens/contact_form_screen.dart';
import 'package:dialer/features/contacts/presentation/screens/contact_details_screen.dart';
import 'package:dialer/features/contacts/data/repositories/contacts_repository.dart';
import 'package:dialer/features/contacts/data/repositories/contacts_repository_impl.dart';
import 'package:dialer/features/recents/data/repositories/recent_calls_repository.dart';
import 'package:dialer/features/recents/data/repositories/recent_calls_repository_impl.dart';
import 'package:dialer/features/dialer/blocs/dialer_bloc.dart';
import 'package:dialer/features/recents/blocs/recent_calls_bloc.dart';
import 'package:dialer/features/contacts/blocs/contacts_bloc.dart';
import 'package:dialer/objectbox.g.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Contacts Feature Integration Tests', () {
    late Directory contactsTempDir;
    late Directory recentsTempDir;
    late Store contactsStore;
    late Store recentsStore;

    setUp(() async {
      contactsTempDir = await Directory.systemTemp.createTemp('contacts_test_');
      recentsTempDir = await Directory.systemTemp.createTemp('recents_test_');

      contactsStore = openStore(directory: contactsTempDir.path);
      recentsStore = openStore(directory: recentsTempDir.path);
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
              create: (context) => RecentCallsBloc(context.read<RecentCallsRepository>()),
            ),
            BlocProvider(
              create: (context) => ContactsBloc(context.read<ContactsRepository>()),
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
        return imageProvider is AssetImage && imageProvider.assetName == assetPath;
      });
    }

    testWidgets('Verify contacts listing, addition, search, detail view, and deletion', (WidgetTester tester) async {
      // 1. Launch the app
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // 2. Switch to Contacts tab
      final contactsTabFinder = findImageByAsset(AppIcons.contacts);
      expect(contactsTabFinder, findsOneWidget);
      await tester.tap(contactsTabFinder);
      await tester.pumpAndSettle();

      // Verify ContactsScreen is shown
      expect(find.byType(ContactsScreen), findsOneWidget);

      // 3. Test creating a contact
      final addBtnFinder = find.byIcon(Icons.add);
      expect(addBtnFinder, findsOneWidget);
      await tester.tap(addBtnFinder);
      await tester.pumpAndSettle();

      // Verify ContactFormScreen is shown
      expect(find.byType(ContactFormScreen), findsOneWidget);

      // Fill in Name
      final nameField = find.widgetWithText(TextFormField, 'Enter name');
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'Alice');
      await tester.pump();

      // Fill in Phone number
      final phoneField = find.widgetWithText(TextFormField, 'Enter phone number');
      expect(phoneField, findsOneWidget);
      await tester.enterText(phoneField, '123456789');
      await tester.pump();

      // Save the form
      final saveBtnFinder = find.byIcon(Icons.check);
      expect(saveBtnFinder, findsOneWidget);
      await tester.tap(saveBtnFinder);
      await tester.pumpAndSettle();

      // Verify back on ContactsScreen and contact "Alice" is present
      expect(find.byType(ContactsScreen), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Alice'), findsOneWidget);

      // 4. Test searching contacts
      final searchField = find.widgetWithText(TextField, 'Search in contacts');
      expect(searchField, findsOneWidget);

      // Search for non-existent contact
      await tester.enterText(searchField, 'Bob');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'Alice'), findsNothing);

      // Search for Alice
      await tester.enterText(searchField, 'Alice');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'Alice'), findsOneWidget);

      // Clear search
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'Alice'), findsOneWidget);

      // 5. Test view contact details
      await tester.tap(find.widgetWithText(ListTile, 'Alice'));
      await tester.pumpAndSettle();

      // Verify details screen is opened
      expect(find.byType(ContactDetailsScreen), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('123456789'), findsAtLeastNWidgets(1));

      // 6. Test delete contact
      final moreBtnFinder = find.byIcon(Icons.more_vert);
      expect(moreBtnFinder, findsOneWidget);
      await tester.tap(moreBtnFinder);
      await tester.pumpAndSettle();

      final deleteContactOption = find.text('Delete contact');
      expect(deleteContactOption, findsOneWidget);
      await tester.tap(deleteContactOption);
      await tester.pumpAndSettle();

      // Tap Delete confirmation button in modal sheet
      final deleteConfirmFinder = find.text('Delete');
      expect(deleteConfirmFinder, findsOneWidget);
      await tester.tap(deleteConfirmFinder);
      await tester.pumpAndSettle();

      // Verify back on ContactsScreen and "Alice" is deleted
      expect(find.byType(ContactsScreen), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Alice'), findsNothing);
    });
  });
}
