import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../filters/filter_state.dart';

const double _kMaxPrice = 50000;

void showPriceFilterSheet({
  required BuildContext context,
  required FilterState filters,
  required VoidCallback onChanged,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF121212),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _PriceFilterSheet(filters: filters, onChanged: onChanged),
  );
}

class _PriceFilterSheet extends StatefulWidget {
  final FilterState filters;
  final VoidCallback onChanged;
  const _PriceFilterSheet({required this.filters, required this.onChanged});

  @override
  State<_PriceFilterSheet> createState() => _PriceFilterSheetState();
}

class _PriceFilterSheetState extends State<_PriceFilterSheet> {
  late RangeValues _range;
  late Set<String> _units;

  static const _unitLabels = {
    'per_hour': 'Per Hour',
    'per_day': 'Per Day',
    'fixed': 'Fixed Rate',
  };

  @override
  void initState() {
    super.initState();
    _range = RangeValues(
      widget.filters.priceMin ?? 0,
      widget.filters.priceMax ?? _kMaxPrice,
    );
    _units = Set.from(widget.filters.paymentUnits);
  }

  String _fmt(double v) {
    if (v >= 1000) {
      final k = v / 1000;
      return k == k.truncateToDouble() ? '${k.toInt()}k' : '${k.toStringAsFixed(1)}k';
    }
    return v.toInt().toString();
  }

  void _apply() {
    final isFullRange = _range.start == 0 && _range.end == _kMaxPrice;
    widget.filters.priceMin = isFullRange ? null : _range.start;
    widget.filters.priceMax = isFullRange ? null : _range.end;
    widget.filters.paymentUnits
      ..clear()
      ..addAll(_units);
    widget.onChanged();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Price Filter',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // --- Payment unit chips ---
          const Text(
            'Payment Type',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: _unitLabels.entries.map((e) {
              final selected = _units.contains(e.key);
              return FilterChip(
                label: Text(e.value),
                selected: selected,
                onSelected: (_) => setState(() {
                  if (selected) {
                    _units.remove(e.key);
                  } else {
                    _units.add(e.key);
                  }
                }),
                selectedColor: AppColors.primaryGold,
                checkmarkColor: AppColors.darkBrown,
                labelStyle: TextStyle(
                  color: selected ? AppColors.darkBrown : Colors.white,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: const Color(0xFF2A2A2A),
                side: BorderSide(
                  color: selected ? AppColors.primaryGold : Colors.white24,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // --- Range slider ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Price Range',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                _range.end >= _kMaxPrice
                    ? '฿${_fmt(_range.start)} – ฿${_fmt(_kMaxPrice)}+'
                    : '฿${_fmt(_range.start)} – ฿${_fmt(_range.end)}',
                style: const TextStyle(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primaryGold,
              inactiveTrackColor: Colors.white12,
              thumbColor: AppColors.primaryGold,
              overlayColor: AppColors.primaryGold.withOpacity(0.2),
              valueIndicatorColor: AppColors.primaryGold,
            ),
            child: RangeSlider(
              values: _range,
              min: 0,
              max: _kMaxPrice,
              divisions: 100,
              onChanged: (v) => setState(() => _range = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('฿0', style: TextStyle(color: Colors.white38, fontSize: 11)),
              Text('฿50,000+',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),

          const SizedBox(height: 28),

          // --- Buttons ---
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _range = const RangeValues(0, _kMaxPrice);
                      _units.clear();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    foregroundColor: Colors.white70,
                  ),
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: AppColors.darkBrown,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
