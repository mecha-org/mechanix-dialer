import 'package:dialer/core/utils/enums.dart';
import 'package:flutter/material.dart';

import 'package:dialer/core/constants/icons.dart';
import 'package:dialer/core/theme/app_theme.dart';
import 'package:dialer/core/widgets/custom_image_asset.dart';

class CallTypeIcon extends StatelessWidget {
  final CallType type;
  final double size;

  const CallTypeIcon({super.key, required this.type, this.size = 24});

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case CallType.missed:
        return CustomImage(
          assetPath: AppIcons.missedCall,
          color: Colors.red,
          size: size,
        );

      case CallType.incoming:
        return CustomImage(
          assetPath: AppIcons.incomingCall,
          color: AppColors.onSurfaceVariant,
          size: size,
        );

      case CallType.outgoing:
        return CustomImage(
          assetPath: AppIcons.outgoingCall,
          color: AppColors.onSurfaceVariant,
          size: size,
        );

      case CallType.rejected:
        return CustomImage(
          assetPath: AppIcons.rejectedCall,
          color: Colors.red,
          size: size,
        );

      case CallType.blocked:
        return CustomImage(
          assetPath: AppIcons.blockCall,
          color: AppColors.onSurfaceVariant,
          size: size,
        );
    }
  }
}
