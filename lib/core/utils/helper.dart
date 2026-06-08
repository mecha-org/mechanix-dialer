import 'package:mechanix_dialer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatDateTime(DateTime dateTime, BuildContext context) {
  final now = DateTime.now();

  // If modified just now (within last 30 seconds)
  if (now.difference(dateTime).inSeconds.abs() < 30) {
    return AppLocalizations.of(context)!.now;
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
    return AppLocalizations.of(context)!.yesterday;
  }

  // If same year → "Nov 2"
  if (now.year == dateTime.year) {
    return DateFormat('MMM d').format(dateTime);
  }

  // If different year → "Nov 2, 2024"
  return DateFormat('MMM d, yyyy').format(dateTime);
}

String formatDuration(BuildContext context, int seconds) {
  final l10n = AppLocalizations.of(context)!;

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
