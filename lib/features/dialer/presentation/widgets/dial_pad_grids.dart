import 'package:mechanix_dialer/core/constants/dial_pad_buttons.dart';
import 'package:mechanix_dialer/core/constants/icons.dart';
import 'package:mechanix_dialer/core/theme/app_theme.dart';
import 'package:mechanix_dialer/core/widgets/custom_image_asset.dart';
import 'package:mechanix_dialer/core/widgets/toast/custom_app_toast.dart';
import 'package:mechanix_dialer/features/dialer/blocs/dialer_bloc.dart';
import 'package:mechanix_dialer/features/dialer/blocs/dialer_event.dart';
import 'package:mechanix_dialer/features/dialer/presentation/widgets/dial_button.dart';
import 'package:mechanix_dialer/features/dialer/presentation/widgets/dial_pad_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DialPadGrid extends StatelessWidget {
  final ValueNotifier<String> dialedNumberNotifier;

  const DialPadGrid({super.key, required this.dialedNumberNotifier});

  @override
  Widget build(BuildContext context) {
    final items = [
      ...DialerButtons.keys.map((e) {
        final isZero = e == '0';
        return DialPadItem(
          text: e,
          subText: isZero ? '+' : null,
          backgroundColor: AppColors.backgroundVariant,
          onTap: () {
            dialedNumberNotifier.value += e;
          },
          onLongPress: isZero
              ? () {
                  dialedNumberNotifier.value += '+';
                }
              : null,
        );
      }),

      DialPadItem(
        icon: const CustomImage(assetPath: AppIcons.personAdd, size: 32),
        backgroundColor: AppColors.backgroundVariantDark,
        onTap: () {
          // TODO: Implement conference call
        },
      ),

      DialPadItem(
        icon: const CustomImage(
          assetPath: AppIcons.call,
          size: 36,
          color: AppColors.onSurface,
        ),
        backgroundColor: Colors.green,
        onTap: () {
          final number = dialedNumberNotifier.value;
          final cleanNumber = number.replaceAll(RegExp(r'[^\d*#+]'), '');
          if (cleanNumber.length < 3) {
            CustomAppToast.show(
              context: context,
              message: "Please enter a valid phone number (at least 3 digits).",
              type: ToastType.error,
            );
            return;
          }
          context.read<DialerBloc>().add(StartOutgoingCall(number));
        },
      ),

      DialPadItem(
        icon: const CustomImage(assetPath: AppIcons.backspace, size: 32),
        backgroundColor: AppColors.backgroundVariantDark,
        onTap: () {
          final number = dialedNumberNotifier.value;
          if (number.isNotEmpty) {
            dialedNumberNotifier.value = number.substring(0, number.length - 1);
          }
        },
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const horizontalSpacing = 10.0 * 2;
          const verticalSpacing = 10.0 * 4;
          final itemWidth = (constraints.maxWidth - horizontalSpacing) / 3;
          final itemHeight = (constraints.maxHeight - verticalSpacing) / 5;
          final aspectRatio = itemWidth / itemHeight;

          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: aspectRatio,
            ),
            itemBuilder: (context, index) {
              final item = items[index];

              return DialButton(
                text: item.text,
                subText: item.subText,
                icon: item.icon,
                backgroundColor: item.backgroundColor,
                onTap: item.onTap!,
                onLongPress: item.onLongPress,
              );
            },
          );
        },
      ),
    );
  }
}
