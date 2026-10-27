/// Number helpers shared by the listing cards, the Listing Details screen and
/// the Create Listing price field.
///
/// Keeping one implementation means a price the user typed and the same price
/// read back from the database are always rendered identically.
class PriceFormatter {
  const PriceFormatter._();

  /// Groups digits in threes with commas: `1500000` → `1,500,000`.
  static String group(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Groups a numeric amount: whole numbers keep no decimal part, anything
  /// else is rounded to whole units because Loqta's prices are whole Syrian
  /// pounds.
  static String groupAmount(double value) {
    if (value == value.roundToDouble()) return group(value.round().toString());
    return group(value.toStringAsFixed(0));
  }

  /// Parses what the user typed — digits with optional grouping commas or
  /// spaces — into an amount.
  ///
  /// Returns null when the text is empty or is not a plain positive number, so
  /// callers report "enter a price" rather than silently publishing zero.
  static double? parse(String raw) {
    final cleaned = normalize(raw);
    if (cleaned.isEmpty) return null;
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(cleaned)) return null;
    return double.tryParse(cleaned);
  }

  /// Removes grouping characters, leaving the bare digits behind.
  static String normalize(String raw) =>
      raw.replaceAll(RegExp(r'[,\s]'), '').trim();
}
