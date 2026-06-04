import 'package:dialer/core/constants/app_routes.dart';
import 'package:dialer/core/theme/app_theme.dart';
import 'package:dialer/features/dialer/blocs/dialer_bloc.dart';
import 'package:dialer/features/dialer/presentation/screens/dialer_screen.dart';
import 'package:dialer/features/dialer/presentation/screens/dialer_shell_screen.dart';
import 'package:dialer/features/recents/blocs/recent_calls_bloc.dart';
import 'package:dialer/features/recents/data/repositories/recent_calls_repository.dart';
import 'package:dialer/features/recents/data/repositories/recent_calls_repository_impl.dart';
import 'package:dialer/features/recents/presentation/screens/recent_calls_screen.dart';
import 'package:dialer/features/contacts/data/repositories/contacts_repository.dart';
import 'package:dialer/features/contacts/data/repositories/contacts_repository_impl.dart';
import 'package:dialer/features/contacts/blocs/contacts_bloc.dart';
import 'package:dialer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<RecentCallsRepository>(
          create: (_) => RecentCallsRepositoryImpl(),
        ),
        RepositoryProvider<ContactsRepository>(
          create: (_) => ContactsRepositoryImpl(),
        ),
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
    ),
  );
}

class DialerApp extends StatelessWidget {
  const DialerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DialerShellScreen(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routes: {
        AppRoutes.dialer: (context) => const DialerScreen(),
        AppRoutes.recents: (context) => const RecentCallsScreen(),
      },
    );
  }
}
