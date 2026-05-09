// ============================================================================
// pay_label_test.dart
// ============================================================================
// Why this file exists (teaching note for Guide):
//
//   payLabel() is the single function that turns a raw `payment` + `unit`
//   pair into the string shown on every gig card, home page tile, and
//   detail page. It used to be duplicated in 3 files with no tests.
//
//   Now it lives in lib/core/utils/pay_label.dart and is tested here.
//   The tests pin:
//     • Each unit label suffix (/hr, /day, empty)
//     • Thousands-comma formatting (1500 → "1,500")
//     • The null/Negotiable edge case
//     • Legacy null-unit rows (behave like 'fixed')
//
//   Rule of thumb: if a bug in this function silently shows wrong pay
//   data to musicians, we want a test to catch it before code review.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:jamup_app/core/utils/pay_label.dart';

void main() {
  group('payLabel — unit suffixes', () {
    test('per_hour appends /hr', () {
      expect(payLabel(1500, 'per_hour'), '฿1,500/hr');
    });

    test('per_day appends /day', () {
      expect(payLabel(5000, 'per_day'), '฿5,000/day');
    });

    test('fixed shows amount only, no suffix', () {
      expect(payLabel(10000, 'fixed'), '฿10,000');
    });

    test('null unit (legacy row) behaves like fixed', () {
      expect(payLabel(3000, null), '฿3,000');
    });
  });

  group('payLabel — null amount', () {
    test('null payment returns "Negotiable" regardless of unit', () {
      expect(payLabel(null, 'per_hour'), 'Negotiable');
      expect(payLabel(null, 'per_day'), 'Negotiable');
      expect(payLabel(null, 'fixed'), 'Negotiable');
      expect(payLabel(null, null), 'Negotiable');
    });
  });

  group('payLabel — thousands formatting', () {
    test('amounts below 1000 have no comma', () {
      expect(payLabel(500, 'fixed'), '฿500');
      expect(payLabel(999, 'fixed'), '฿999');
    });

    test('1000 gets a comma', () {
      expect(payLabel(1000, 'fixed'), '฿1,000');
    });

    test('exactly 10000 formats as 10,000', () {
      expect(payLabel(10000, 'fixed'), '฿10,000');
    });

    test('100000 formats as 100,000', () {
      expect(payLabel(100000, 'fixed'), '฿100,000');
    });

    test('1500000 formats as 1,500,000', () {
      expect(payLabel(1500000, 'fixed'), '฿1,500,000');
    });

    test('decimal amounts are truncated to whole number', () {
      // Payment is stored as a float in Postgres; we always display an int.
      expect(payLabel(1500.9, 'fixed'), '฿1,500');
    });
  });

  group('payLabel — combined unit + formatting', () {
    test('per_hour with large amount formats correctly', () {
      expect(payLabel(12000, 'per_hour'), '฿12,000/hr');
    });

    test('per_day with large amount formats correctly', () {
      expect(payLabel(50000, 'per_day'), '฿50,000/day');
    });
  });
}
