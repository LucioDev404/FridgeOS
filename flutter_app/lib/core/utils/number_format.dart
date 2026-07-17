/// Formats a quantity [amount] for display, dropping a redundant trailing
/// `.0` (e.g. `2.0 -> "2"`, `2.5 -> "2.5"`). Kept dependency-free and locale
/// -agnostic for stable, testable output.
String formatAmount(double amount) {
  if (amount == amount.roundToDouble()) {
    return amount.toInt().toString();
  }
  return amount
      .toStringAsFixed(2)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}
