import 'dart:async';
import 'package:mechanix_dialer/core/constants/icons.dart';
import 'package:mechanix_dialer/core/theme/app_theme.dart';
import 'package:mechanix_dialer/core/utils/enums.dart';
import 'package:mechanix_dialer/core/utils/helper.dart';
import 'package:mechanix_dialer/core/widgets/custom_icon_button.dart';
import 'package:mechanix_dialer/core/widgets/custom_image_asset.dart';
import 'package:mechanix_dialer/core/widgets/toast/custom_app_toast.dart';
import 'package:mechanix_dialer/features/contacts/blocs/contacts_bloc.dart';
import 'package:mechanix_dialer/features/contacts/blocs/contacts_event.dart';
import 'package:mechanix_dialer/features/contacts/blocs/contacts_state.dart';
import 'package:mechanix_contacts/mechanix_contacts.dart';
import 'package:mechanix_dialer/features/contacts/presentation/screens/contact_details_screen.dart';
import 'package:mechanix_dialer/features/contacts/presentation/screens/contact_form_screen.dart';
import 'package:mechanix_dialer/features/contacts/presentation/widgets/contacts_list_view.dart';
import 'package:mechanix_dialer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _groupKeys = {};
  bool _isScrolling = false;
  bool _isDraggingScrollbar = false;
  bool _isAtEnd = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    context.read<ContactsBloc>().add(LoadContacts());
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    final state = context.read<ContactsBloc>().state;
    final symbols = AppLocalizations.of(context)!.contactAlphabet.split('');

    if (state.contacts.isNotEmpty) {
      final Map<String, List<ContactEntity>> groups = {};
      for (final symbol in symbols) {
        groups[symbol] = [];
      }
      for (final contact in state.contacts) {
        final firstChar = contact.name.isNotEmpty
            ? contact.name[0].toUpperCase()
            : symbols.last; // Group empty names under the last symbol e.g. '#'
        groups.putIfAbsent(firstChar, () => []);
        groups[firstChar]!.add(contact);
      }

      final sortedKeys = groups.keys.toList()..sort();
      final lastActiveSymbol = sortedKeys.lastWhere(
        (key) => groups[key]!.isNotEmpty,
        orElse: () => '',
      );

      final key = _groupKeys[lastActiveSymbol];
      if (key != null) {
        final isAtEnd = _isLastGroupVisible(key);
        if (isAtEnd != _isAtEnd) {
          setState(() {
            _isAtEnd = isAtEnd;
          });
        }
        return;
      }
    }

    if (_isAtEnd) {
      setState(() {
        _isAtEnd = false;
      });
    }
  }

  bool _isLastGroupVisible(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return false;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return false;
    final position = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    // The last group is visible if its top is above the bottom of the screen
    return position.dy < screenHeight - 60;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _createNewContact() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const ContactFormScreen()),
    );

    if (result != null && mounted) {
      final contact = result['contact'] as ContactEntity;
      final numbers = result['numbers'] as List<String>;
      final emails = result['emails'] as List<String>;

      context.read<ContactsBloc>().add(
        SaveContact(contact: contact, phoneNumbers: numbers, emails: emails),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget myCard = ListTile(
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
          "U",
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        'My card',
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: AppColors.onSurface),
      ),
      onTap: () {
        // TODO: Actions for My Card can be added here
      },
    );

    return BlocListener<ContactsBloc, ContactsState>(
      listenWhen: (previous, current) =>
          previous.error != current.error &&
          current.status == ContactsStatus.error,
      listener: (context, state) {
        if (state.error == null) return;

        CustomAppToast.show(
          context: context,
          message: getErrorMessage(AppLocalizations.of(context)!, state.error!),
          type: ToastType.error,
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.contacts),
          titleTextStyle: Theme.of(context).textTheme.displaySmall,
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 8),
              child: CustomIconButton.icon(
                iconData: Icons.add,
                onPressed: _createNewContact,
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  context.read<ContactsBloc>().add(
                    SearchContacts(value.trim()),
                  );
                },
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchInContacts,
                  hintStyle: Theme.of(context).textTheme.labelMedium,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(8),
                    child: CustomImage(assetPath: AppIcons.search, size: 20),
                  ),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  fillColor: AppColors.backgroundVariantDark,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      context.read<ContactsBloc>().add(
                        const SearchContacts(''),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        body: BlocBuilder<ContactsBloc, ContactsState>(
          builder: (context, state) {
            if (state.status == ContactsStatus.loading &&
                state.contacts.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return ContactsListView(
              contacts: state.contacts,
              myCard: myCard,
              scrollController: _scrollController,
              groupKeys: _groupKeys,
              isScrolling: _isScrolling,
              isDraggingScrollbar: _isDraggingScrollbar,
              isAtEnd: _isAtEnd,
              debounceTimer: _debounceTimer,
              getInitials: getInitials,

              onScrollStart: () {
                if (!_isScrolling) {
                  setState(() {
                    _isScrolling = true;
                  });
                }
              },

              onScrollEnd: () {
                _debounceTimer?.cancel();

                _debounceTimer = Timer(const Duration(milliseconds: 800), () {
                  if (mounted) {
                    setState(() {
                      _isScrolling = false;
                    });
                  }
                });
              },

              onScrollbarDragStart: () {
                setState(() {
                  _isDraggingScrollbar = true;
                });
              },

              onScrollbarDragEnd: () {
                setState(() {
                  _isDraggingScrollbar = false;
                });
              },

              onContactTap: (contact) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ContactDetailsScreen(contact: contact),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
