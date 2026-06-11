import 'package:mechanix_dialer/core/constants/icons.dart';
import 'package:mechanix_dialer/core/theme/app_theme.dart';
import 'package:mechanix_dialer/core/utils/helper.dart';
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

  /// Shared helper methods for managing dynamic phone and email input fields,
  /// including controller creation, automatic field addition/removal,
  /// and cleanup of redundant empty fields.
  void _addController(
    List<TextEditingController> controllers,
    void Function(TextEditingController controller) onChanged, [
    String text = '',
  ]) {
    final controller = TextEditingController(text: text);

    controller.addListener(() {
      onChanged(controller);
    });

    controllers.add(controller);
  }

  void _handleFieldChanged(
    TextEditingController controller,
    List<TextEditingController> controllers,
    VoidCallback addController,
  ) {
    final index = controllers.indexOf(controller);

    if (index == -1) return;

    if (index == controllers.length - 1 && controller.text.trim().isNotEmpty) {
      setState(addController);
    }

    _removeExtraEmptyControllers(controllers);
  }

  void _removeControllerField(
    int index,
    List<TextEditingController> controllers,
    VoidCallback addController,
  ) {
    if (controllers.length <= 1) return;

    setState(() {
      controllers[index].dispose();
      controllers.removeAt(index);

      if (controllers.isEmpty || controllers.last.text.trim().isNotEmpty) {
        addController();
      }
    });
  }

  void _removeExtraEmptyControllers(List<TextEditingController> controllers) {
    final emptyIndexes = <int>[];

    for (int i = 0; i < controllers.length; i++) {
      if (controllers[i].text.trim().isEmpty) {
        emptyIndexes.add(i);
      }
    }

    if (emptyIndexes.length <= 1) return;

    setState(() {
      for (int i = emptyIndexes.length - 2; i >= 0; i--) {
        final removeIndex = emptyIndexes[i];

        controllers[removeIndex].dispose();
        controllers.removeAt(removeIndex);
      }
    });
  }

  // Phone number field management
  void _addPhoneController([String text = '']) {
    _addController(_phoneControllers, _handlePhoneFieldChanged, text);
  }

  void _handlePhoneFieldChanged(TextEditingController controller) {
    _handleFieldChanged(controller, _phoneControllers, _addPhoneController);
  }

  void _removePhoneNumberField(int index) {
    _removeControllerField(index, _phoneControllers, _addPhoneController);
  }

  // Email field management
  void _addEmailController([String text = '']) {
    _addController(_emailControllers, _handleEmailFieldChanged, text);
  }

  void _handleEmailFieldChanged(TextEditingController controller) {
    _handleFieldChanged(controller, _emailControllers, _addEmailController);
  }

  void _removeEmailField(int index) {
    _removeControllerField(index, _emailControllers, _addEmailController);
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(isEditing ? l10n.editContact : l10n.newContact),
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
        validateEmail: (value) => validateEmail(l10n, value),
      ),
      bottomNavigationBar: ContactsFormBottomBar(onSave: _save),
    );
  }
}
