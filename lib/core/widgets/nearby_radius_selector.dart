import 'package:flutter/material.dart';
import 'package:jamup_app/core/constants/app_colors.dart';
import 'package:jamup_app/core/constants/app_fonts.dart';

// A reusable bottom sheet that lets the user pick a search radius.
// Reusable because both the gigs page AND musicians page need it.
// That's why it lives in core/widgets/ not inside a feature.

class NearbyRadiusSelector extends StatefulWidget {
  final double initialRadius;
  final ValueChanged<double> onChanged;

  const NearbyRadiusSelector({
    super.key,
    required this.initialRadius,
    required this.onChanged,
  });

  @override
  State<NearbyRadiusSelector> createState() => _NearbyRadiusSelectorState();

  // Static helper — call this to show the bottom sheet from anywhere
  static void show(
    BuildContext context, {
    required double currentRadius,
    required ValueChanged<double> onChanged,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => NearbyRadiusSelector(
        initialRadius: currentRadius,
        onChanged: onChanged,
      ),
    );
  }
}

class _NearbyRadiusSelectorState extends State<NearbyRadiusSelector> {
  late double _radius;

  @override
  void initState() {
    super.initState();
    _radius = widget.initialRadius;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Search radius', style: AppFonts.textTheme.headlineMedium),
          const SizedBox(height: 20),

          // Large radius display
          Text(
            '${_radius.toStringAsFixed(0)} km',
            style: AppFonts.textTheme.headlineLarge?.copyWith(
              color: AppColors.primaryGold,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 8),

          // Slider from 5km to 100km
          Slider(
            value: _radius,
            min: 5,
            max: 100,
            divisions: 19,       // snaps to 5, 10, 15... 100
            activeColor: AppColors.primaryGold,
            inactiveColor: AppColors.accentBrown.withOpacity(0.3),
            onChanged: (val) => setState(() => _radius = val),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('5 km', style: AppFonts.textTheme.bodyMedium),
              Text('100 km', style: AppFonts.textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 20),

          // Apply button — notifies parent then closes sheet
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                widget.onChanged(_radius);  // tell parent the new value
                Navigator.pop(context);
              },
              child: const Text(
                'Apply',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}