import 'dart:io';

class AppConstants {
  static const int maxContactNameLength = 100;
  static const int recentCallsPageSize = 30;
  static final home = Platform.environment['HOME'];
  static final dialerStoreDir = Directory(
    '$home/.config/mechanix_apps/dialer/objectbox',
  );
}
