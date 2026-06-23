import 'package:mechanix_dialer/core/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_dialer/features/dialer/blocs/dialer_bloc.dart';
import 'package:mechanix_dialer/features/dialer/blocs/dialer_state.dart';
import 'package:mechanix_dialer/features/dialer/presentation/screens/call_screen.dart';
import 'package:mechanix_dialer/features/dialer/presentation/screens/dialer_screen.dart';
import 'package:mechanix_dialer/features/dialer/presentation/widgets/dialer_bottom_bar.dart';
import 'package:mechanix_dialer/features/recents/presentation/screens/recent_calls_screen.dart';
import 'package:mechanix_dialer/features/contacts/presentation/screens/contacts_screen.dart';
import 'package:mechanix_dialer/features/recents/blocs/recent_calls_bloc.dart';
import 'package:mechanix_dialer/features/recents/blocs/recent_calls_event.dart';

class DialerShellScreen extends StatefulWidget {
  const DialerShellScreen({super.key});

  @override
  State<DialerShellScreen> createState() => _DialerShellScreenState();
}

class _DialerShellScreenState extends State<DialerShellScreen> {
  int _index = 0;
  final _dialerKey = GlobalKey<DialerScreenState>();

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();

    _tabs = [
      const RecentCallsScreen(),
      DialerScreen(key: _dialerKey),
      const ContactsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DialerBloc, DialerState>(
      listenWhen: (previous, current) {
        final started =
            previous.callStatus == CallStatus.none &&
            (current.callStatus == CallStatus.calling ||
                current.callStatus == CallStatus.incoming);
        final ended =
            previous.callStatus != CallStatus.none &&
            current.callStatus == CallStatus.none;
        return started || ended;
      },
      listener: (context, state) {
        if (state.callStatus == CallStatus.calling ||
            state.callStatus == CallStatus.incoming) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CallScreen()),
          );
        } else if (state.callStatus == CallStatus.none) {
          setState(() {
            _index = 0;
          });
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: _tabs),
        bottomNavigationBar: DialerBottomBar(
          currentIndex: _index,

          // onTap: (i) {
          //   setState(() => _index = i);
          //   if (i == 0) {
          //     // Refresh the Recents list whenever the user navigates to the Recents tab.
          //     context.read<RecentCallsBloc>().add(LoadRecentCalls());
          //   }
          // },
          onTap: (i) {
            if (_index == 1 && i != 1) {
              _dialerKey.currentState?.clearDialedNumber();
            }

            setState(() => _index = i);

            if (i == 0) {
              context.read<RecentCallsBloc>().add(LoadRecentCalls());
            }
          },
        ),
      ),
    );
  }
}
