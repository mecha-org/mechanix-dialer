import 'dart:ui';

import 'package:mechanix_dialer/core/constants/dial_pad_buttons.dart';
import 'package:mechanix_dialer/core/theme/app_theme.dart';
import 'package:mechanix_dialer/core/constants/icons.dart';
import 'package:mechanix_dialer/core/utils/enums.dart';
import 'package:mechanix_dialer/core/utils/helper.dart';
import 'package:mechanix_dialer/core/widgets/custom_image_asset.dart';
import 'package:mechanix_dialer/features/dialer/blocs/dialer_bloc.dart';
import 'package:mechanix_dialer/features/dialer/blocs/dialer_event.dart';
import 'package:mechanix_dialer/features/dialer/blocs/dialer_state.dart';
import 'package:mechanix_dialer/features/dialer/presentation/widgets/call_action_buttton.dart';
import 'package:mechanix_dialer/features/dialer/presentation/widgets/call_toggle_button.dart';
import 'package:mechanix_dialer/features/dialer/presentation/widgets/dial_button.dart';
import 'package:mechanix_dialer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _showDialPad = false;
  String _dtmfInput = '';
  final ScrollController _dtmfScrollController = ScrollController();

  @override
  void dispose() {
    _dtmfScrollController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _toggleDialPad() {
    setState(() {
      _showDialPad = !_showDialPad;

      if (!_showDialPad) {
        _dtmfInput = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DialerBloc, DialerState>(
      listenWhen: (previous, current) =>
          previous.callStatus != CallStatus.none &&
          current.callStatus == CallStatus.none,
      listener: (context, state) {
        Navigator.maybePop(context);
      },
      child: Scaffold(
        body: BlocBuilder<DialerBloc, DialerState>(
          builder: (context, state) {
            final isButtonsEnabled = state.callStatus != CallStatus.cancelled;
            final bool hasContactName =
                state.callerName != null && state.callerName!.isNotEmpty;

            final String displayName = hasContactName
                ? state.callerName!
                : state.callerNumber;

            final String? subText = hasContactName ? state.callerNumber : null;

            final String initials = hasContactName
                ? getInitials(state.callerName!)
                : '';

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    if (!_showDialPad) const Spacer(flex: 1),

                    // Avatar block / Dial Pad Block
                    if (_showDialPad) ...[
                      const SizedBox(height: 12),
                      // Time/duration at top
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            state.callStatus == CallStatus.calling
                                ? AppLocalizations.of(context)!.calling
                                : state.callStatus == CallStatus.incoming
                                ? AppLocalizations.of(context)!.incomingCall
                                : state.callStatus == CallStatus.active
                                ? _formatDuration(state.callDuration)
                                : state.callStatus == CallStatus.cancelled
                                ? AppLocalizations.of(context)!.callCancelled
                                : "",
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize:
                                      state.callStatus == CallStatus.active
                                      ? 18
                                      : 14,
                                  fontWeight:
                                      state.callStatus == CallStatus.active
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                  color: state.callStatus == CallStatus.active
                                      ? AppColors.onSurfaceVariant
                                      : AppColors.onSurfaceVariantDark,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Shows the sequence of DTMF digits entered during an active call.
                      // Used for IVR systems, conference PINs, voicemail navigation, etc.
                      SizedBox(
                        height: 48,
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: {
                              PointerDeviceKind.touch,
                              PointerDeviceKind.mouse,
                            },
                          ),
                          child: SingleChildScrollView(
                            controller: _dtmfScrollController,
                            scrollDirection: Axis.horizontal,
                            reverse: true,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                _dtmfInput,
                                style: Theme.of(context).textTheme.displayMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2.0,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      // Dial pad buttons layout dynamically calculated to match mechanix_dialer screen style
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            const horizontalSpacing = 10.0 * 2;
                            const verticalSpacing = 10.0 * 3;
                            final itemWidth =
                                (constraints.maxWidth - horizontalSpacing) / 3;
                            final itemHeight =
                                (constraints.maxHeight - verticalSpacing) / 4;
                            final aspectRatio = itemWidth / itemHeight;

                            return GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: DialerButtons.keys.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: aspectRatio,
                                  ),
                              itemBuilder: (context, index) {
                                final key = DialerButtons.keys[index];
                                return DialButton(
                                  text: key,
                                  backgroundColor: AppColors.backgroundVariant,
                                  onTap: () {
                                    setState(() {
                                      _dtmfInput += key;
                                    });

                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (_dtmfScrollController
                                              .hasClients) {
                                            _dtmfScrollController.animateTo(
                                              0,
                                              duration: const Duration(
                                                milliseconds: 150,
                                              ),
                                              curve: Curves.easeOut,
                                            );
                                          }
                                        });
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: 100,
                        height: 100,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: (initials.trim().isEmpty)
                            ? const CustomImage(
                                size: 36,
                                color: AppColors.onSurface,
                                assetPath: AppIcons.person,
                              )
                            : Text(
                                initials,
                                style: Theme.of(context).textTheme.displayMedium
                                    ?.copyWith(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                      ),

                      const SizedBox(height: 32),

                      // Name Display
                      Text(
                        displayName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurface,
                        ),
                      ),

                      // Number display (if name is present)
                      if (subText != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          subText,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Call status with icon if applicable
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            state.callStatus == CallStatus.calling
                                ? AppLocalizations.of(context)!.calling
                                : state.callStatus == CallStatus.incoming
                                ? AppLocalizations.of(context)!.incomingCall
                                : state.callStatus == CallStatus.active
                                ? _formatDuration(state.callDuration)
                                : state.callStatus == CallStatus.cancelled
                                ? AppLocalizations.of(context)!.callCancelled
                                : "",
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize:
                                      state.callStatus == CallStatus.active
                                      ? 18
                                      : 14,
                                  fontWeight:
                                      state.callStatus == CallStatus.active
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                  color: state.callStatus == CallStatus.active
                                      ? AppColors.onSurfaceVariant
                                      : AppColors.onSurfaceVariantDark,
                                ),
                          ),
                        ],
                      ),
                    ],

                    if (!_showDialPad)
                      const Spacer(flex: 2)
                    else
                      const SizedBox(height: 12),

                    // Buttons Section
                    if (state.callStatus == CallStatus.incoming)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Reject Button
                          GestureDetector(
                            onTap: () {
                              context.read<DialerBloc>().add(RejectCall());
                            },
                            child: Container(
                              width: 160,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: CustomImage(
                                  assetPath: AppIcons.endcall,
                                  size: 28,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          // Accept Button
                          GestureDetector(
                            onTap: () {
                              context.read<DialerBloc>().add(AcceptCall());
                            },
                            child: Container(
                              width: 160,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: CustomImage(
                                  assetPath: AppIcons.call,
                                  size: 28,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (_showDialPad)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Row 1: Speaker, Mute, Dialpad
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CallToggleButton(
                                icon: AppIcons.volume,
                                isActive: state.isSpeakerOn,
                                isEnabled: isButtonsEnabled,
                                onTap: () {
                                  context.read<DialerBloc>().add(
                                    ToggleSpeaker(),
                                  );
                                },
                              ),
                              CallToggleButton(
                                icon: AppIcons.mute,
                                isActive: state.isMuted,
                                isEnabled: isButtonsEnabled,
                                onTap: () {
                                  context.read<DialerBloc>().add(ToggleMute());
                                },
                              ),
                              CallToggleButton(
                                icon: AppIcons.dialpad,
                                isActive: _showDialPad,
                                isEnabled: isButtonsEnabled,
                                onTap: _toggleDialPad,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Row 2: Center Hangup Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: isButtonsEnabled
                                    ? () {
                                        context.read<DialerBloc>().add(
                                          EndCall(),
                                        );
                                      }
                                    : null,
                                child: Container(
                                  width: 165,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: isButtonsEnabled
                                        ? Colors.redAccent
                                        : AppColors.backgroundVariantLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: CustomImage(
                                      assetPath: AppIcons.endcall,
                                      size: 28,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Row 1: Speaker & Mute
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CallToggleButton(
                                icon: AppIcons.volume,
                                isActive: state.isSpeakerOn,
                                isEnabled: isButtonsEnabled,
                                onTap: () {
                                  context.read<DialerBloc>().add(
                                    ToggleSpeaker(),
                                  );
                                },
                              ),
                              CallToggleButton(
                                icon: AppIcons.mute,
                                isActive: state.isMuted,
                                isEnabled: isButtonsEnabled,
                                onTap: () {
                                  context.read<DialerBloc>().add(ToggleMute());
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Row 2: Add Contact, Hangup, Dialpad
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CallActionButton(
                                icon: AppIcons.personAdd,
                                isEnabled: isButtonsEnabled,
                                onTap: () {
                                  // TODO: Conference call
                                },
                              ),
                              // Hangup Button
                              GestureDetector(
                                onTap: isButtonsEnabled
                                    ? () {
                                        context.read<DialerBloc>().add(
                                          EndCall(),
                                        );
                                      }
                                    : null,
                                child: Container(
                                  width: 165,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: isButtonsEnabled
                                        ? Colors.redAccent
                                        : AppColors.backgroundVariantLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: CustomImage(
                                      assetPath: AppIcons.endcall,
                                      size: 28,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              CallToggleButton(
                                icon: AppIcons.dialpad,
                                isActive: _showDialPad,
                                isEnabled: isButtonsEnabled,
                                onTap: () {
                                  setState(() {
                                    _showDialPad = !_showDialPad;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
