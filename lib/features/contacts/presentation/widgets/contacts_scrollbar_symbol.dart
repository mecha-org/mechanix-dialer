import 'package:alphabet_list_view/alphabet_list_view.dart';
import 'package:flutter/material.dart';
import 'package:mechanix_dialer/core/theme/app_theme.dart';
import 'package:mechanix_dialer/features/contacts/presentation/widgets/active_scrollbar_bubble.dart';

class ContactsScrollbarSymbol extends StatelessWidget {
  final String symbol;
  final List<String> symbols;
  final AlphabetScrollbarItemState sidebarState;
  final bool isAtEnd;
  final bool isDraggingScrollbar;
  final bool isScrolling;
  final String lastActiveSymbol;

  const ContactsScrollbarSymbol({
    super.key,
    required this.symbol,
    required this.symbols,
    required this.sidebarState,
    required this.isAtEnd,
    required this.isDraggingScrollbar,
    required this.isScrolling,
    required this.lastActiveSymbol,
  });

  @override
  Widget build(BuildContext context) {
    var isActive = sidebarState == AlphabetScrollbarItemState.active;

    if (isAtEnd && !isDraggingScrollbar) {
      isActive = symbol == lastActiveSymbol;
    }

    final showBubble = isActive && (isScrolling || isDraggingScrollbar);

    if (showBubble) {
      double verticalAlignment = 0.0;

      if (symbol == symbols.first) {
        verticalAlignment = -1.0;
      } else if (symbol == symbols.last) {
        verticalAlignment = 1.0;
      }

      return ActiveScrollbarBubble(
        symbol: symbol,
        verticalAlignment: verticalAlignment,
      );
    }

    if (isActive) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.onSurfaceVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        width: 4,
        height: 4,
        decoration: const BoxDecoration(
          color: AppColors.onSurfaceVariantDark,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
