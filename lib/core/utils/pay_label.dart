String payLabel(double? amount, String? unit) {
  if (amount == null) return 'Negotiable';
  final formatted = _formatAmount(amount);
  switch (unit) {
    case 'per_hour':
      return '฿$formatted/hr';
    case 'per_day':
      return '฿$formatted/day';
    default: // 'fixed' or legacy null rows
      return '฿$formatted';
  }
}

String _formatAmount(double amount) {
  final s = amount.toInt().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Parses a user-typed price-offer amount (in-app chat "Send Offer" field).
/// Returns null for anything that isn't a usable positive number, so the
/// caller can disable the send button instead of inserting a junk/zero offer.
double? parseOfferAmount(String input) {
  final value = double.tryParse(input.trim());
  if (value == null || value <= 0) return null;
  return value;
}

/// Human-readable label for a unit key, used on the offer-composer chips.
/// Kept alongside payLabel() since both describe the same 'per_hour' /
/// 'per_day' / 'fixed' vocabulary used by the Gig model.
String offerUnitLabel(String unit) {
  switch (unit) {
    case 'per_hour':
      return 'Per Hour';
    case 'per_day':
      return 'Per Day';
    default:
      return 'Fixed';
  }
}
