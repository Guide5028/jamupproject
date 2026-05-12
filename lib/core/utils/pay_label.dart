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
