import 'package:alphabet_list_view/alphabet_list_view.dart';
import 'package:flutter/material.dart';
import 'package:mechanix_contacts/features/contacts/data/models/contacts.dart';

Map<String, List<ContactEntity>> buildContactGroups(
  List<ContactEntity> contacts,
  List<String> symbols,
) {
  final groups = <String, List<ContactEntity>>{};

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

  return groups;
}

List<AlphabetListViewItemGroup> buildListItems({
  required Map<String, List<ContactEntity>> groups,
  required Map<String, GlobalKey> groupKeys,
  required Widget Function(ContactEntity contact) itemBuilder,
}) {
  final sortedKeys = groups.keys.toList()..sort();

  final items = <AlphabetListViewItemGroup>[];

  for (final key in sortedKeys) {
    final contacts = groups[key]!;

    final group = AlphabetListViewItemGroup.builder(
      tag: key,
      itemCount: contacts.length,
      itemBuilder: (_, index) => itemBuilder(contacts[index]),
    );

    groupKeys[key] = group.key;
    items.add(group);
  }

  return items;
}
