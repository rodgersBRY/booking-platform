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
