import 'package:mechanix_dialer/core/constants/icons.dart';
import 'package:mechanix_dialer/core/theme/app_theme.dart';
import 'package:mechanix_dialer/core/widgets/custom_image_asset.dart';
import 'package:mechanix_dialer/core/widgets/toast/custom_app_toast.dart';
import 'package:mechanix_dialer/features/contacts/presentation/widgets/contact_form_content.dart';
import 'package:mechanix_dialer/features/contacts/presentation/widgets/contacts_form_bottom_bar.dart';
import 'package:mechanix_dialer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:mechanix_contacts/mechanix_contacts.dart';

class ContactFormScreen extends StatefulWidget {
  final ContactEntity? contact;
  final List<String>? initialNumbers;
  final List<String>? initialEmails;

  const ContactFormScreen({
    super.key,
    this.contact,
    this.initialNumbers,
    this.initialEmails,
  });

  @override
  State<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final List<TextEditingController> _phoneControllers = [];
  final List<TextEditingController> _emailControllers = [];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.contact?.name ?? '');

    if (widget.initialNumbers != null) {
      for (final number in widget.initialNumbers!) {
        _addPhoneController(number);
      }
    }

    if (widget.initialEmails != null) {
      for (final email in widget.initialEmails!) {
        _addEmailController(email);
      }
    }

    _addPhoneController();
    _addEmailController();
  }

  @override
  void dispose() {
    _nameController.dispose();

    for (final controller in _phoneControllers) {
      controller.dispose();
    }

    for (final controller in _emailControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  // Phone number field management
  void _addPhoneController([String text = '']) {
    final controller = TextEditingController(text: text);

    controller.addListener(() {
      _handlePhoneFieldChanged(controller);
    });

    _phoneControllers.add(controller);
  }

  void _handlePhoneFieldChanged(TextEditingController controller) {
    final index = _phoneControllers.indexOf(controller);

    if (index == -1) return;

    // User started typing in last field
    if (index == _phoneControllers.length - 1 &&
        controller.text.trim().isNotEmpty) {
      setState(() {
        _addPhoneController();
      });
    }

    _removeExtraEmptyFields();
  }

  void _removeExtraEmptyFields() {
    final emptyIndexes = <int>[];

    for (int i = 0; i < _phoneControllers.length; i++) {
      if (_phoneControllers[i].text.trim().isEmpty) {
        emptyIndexes.add(i);
      }
    }

    // Keep only the last empty field
    if (emptyIndexes.length <= 1) return;

    setState(() {
      for (int i = emptyIndexes.length - 2; i >= 0; i--) {
        final removeIndex = emptyIndexes[i];

        _phoneControllers[removeIndex].dispose();
        _phoneControllers.removeAt(removeIndex);
      }
    });
  }

  void _removePhoneNumberField(int index) {
    if (_phoneControllers.length <= 1) return;

    setState(() {
      _phoneControllers[index].dispose();
      _phoneControllers.removeAt(index);

      if (_phoneControllers.isEmpty ||
          _phoneControllers.last.text.trim().isNotEmpty) {
        _addPhoneController();
      }
    });
  }

  // Email field management
  void _addEmailController([String text = '']) {
    final controller = TextEditingController(text: text);

    controller.addListener(() {
      _handleEmailFieldChanged(controller);
    });

    _emailControllers.add(controller);
  }

  void _handleEmailFieldChanged(TextEditingController controller) {
    final index = _emailControllers.indexOf(controller);

    if (index == -1) return;

    if (index == _emailControllers.length - 1 &&
        controller.text.trim().isNotEmpty) {
      setState(() {
        _addEmailController();
      });
    }

    _removeExtraEmptyEmailFields();
  }

  void _removeExtraEmptyEmailFields() {
    final emptyIndexes = <int>[];

    for (int i = 0; i < _emailControllers.length; i++) {
      if (_emailControllers[i].text.trim().isEmpty) {
        emptyIndexes.add(i);
      }
    }

    if (emptyIndexes.length <= 1) return;

    setState(() {
      for (int i = emptyIndexes.length - 2; i >= 0; i--) {
        final removeIndex = emptyIndexes[i];

        _emailControllers[removeIndex].dispose();
        _emailControllers.removeAt(removeIndex);
      }
    });
  }

  void _removeEmailField(int index) {
    if (_emailControllers.length <= 1) return;

    setState(() {
      _emailControllers[index].dispose();
      _emailControllers.removeAt(index);

      if (_emailControllers.isEmpty ||
          _emailControllers.last.text.trim().isNotEmpty) {
        _addEmailController();
      }
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final email = value.trim();

    const pattern = r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';

    if (!RegExp(pattern).hasMatch(email)) {
      return AppLocalizations.of(context)!.invalidEmail;
    }

    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final numbers = _phoneControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final emails = _emailControllers
        .map((c) => c.text.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (numbers.isEmpty) {
      CustomAppToast.show(
        context: context,
        message: AppLocalizations.of(context)!.pleaseEnterAtLeastOnePhoneNumber,

        type: ToastType.error,
      );
      return;
    }

    final contact = widget.contact ?? ContactEntity(name: name);
    contact.name = name;

    Navigator.pop(context, {
      'contact': contact,
      'numbers': numbers,
      'emails': emails,
    });
  }

  String get initials {
    final name = _nameController.text.trim();

    if (name.isEmpty) return '';

    final parts = name.split(RegExp(r'\s+'));

    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.contact != null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          isEditing
              ? AppLocalizations.of(context)!.editContact
              : AppLocalizations.of(context)!.newContact,
        ),
        titleTextStyle: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.backgroundVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: initials.isEmpty
                    ? const CustomImage(
                        size: 28,
                        color: AppColors.onSurface,
                        assetPath: AppIcons.person,
                      )
                    : Text(
                        initials,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
              ),
            ),
          ),
        ),
      ),
      body: ContactFormContent(
        formKey: _formKey,
        nameController: _nameController,
        phoneControllers: _phoneControllers,
        emailControllers: _emailControllers,
        onAddPhone: () {
          setState(() {
            _addPhoneController();
          });
        },
        onRemovePhone: _removePhoneNumberField,
        onAddEmail: () {
          setState(() {
            _addEmailController();
          });
        },
        onRemoveEmail: _removeEmailField,
        validateEmail: _validateEmail,
      ),
      bottomNavigationBar: ContactsFormBottomBar(onSave: _save),
    );
  }
}
