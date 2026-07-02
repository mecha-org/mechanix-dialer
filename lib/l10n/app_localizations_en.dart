// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get contacts => 'Contacts';

  @override
  String get recentCalls => 'Recent calls';

  @override
  String get allCalls => 'All';

  @override
  String get missedCalls => 'Missed';

  @override
  String get searchInCallLog => 'Search in call log';

  @override
  String get call => 'Call';

  @override
  String get message => 'Message';

  @override
  String get noRecentCalls => 'No recent calls found';

  @override
  String get now => 'Now';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get deleteContactTitle => 'Delete contact?';

  @override
  String deleteContactConfirmation(String name) {
    return 'Are you sure you want to delete \'$name\'?';
  }

  @override
  String get editContact => 'Edit contact';

  @override
  String get newContact => 'New contact';

  @override
  String get save => 'Save';

  @override
  String get deleteContact => 'Delete contact';

  @override
  String get name => 'Name';

  @override
  String get enterName => 'Enter name';

  @override
  String get pleaseEnterName => 'Please enter a name';

  @override
  String get phoneNumbers => 'Phone numbers';

  @override
  String get addNumber => 'Add number';

  @override
  String get enterPhoneNumber => 'Enter phone number';

  @override
  String get pleaseEnterAtLeastOnePhoneNumber =>
      'Please enter at least one phone number.';

  @override
  String get contact => 'Contact';

  @override
  String get callHistory => 'Call history';

  @override
  String get incomingCall => 'Incoming call';

  @override
  String get outgoingCall => 'Outgoing call';

  @override
  String get missedCall => 'Missed call';

  @override
  String get cancelledCall => 'Cancelled call';

  @override
  String get blockedCall => 'Blocked call';

  @override
  String durationSeconds(int count) {
    return '${count}s';
  }

  @override
  String durationMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '${minutes}m ${seconds}s';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String durationHoursMinutesSeconds(int hours, int minutes, int seconds) {
    return '${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String get invalidPhoneNumber =>
      'Please enter a valid phone number using digits and +, -, (, )';

  @override
  String get invalidPhoneNumberFormat => 'Please enter a valid phone number';

  @override
  String get phoneNumberTooShort => 'Please enter at least 3 digits';

  @override
  String get searchInContacts => 'Search in contacts';

  @override
  String get myCard => 'My card';

  @override
  String get noContactsFound => 'No contacts found';

  @override
  String get noPhoneNumbers => 'No phone numbers';

  @override
  String get contactAlphabet => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ#';

  @override
  String get emails => 'Emails';

  @override
  String get enterEmailAddress => 'Enter email address';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get preferredLine => 'Preferred line';

  @override
  String get calling => 'Calling...';

  @override
  String get callCancelled => 'Call cancelled';

  @override
  String get selectPreferredLine => 'Select preferred line';

  @override
  String get nameTooShort => 'Name must contain at least 2 characters';

  @override
  String get invalidName => 'Please enter a valid name';

  @override
  String nameTooLong(int maxLength) {
    return 'Name cannot exceed $maxLength characters';
  }

  @override
  String get failedToLoadContacts => 'Failed to load contacts';

  @override
  String get failedToSaveContact => 'Failed to save contact';

  @override
  String get failedToDeleteContact => 'Failed to delete contact';

  @override
  String get failedToUpdateContact => 'Failed to update contact';

  @override
  String get contactsDatabaseUnavailable => 'Contacts database is unavailable';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get failedToSearchContact => 'Failed to search contact';

  @override
  String get contactAlreadyExists =>
      'A contact with this name and phone number already exists';
}
