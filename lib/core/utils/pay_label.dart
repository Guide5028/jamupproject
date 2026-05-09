// ============================================================================
// pay_label.dart  —  Shared formatter for musician pay amounts
// ============================================================================
// Why a standalone util?
//
//   The same formatting logic was duplicated across GigCard, HomePage, and
//   GigDetailPage. Centralising it means:
//     1. One place to change the format (e.g. "hr" → "hour").
//     2. The logic is testable without spinning up a widget tree.
//     3. No silent drift where one file shows "฿1,500/hr" and another
//        shows "฿1500/hr".
// ============================================================================

/// Returns a human-readable pay label for a gig, e.g.:
///   payLabel(1500, 'per_hour') → "฿1,500/hr"
///   payLabel(5000, 'per_day')  → "฿5,000/day"
///   payLabel(10000, 'fixed')   → "฿10,000"
///   payLabel(null,  any)       → "Negotiable"
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

/// Formats a non-negative number with thousands commas and no decimals.
///   1500    → "1,500"
///   10000   → "10,000"
///   999     → "999"
String _formatAmount(double amount) {
  final s = amount.toInt().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
