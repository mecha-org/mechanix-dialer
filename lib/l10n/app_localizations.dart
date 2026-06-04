import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// No description provided for @recentCalls.
  ///
  /// In en, this message translates to:
  /// **'Recent calls'**
  String get recentCalls;

  /// No description provided for @allCalls.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCalls;

  /// No description provided for @missedCalls.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get missedCalls;

  /// No description provided for @searchInCallLog.
  ///
  /// In en, this message translates to:
  /// **'Search in call log'**
  String get searchInCallLog;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @noRecentCalls.
  ///
  /// In en, this message translates to:
  /// **'No recent calls found'**
  String get noRecentCalls;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete contact?'**
  String get deleteContactTitle;

  /// No description provided for @deleteContactConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \'{name}\'?'**
  String deleteContactConfirmation(String name);

  /// No description provided for @editContact.
  ///
  /// In en, this message translates to:
  /// **'Edit contact'**
  String get editContact;

  /// No description provided for @newContact.
  ///
  /// In en, this message translates to:
  /// **'New contact'**
  String get newContact;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @deleteContact.
  ///
  /// In en, this message translates to:
  /// **'Delete contact'**
  String get deleteContact;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter name'**
  String get enterName;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get pleaseEnterName;

  /// No description provided for @phoneNumbers.
  ///
  /// In en, this message translates to:
  /// **'Phone numbers'**
  String get phoneNumbers;

  /// No description provided for @addNumber.
  ///
  /// In en, this message translates to:
  /// **'Add number'**
  String get addNumber;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enterPhoneNumber;

  /// No description provided for @pleaseEnterAtLeastOnePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter at least one phone number.'**
  String get pleaseEnterAtLeastOnePhoneNumber;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @callHistory.
  ///
  /// In en, this message translates to:
  /// **'Call history'**
  String get callHistory;

  /// Shown when there is an incoming call
  ///
  /// In en, this message translates to:
  /// **'Incoming call'**
  String get incomingCall;

  /// No description provided for @outgoingCall.
  ///
  /// In en, this message translates to:
  /// **'Outgoing call'**
  String get outgoingCall;

  /// No description provided for @missedCall.
  ///
  /// In en, this message translates to:
  /// **'Missed call'**
  String get missedCall;

  /// No description provided for @cancelledCall.
  ///
  /// In en, this message translates to:
  /// **'Cancelled call'**
  String get cancelledCall;

  /// No description provided for @blockedCall.
  ///
  /// In en, this message translates to:
  /// **'Blocked call'**
  String get blockedCall;

  /// Duration displayed in seconds
  ///
  /// In en, this message translates to:
  /// **'{count}s'**
  String durationSeconds(int count);

  /// Duration displayed in minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String durationMinutes(int minutes);

  /// Duration displayed in minutes and seconds
  ///
  /// In en, this message translates to:
  /// **'{minutes}m {seconds}s'**
  String durationMinutesSeconds(int minutes, int seconds);

  /// Duration displayed in hours and minutes
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String durationHoursMinutes(int hours, int minutes);

  /// Duration displayed in hours, minutes and seconds
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m {seconds}s'**
  String durationHoursMinutesSeconds(int hours, int minutes, int seconds);

  /// Shown when a phone number contains invalid characters
  ///
  /// In en, this message translates to:
  /// **'Only numbers and symbols (+, -, (, )) are allowed'**
  String get invalidPhoneNumber;

  /// Shown when a phone number is too short
  ///
  /// In en, this message translates to:
  /// **'Please enter at least 3 digits'**
  String get phoneNumberTooShort;

  /// No description provided for @searchInContacts.
  ///
  /// In en, this message translates to:
  /// **'Search in contacts'**
  String get searchInContacts;

  /// No description provided for @myCard.
  ///
  /// In en, this message translates to:
  /// **'My card'**
  String get myCard;

  /// No description provided for @noContactsFound.
  ///
  /// In en, this message translates to:
  /// **'No contacts found'**
  String get noContactsFound;

  /// No description provided for @noPhoneNumbers.
  ///
  /// In en, this message translates to:
  /// **'No phone numbers'**
  String get noPhoneNumbers;

  /// Alphabet used for contact list indexing
  ///
  /// In en, this message translates to:
  /// **'ABCDEFGHIJKLMNOPQRSTUVWXYZ#'**
  String get contactAlphabet;

  /// No description provided for @emails.
  ///
  /// In en, this message translates to:
  /// **'Emails'**
  String get emails;

  /// No description provided for @enterEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter email address'**
  String get enterEmailAddress;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @preferredLine.
  ///
  /// In en, this message translates to:
  /// **'Preferred line'**
  String get preferredLine;

  /// Shown when an outgoing call is being placed
  ///
  /// In en, this message translates to:
  /// **'Calling...'**
  String get calling;

  /// Shown when a call was cancelled
  ///
  /// In en, this message translates to:
  /// **'Call cancelled'**
  String get callCancelled;

  /// Dialog title for selecting preferred phone line
  ///
  /// In en, this message translates to:
  /// **'Select preferred line'**
  String get selectPreferredLine;

  /// Validation message shown when contact name is too short
  ///
  /// In en, this message translates to:
  /// **'Name must contain at least 2 characters'**
  String get nameTooShort;

  /// Validation message shown when contact name contains invalid characters
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid name'**
  String get invalidName;

  /// Validation message shown when contact name exceeds maximum length
  ///
  /// In en, this message translates to:
  /// **'Name cannot exceed {maxLength} characters'**
  String nameTooLong(int maxLength);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
