import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class MusicianFilterBar extends StatelessWidget {
  final VoidCallback onGenreTap;
  final VoidCallback onTypeTap;
  final VoidCallback onLocationTap;
  final VoidCallback onPriceTap;
  
  final bool genreActive;
  final bool typeActive;
  final bool locationActive;
  final bool priceActive;

  const MusicianFilterBar({
    super.key,
    required this.onGenreTap,
    required this.onTypeTap,
    required this.onLocationTap,
    required this.onPriceTap,
    required this.genreActive,
    required this.typeActive,
    required this.locationActive,
    required this.priceActive,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip("Genre", Icons.music_note, onGenreTap, genreActive),
          _chip("Type", Icons.group, onTypeTap, typeActive),
          _chip("Location", Icons.location_on, onLocationTap, locationActive),
          _chip("Price", Icons.attach_money, onPriceTap, priceActive),
        ],
      ),
    );
  }
  
  Widget _chip(
    
    String label,
    IconData icon,
    VoidCallback onTap,
    bool active,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                active ? AppColors.primaryGold : Colors.black.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: active ? Colors.white : AppColors.darkBrown,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: active ? Colors.white : AppColors.darkBrown,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 14,
                color: active ? Colors.white : AppColors.darkBrown,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
