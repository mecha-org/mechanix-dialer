import 'dart:async';
import 'dart:ui';

import 'package:alphabet_list_view/alphabet_list_view.dart';
import 'package:mechanix_dialer/core/theme/app_theme.dart';
import 'package:mechanix_contacts/mechanix_contacts.dart';
import 'package:mechanix_dialer/features/contacts/presentation/widgets/active_scrollbar_bubble.dart';
import 'package:mechanix_dialer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ContactsListView extends StatelessWidget {
  final List<ContactEntity> contacts;
  final Widget myCard;
  final ScrollController scrollController;
  final Map<String, GlobalKey> groupKeys;
  final bool isScrolling;
  final bool isDraggingScrollbar;
  final bool isAtEnd;
  final Timer? debounceTimer;
  final String Function(String name) getInitials;
  final VoidCallback onScrollbarDragStart;
  final VoidCallback onScrollbarDragEnd;
  final ValueChanged<ContactEntity> onContactTap;
  final VoidCallback onScrollStart;
  final VoidCallback onScrollEnd;

  const ContactsListView({
    super.key,
    required this.contacts,
    required this.myCard,
    required this.scrollController,
    required this.groupKeys,
    required this.isScrolling,
    required this.isDraggingScrollbar,
    required this.isAtEnd,
    required this.debounceTimer,
    required this.getInitials,
    required this.onScrollbarDragStart,
    required this.onScrollbarDragEnd,
    required this.onContactTap,
    required this.onScrollStart,
    required this.onScrollEnd,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, List<ContactEntity>> groups = {};
    final symbols = AppLocalizations.of(context)!.contactAlphabet.split('');

    for (final symbol in symbols) {
      groups[symbol] = [];
    }

    for (final contact in contacts) {
      final firstChar = contact.name.isNotEmpty
          ? contact.name[0].toUpperCase()
          : '#';

      groups.putIfAbsent(firstChar, () => []);
      groups[firstChar]!.add(contact);
    }

    final sortedKeys = groups.keys.toList()..sort();

    final List<AlphabetListViewItemGroup> listItems = [];

    for (final key in sortedKeys) {
      final contactsInGroup = groups[key]!;

      final groupItem = AlphabetListViewItemGroup.builder(
        tag: key,
        itemCount: contactsInGroup.length,
        itemBuilder: (context, index) {
          final contact = contactsInGroup[index];

          return ListTile(
            minTileHeight: 70,
            contentPadding: const EdgeInsets.only(left: 16, right: 16),
            leading: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.backgroundVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                getInitials(contact.name),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              contact.name,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.onSurface),
            ),
            subtitle: Text(
              contact.phoneNumbers.isNotEmpty
                  ? contact.phoneNumbers.first.number
                  : AppLocalizations.of(context)!.noPhoneNumbers,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariantDark,
              ),
            ),
            onTap: () => onContactTap(contact),
          );
        },
      );

      groupKeys[key] = groupItem.key;
      listItems.add(groupItem);
    }

    if (listItems.isEmpty) {
      return Column(
        children: [
          myCard,
          Expanded(
            child: Center(
              child: Text(AppLocalizations.of(context)!.noContactsFound),
            ),
          ),
        ],
      );
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
        scrollbars: false,
      ),
      child: Listener(
        onPointerDown: (event) {
          final screenWidth = MediaQuery.of(context).size.width;

          if (event.position.dx >= screenWidth - 60) {
            onScrollbarDragStart();
          }
        },
        onPointerUp: (_) => onScrollbarDragEnd(),
        onPointerCancel: (_) => onScrollbarDragEnd(),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification ||
                notification is ScrollUpdateNotification) {
              onScrollStart();
            }

            if (notification is ScrollEndNotification) {
              onScrollEnd();
            }

            return false;
          },
          child: AlphabetListView(
            scrollController: scrollController,
            items: listItems,
            options: AlphabetListViewOptions(
              listOptions: ListOptions(
                showSectionHeader: false,
                beforeList: myCard,
                physics: const ClampingScrollPhysics(),
              ),
              scrollbarOptions: ScrollbarOptions(
                width: 24,
                padding: const EdgeInsets.symmetric(vertical: 20),
                mainAxisAlignment: MainAxisAlignment.start,
                symbols: symbols,
                jumpToSymbolsWithNoEntries: true,
                symbolBuilder: (context, symbol, sidebarState) {
                  var isActive =
                      sidebarState == AlphabetScrollbarItemState.active;

                  if (isAtEnd && !isDraggingScrollbar) {
                    final lastActiveSymbol = sortedKeys.lastWhere(
                      (key) => groups[key]!.isNotEmpty,
                      orElse: () => '',
                    );

                    isActive = symbol == lastActiveSymbol;
                  }

                  final showBubble =
                      isActive && (isScrolling || isDraggingScrollbar);

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
                },
              ),
              overlayOptions: const OverlayOptions(showOverlay: false),
            ),
          ),
        ),
      ),
    );
  }
}
