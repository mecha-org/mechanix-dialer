import 'package:mechanix_dialer/core/theme/app_theme.dart';
import 'package:mechanix_dialer/core/utils/enums.dart';
import 'package:mechanix_dialer/core/utils/helper.dart';
import 'package:mechanix_dialer/core/widgets/toast/custom_app_toast.dart';
import 'package:mechanix_dialer/features/contacts/blocs/contacts_bloc.dart';
import 'package:mechanix_dialer/features/contacts/blocs/contacts_event.dart';
import 'package:mechanix_dialer/features/contacts/blocs/contacts_state.dart';
import 'package:mechanix_dialer/features/contacts/data/repositories/contacts_repository.dart';
import 'package:mechanix_contacts/mechanix_contacts.dart';
import 'package:mechanix_dialer/features/contacts/presentation/screens/contact_form_screen.dart';
import 'package:mechanix_dialer/features/contacts/presentation/widgets/contact_details_app_bar.dart';
import 'package:mechanix_dialer/features/contacts/presentation/widgets/contact_details_content.dart';
import 'package:mechanix_dialer/features/contacts/presentation/widgets/contacts_action_menu.dart';
import 'package:mechanix_dialer/features/contacts/presentation/widgets/contacts_info_bottom_bar.dart';
import 'package:mechanix_dialer/features/contacts/presentation/widgets/delete_contact_confirmation.dart';
import 'package:mechanix_dialer/features/contacts/presentation/widgets/preferred_line_sheet.dart';
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
      builder: (_) {
        return PreferredLineSheet(
          simCards: _simCards,
          selectedSim: _selectedSim,
          onSelected: (sim) {
            setState(() {
              _selectedSim = sim;
            });

            Navigator.pop(context);
          },
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
        appBar: ContactDetailsAppBar(contact: _contact),
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
              onMore: _toggleActionsMenu,
              isMenuActive: _showActionsMenu,
            ),
          ],
        ),
      ),
    );
  }
}
