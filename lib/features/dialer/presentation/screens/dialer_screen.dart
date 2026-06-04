import 'package:dialer/core/theme/app_theme.dart';
import 'package:dialer/core/utils/enums.dart';
import 'package:dialer/features/contacts/data/repositories/contacts_repository.dart';
import 'package:dialer/features/dialer/blocs/dialer_bloc.dart';
import 'package:dialer/features/dialer/blocs/dialer_event.dart';
import 'package:dialer/features/dialer/blocs/dialer_state.dart';
import 'package:dialer/features/dialer/presentation/widgets/dial_pad_grids.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DialerScreen extends StatefulWidget {
  const DialerScreen({super.key});

  @override
  State<DialerScreen> createState() => DialerScreenState();
}

class DialerScreenState extends State<DialerScreen> {
  final ValueNotifier<String> dialedNumberNotifier = ValueNotifier('');
  final ValueNotifier<String?> callerNameNotifier = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    dialedNumberNotifier.addListener(_onNumberChanged);
  }

  @override
  void dispose() {
    dialedNumberNotifier.removeListener(_onNumberChanged);
    dialedNumberNotifier.dispose();
    callerNameNotifier.dispose();
    super.dispose();
  }

  Future<void> _onNumberChanged() async {
    final number = dialedNumberNotifier.value;
    if (number.isEmpty) {
      callerNameNotifier.value = null;
      return;
    }
    final contactsRepository = context.read<ContactsRepository>();
    try {
      final contacts = await contactsRepository.search(number);
      for (final contact in contacts) {
        for (final phone in contact.phoneNumbers) {
          final cleanPhone = phone.number.replaceAll(RegExp(r'\D'), '');
          final cleanNumber = number.replaceAll(RegExp(r'\D'), '');
          if (cleanPhone == cleanNumber || phone.number == number) {
            callerNameNotifier.value = contact.name;
            return;
          }
        }
      }
    } catch (e) {
      // ignore
    }
    callerNameNotifier.value = null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DialerBloc, DialerState>(
      listenWhen: (previous, current) =>
          previous.callStatus == CallStatus.none &&
          (current.callStatus == CallStatus.calling ||
              current.callStatus == CallStatus.incoming),
      listener: (context, state) {
        dialedNumberNotifier.value = '';
      },
      child: Scaffold(
        body: Container(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              ValueListenableBuilder<String>(
                valueListenable: dialedNumberNotifier,
                builder: (context, dialedNumber, _) {
                  return ValueListenableBuilder<String?>(
                    valueListenable: callerNameNotifier,
                    builder: (context, callerName, _) {
                      return Column(
                        children: [
                          Text(
                            dialedNumber.isEmpty ? ' ' : dialedNumber,
                            style: Theme.of(context).textTheme.labelLarge,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          if (dialedNumber.isNotEmpty) ...[
                            if (callerName != null && callerName.isNotEmpty)
                              Text(
                                callerName,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                              )
                            else
                              const SizedBox(height: 22),
                          ] else ...[
                            // Number is empty, show option to simulate incoming call
                            GestureDetector(
                              onTap: () {
                                context.read<DialerBloc>().add(
                                  ReceiveIncomingCall(
                                    phoneNumber: '01-45728',
                                    callerName: 'John Doe',
                                    simNumber: '01-626262',
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.backgroundVariantLight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.call_received,
                                      size: 14,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "Simulate Incoming Call",
                                      style: TextStyle(
                                        color: AppColors.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 18),

              Expanded(
                child: DialPadGrid(dialedNumberNotifier: dialedNumberNotifier),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
