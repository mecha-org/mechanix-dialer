import 'dart:ui';

import 'package:dialer/core/constants/app_constants.dart';
import 'package:dialer/core/theme/app_theme.dart';
import 'package:dialer/l10n/app_localizations.dart';
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
                controller: controller,
                onAdd: onAddPhone,
                onRemove: () => onRemovePhone(index),
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
                controller: controller,
                validator: validateEmail,
                onAdd: onAddEmail,
                onRemove: () => onRemoveEmail(index),
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
          return AppLocalizations.of(context)!.pleaseEnterName;
        }

        if (name.length < 2) {
          return AppLocalizations.of(context)!.nameTooShort;
        }

        final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s'.-]+$");

        if (!nameRegex.hasMatch(name)) {
          return AppLocalizations.of(context)!.invalidName;
        }

        if (name.length > AppConstants.maxContactLength) {
          return AppLocalizations.of(
            context,
          )!.nameTooLong(AppConstants.maxContactLength);
        }

        return null;
      },
    );
  }
}

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _PhoneField({
    required this.controller,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isEmptyField = controller.text.trim().isEmpty;

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
              validator: (value) {
                if (isEmptyField) return null;

                final cleanVal = value!.trim();

                final allowedCharsRegex = RegExp(r'^[0-9\s\-()+]*$');

                if (!allowedCharsRegex.hasMatch(cleanVal)) {
                  return AppLocalizations.of(context)!.invalidPhoneNumber;
                }

                final digitsOnly = cleanVal.replaceAll(RegExp(r'\D'), '');

                if (digitsOnly.length < 3) {
                  return AppLocalizations.of(context)!.phoneNumberTooShort;
                }

                return null;
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              isEmptyField
                  ? Icons.add_circle_outline
                  : Icons.remove_circle_outline,
              color: isEmptyField ? Colors.blue : Colors.redAccent,
            ),
            onPressed: isEmptyField ? onAdd : onRemove,
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

  const _EmailField({
    required this.controller,
    required this.validator,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isEmptyField = controller.text.trim().isEmpty;

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
              isEmptyField
                  ? Icons.add_circle_outline
                  : Icons.remove_circle_outline,
              color: isEmptyField ? Colors.blue : Colors.redAccent,
            ),
            onPressed: isEmptyField ? onAdd : onRemove,
          ),
        ],
      ),
    );
  }
}
