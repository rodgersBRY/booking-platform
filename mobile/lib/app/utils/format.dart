import '../modules/booking/booking_controller.dart' show otherCategoryKey;

/// "hair_dyes" -> "Hair Dyes". [otherCategoryKey] -> "Other".
String categoryLabel(String key) {
  if (key == otherCategoryKey) return 'Other';
  return key
      .split('_')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

/// Humanizes a date into a relative label — "Today", "Yesterday",
/// "3 Days Ago", "2 Weeks Ago", "4 Months Ago", "1 Year Ago" — per
/// BARBER-APP.md's Customers tab card example ("Last Visit / 2 Weeks
/// Ago"). Compares calendar days, not wall-clock hours, so a visit
/// earlier today never reads as anything but "Today" regardless of what
/// time it is now.
String relativeDateLabel(DateTime date, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final target = DateTime(date.year, date.month, date.day);
  final days = today.difference(target).inDays;

  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days < 7) return '$days Days Ago';
  if (days < 30) {
    final weeks = (days / 7).floor();
    return weeks == 1 ? '1 Week Ago' : '$weeks Weeks Ago';
  }
  if (days < 365) {
    final months = (days / 30).floor();
    return months == 1 ? '1 Month Ago' : '$months Months Ago';
  }
  final years = (days / 365).floor();
  return years == 1 ? '1 Year Ago' : '$years Years Ago';
}
