import 'package:mechanix_dialer/core/constants/icons.dart';
import 'package:mechanix_dialer/core/theme/app_theme.dart';
import 'package:mechanix_dialer/core/utils/helper.dart';
import 'package:mechanix_dialer/core/widgets/custom_image_asset.dart';
import 'package:mechanix_dialer/features/contacts/blocs/contacts_bloc.dart';
import 'package:mechanix_dialer/features/contacts/blocs/contacts_event.dart';
import 'package:mechanix_dialer/features/contacts/data/repositories/contacts_repository.dart';
import 'package:mechanix_contacts/mechanix_contacts.dart';
import 'package:mechanix_dialer/features/contacts/presentation/screens/contact_form_screen.dart';
import 'package:mechanix_dialer/features/contacts/presentation/widgets/contact_details_content.dart';
import 'package:mechanix_dialer/features/contacts/presentation/widgets/contacts_action_menu.dart';
import 'package:mechanix_dialer/features/contacts/presentation/widgets/contacts_info_bottom_bar.dart';
import 'package:mechanix_dialer/features/contacts/presentation/widgets/delete_contact_confirmation.dart';
import 'package:mechanix_dialer/features/dialer/blocs/dialer_bloc.dart';
import 'package:mechanix_dialer/features/dialer/blocs/dialer_event.dart';
import 'package:mechanix_dialer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContactDetailsScreen extends StatefulWidget {
  final ContactEntity contact;

  const ContactDetailsScreen({super.key, required this.contact});

  @override
  State<ContactDetailsScreen> createState() => ContactDetailsScreenState();
}

class ContactDetailsScreenState extends State<ContactDetailsScreen> {
  late ContactEntity _contact;
  late List<String> _numbers;
  late List<String> _emails;
  String? _preferredLine;

  List<SimCardEntity> _simCards = [];
  SimCardEntity _selectedSim = SimCardEntity(
    slot: '1',
    name: 'Primary',
    number: '01-554738',
  );

  @override
  void initState() {
    super.initState();
    _contact = widget.contact;
    _updateNumbersAndEmailList();
    _loadSimCards();
  }

  Future<void> _loadSimCards() async {
    final simCards = await context.read<ContactsRepository>().getSimCards();
    if (mounted && simCards.isNotEmpty) {
      setState(() {
        _simCards = simCards;
        _selectedSim = simCards.firstWhere(
          (sim) => sim.slot == _selectedSim.slot,
          orElse: () => simCards.first,
        );
      });
    }
  }

  void _updateNumbersAndEmailList() {
    _numbers = _contact.phoneNumbers.map((p) => p.number).toList();
    _emails = _contact.emails.map((e) => e.email).toList();

    if (_numbers.isNotEmpty) {
      _preferredLine = _numbers.first;
    } else {
      _preferredLine = null;
    }
  }

  void _showPreferredLineDialog() {
    if (_numbers.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundVariantDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Text(
                    AppLocalizations.of(context)!.preferredLine,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                ),
                ..._simCards.map((sim) {
                  final isSelected = _selectedSim.slot == sim.slot;
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? AppColors.onSurface
                              : AppColors.onSurfaceVariantDark,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        sim.slot,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? AppColors.onSurface
                              : AppColors.onSurfaceVariantDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      sim.number,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? AppColors.onSurface
                            : AppColors.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.onSurface,
                            size: 20,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedSim = sim;
                      });
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _showActionsMenu = false;

  void _toggleActionsMenu() {
    setState(() {
      _showActionsMenu = !_showActionsMenu;
    });
  }

  void _closeActionsMenu() {
    if (_showActionsMenu) {
      setState(() {
        _showActionsMenu = false;
      });
    }
  }

  Future<void> editContact() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => ContactFormScreen(
          contact: _contact,
          initialNumbers: _numbers,
          initialEmails: _emails,
        ),
      ),
    );

    if (result != null && mounted) {
      final editedContact = result['contact'] as ContactEntity;
      final editedNumbers = result['numbers'] as List<String>;
      final editedEmails = result['emails'] as List<String>;

      context.read<ContactsBloc>().add(
        SaveContact(
          contact: editedContact,
          phoneNumbers: editedNumbers,
          emails: editedEmails,
        ),
      );

      setState(() {
        _contact = editedContact;
        _numbers = editedNumbers;
        _emails = editedEmails;

        if (_numbers.isNotEmpty && !_numbers.contains(_preferredLine)) {
          _preferredLine = _numbers.first;
        }
      });
    }
  }

  void confirmDelete() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DeleteContactBottomSheet(
          contactName: _contact.name,
          onDelete: () {
            Navigator.pop(context); // close bottom sheet
            context.read<ContactsBloc>().add(DeleteContact(_contact.id));
            Navigator.pop(context); // close details screen
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = getInitials(_contact.name);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 72,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.backgroundVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: (initials.trim().isEmpty)
                  ? const CustomImage(
                      size: 28,
                      color: AppColors.onSurface,
                      assetPath: AppIcons.person,
                    )
                  : Text(
                      initials,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _contact.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: ContactDetailsBody(
        selectedSimSlot: _selectedSim.slot,
        selectedSimNumber: _selectedSim.number,
        numbers: _numbers,
        emails: _emails,
        onPreferredLineTap: _showPreferredLineDialog,
        onCall: (number) {
          context.read<DialerBloc>().add(
            StartOutgoingCall(number, simNumber: _selectedSim.number),
          );
        },
        onMessage: (number) {
          // TODO : Implement messaging functionality
        },
      ),

      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showActionsMenu)
            ContactsActionsMenu(
              closeContactsActionsSheet: _closeActionsMenu,
              state: this,
            ),

          ContactsInfoBottomBar(
            onBack: () => Navigator.pop(context),
            onCall: () {
              final numberToCall =
                  _preferredLine ??
                  (_numbers.isNotEmpty ? _numbers.first : null);

              if (numberToCall != null) {
                context.read<DialerBloc>().add(
                  StartOutgoingCall(
                    numberToCall,
                    simNumber: _selectedSim.number,
                  ),
                );
              }
            },
            onMessage: () {},
            onMore: _toggleActionsMenu,
            isMenuActive: _showActionsMenu,
          ),
        ],
      ),
    );
  }
}
