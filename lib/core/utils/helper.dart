import 'package:mechanix_dialer/core/utils/enums.dart';
import 'package:mechanix_dialer/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

String formatDateTime(AppLocalizations l10n, DateTime dateTime) {
  final now = DateTime.now();

  // If modified just now (within last 30 seconds)
  if (now.difference(dateTime).inSeconds.abs() < 30) {
    return l10n.now;
  }

  final yesterday = now.subtract(const Duration(days: 1));

  final isToday =
      now.year == dateTime.year &&
      now.month == dateTime.month &&
      now.day == dateTime.day;

  final isYesterday =
      yesterday.year == dateTime.year &&
      yesterday.month == dateTime.month &&
      yesterday.day == dateTime.day;

  final time24 = DateFormat('HH:mm').format(dateTime);

  if (isToday) {
    return time24;
  } else if (isYesterday) {
    return l10n.yesterday;
  }

  // If same year → "Nov 2"
  if (now.year == dateTime.year) {
    return DateFormat('MMM d').format(dateTime);
  }

  // If different year → "Nov 2, 2024"
  return DateFormat('MMM d, yyyy').format(dateTime);
}

String formatDuration(AppLocalizations l10n, int seconds) {
  if (seconds < 60) {
    return l10n.durationSeconds(seconds);
  }

  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;

  if (seconds < 3600) {
    return remainingSeconds == 0
        ? l10n.durationMinutes(minutes)
        : l10n.durationMinutesSeconds(minutes, remainingSeconds);
  }

  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;

  return remainingSeconds == 0
      ? l10n.durationHoursMinutes(hours, remainingMinutes)
      : l10n.durationHoursMinutesSeconds(
          hours,
          remainingMinutes,
          remainingSeconds,
        );
}

String getInitials(String name) {
  if (name.isEmpty) return "";
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length > 1) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  return name[0].toUpperCase();
}

String? validateEmail(AppLocalizations l10n, String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  final email = value.trim();

  const pattern = r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';

  if (!RegExp(pattern).hasMatch(email)) {
    return l10n.invalidEmail;
  }

  return null;
}

String? validatePhoneNumber(AppLocalizations l10n, String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  final cleanVal = value.trim();

  // Basic regex check for allowed characters (digits, spaces, -, (, ), +)
  final allowedCharsRegex = RegExp(r'^[0-9\s\-()+]*$');
  if (!allowedCharsRegex.hasMatch(cleanVal)) {
    return l10n.invalidPhoneNumber;
  }

  // Check plus sign position and count (only one optional leading plus)
  final plusCount = cleanVal.split('+').length - 1;
  if (plusCount > 1 || (plusCount == 1 && !cleanVal.startsWith('+'))) {
    return l10n.invalidPhoneNumberFormat;
  }

  // Check parentheses balance and count (at most one pair of matching parentheses)
  final openParenCount = cleanVal.split('(').length - 1;
  final closeParenCount = cleanVal.split(')').length - 1;
  if (openParenCount != closeParenCount || openParenCount > 1) {
    return l10n.invalidPhoneNumberFormat;
  }
  if (openParenCount == 1) {
    final openIndex = cleanVal.indexOf('(');
    final closeIndex = cleanVal.indexOf(')');
    if (openIndex > closeIndex) {
      return l10n.invalidPhoneNumberFormat;
    }
  }

  // Check for consecutive symbols like '--' or '  '
  if (cleanVal.contains('--') || cleanVal.contains('  ')) {
    return l10n.invalidPhoneNumberFormat;
  }

  // Must start with a digit, '+', or '('
  if (!RegExp(r'^[0-9+(]').hasMatch(cleanVal)) {
    return l10n.invalidPhoneNumberFormat;
  }

  // Must end with a digit or ')'
  if (!RegExp(r'[0-9)]$').hasMatch(cleanVal)) {
    return l10n.invalidPhoneNumberFormat;
  }

  final digitsOnly = cleanVal.replaceAll(RegExp(r'\D'), '');
  if (digitsOnly.length < 3) {
    return l10n.phoneNumberTooShort;
  }

  if (digitsOnly.length > 15) {
    return l10n.invalidPhoneNumberFormat;
  }

  // If number of digits is 7 or more and starts with a plus sign, validate using phone_numbers_parser
  if (digitsOnly.length >= 7 && cleanVal.startsWith('+')) {
    try {
      final phoneNumber = PhoneNumber.parse(cleanVal);

      if (!phoneNumber.isValid()) {
        return l10n.invalidPhoneNumberFormat;
      }
    } catch (_) {
      return l10n.invalidPhoneNumberFormat;
    }
  }

  return null;
}

String getErrorMessage(AppLocalizations l10n, ContactsError error) {
  switch (error) {
    case ContactsError.loadFailed:
      return l10n.failedToLoadContacts;

    case ContactsError.saveFailed:
      return l10n.failedToSaveContact;

    case ContactsError.deleteFailed:
      return l10n.failedToDeleteContact;

    case ContactsError.updateFailed:
      return l10n.failedToUpdateContact;

    case ContactsError.storeUnavailable:
      return l10n.contactsDatabaseUnavailable;

    case ContactsError.unknown:
      return l10n.somethingWentWrong;

    case ContactsError.searchFailed:
      return l10n.failedToSearchContact;

    case ContactsError.duplicateContact:
      return l10n.contactAlreadyExists;
  }
}
