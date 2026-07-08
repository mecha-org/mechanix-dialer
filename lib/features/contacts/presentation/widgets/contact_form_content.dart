import 'dart:ui';

import 'package:mechanix_dialer/core/constants/app_constants.dart';
import 'package:mechanix_dialer/core/theme/app_theme.dart';
import 'package:mechanix_dialer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ContactFormContent extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;

  final List<TextEditingController> phoneControllers;
  final List<TextEditingController> emailControllers;

  final VoidCallback onAddPhone;
  final ValueChanged<int> onRemovePhone;

  final VoidCallback onAddEmail;
  final ValueChanged<int> onRemoveEmail;

  final String? Function(String?) validateEmail;
  final String? Function(String?) validatePhone;

  const ContactFormContent({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.phoneControllers,
    required this.emailControllers,
    required this.onAddPhone,
    required this.onRemovePhone,
    required this.onAddEmail,
    required this.onRemoveEmail,
    required this.validateEmail,
    required this.validatePhone,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _NameField(controller: nameController),

            const SizedBox(height: 24),

            Text(
              AppLocalizations.of(context)!.phoneNumbers,
              style: Theme.of(context).textTheme.labelMedium,
            ),

            const SizedBox(height: 8),

            ...List.generate(phoneControllers.length, (index) {
              final controller = phoneControllers[index];

              return _PhoneField(
                key: ValueKey(controller),
                controller: controller,
                validator: validatePhone,
                onAdd: onAddPhone,
                onRemove: () => onRemovePhone(index),
                isLast: index == phoneControllers.length - 1,
              );
            }),

            const SizedBox(height: 24),

            Text(
              AppLocalizations.of(context)!.emails,
              style: Theme.of(context).textTheme.labelMedium,
            ),

            const SizedBox(height: 8),

            ...List.generate(emailControllers.length, (index) {
              final controller = emailControllers[index];

              return _EmailField(
                key: ValueKey(controller),
                controller: controller,
                validator: validateEmail,
                onAdd: onAddEmail,
                onRemove: () => onRemoveEmail(index),
                isLast: index == emailControllers.length - 1,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  final TextEditingController controller;

  const _NameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
        hintText: AppLocalizations.of(context)!.enterName,
        hintStyle: const TextStyle(color: AppColors.onSurfaceVariantDark),
        filled: true,
        fillColor: AppColors.backgroundVariantDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      style: const TextStyle(color: AppColors.onSurface),
      validator: (value) {
        final name = value?.trim() ?? '';

        if (name.isEmpty) {
          return l10n.pleaseEnterName;
        }

        if (name.length < 2) {
          return l10n.nameTooShort;
        }

        if (name.length > AppConstants.maxContactNameLength) {
          return l10n.nameTooLong(AppConstants.maxContactNameLength);
        }

        // Must start with a letter
        if (!RegExp(r'^[A-Za-zÀ-ÿ]').hasMatch(name)) {
          return l10n.invalidName;
        }

        // Allow letters, digits, spaces and common punctuation
        final allowedChars = RegExp(r"^[A-Za-zÀ-ÿ0-9\s'.()\-&_#]+$");
        if (!allowedChars.hasMatch(name)) {
          return l10n.invalidName;
        }

        // Must contain at least one letter
        if (!RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(name)) {
          return l10n.invalidName;
        }

        return null;
      },
    );
  }
}

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?) validator;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final bool isLast;

  const _PhoneField({
    super.key,
    required this.controller,
    required this.validator,
    required this.onAdd,
    required this.onRemove,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.enterPhoneNumber,
                hintStyle: const TextStyle(
                  color: AppColors.onSurfaceVariantDark,
                ),
                filled: true,
                fillColor: AppColors.backgroundVariantDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(color: AppColors.onSurface),
              validator: validator,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              isLast ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: isLast ? Colors.blue : Colors.redAccent,
            ),
            onPressed: isLast ? onAdd : onRemove,
          ),
        ],
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?) validator;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final bool isLast;

  const _EmailField({
    super.key,
    required this.controller,
    required this.validator,
    required this.onAdd,
    required this.onRemove,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.enterEmailAddress,
                hintStyle: const TextStyle(
                  color: AppColors.onSurfaceVariantDark,
                ),
                filled: true,
                fillColor: AppColors.backgroundVariantDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: validator,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              isLast ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: isLast ? Colors.blue : Colors.redAccent,
            ),
            onPressed: isLast ? onAdd : onRemove,
          ),
        ],
      ),
    );
  }
}
