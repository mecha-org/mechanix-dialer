import 'dart:async';
import 'dart:ui';

import 'package:alphabet_list_view/alphabet_list_view.dart';
import 'package:mechanix_contacts/mechanix_contacts.dart';
import 'package:mechanix_dialer/features/contacts/presentation/widgets/contacts_group_helper.dart';
import 'package:mechanix_dialer/features/contacts/presentation/widgets/contacts_list_tile.dart';
import 'package:mechanix_dialer/features/contacts/presentation/widgets/contacts_scrollbar_symbol.dart';
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
    final symbols = AppLocalizations.of(context)!.contactAlphabet.split('');

    final groups = buildContactGroups(contacts, symbols);

    final sortedKeys = groups.keys.toList()..sort();

    final listItems = buildListItems(
      groups: groups,
      groupKeys: groupKeys,
      itemBuilder: (contact) {
        return ContactListTile(
          contact: contact,
          initials: getInitials(contact.name),
          onTap: () => onContactTap(contact),
        );
      },
    );

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
                  final lastActiveSymbol = sortedKeys.lastWhere(
                    (key) => groups[key]!.isNotEmpty,
                    orElse: () => '',
                  );

                  return ContactsScrollbarSymbol(
                    symbol: symbol,
                    symbols: symbols,
                    sidebarState: sidebarState,
                    isAtEnd: isAtEnd,
                    isDraggingScrollbar: isDraggingScrollbar,
                    isScrolling: isScrolling,
                    lastActiveSymbol: lastActiveSymbol,
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
