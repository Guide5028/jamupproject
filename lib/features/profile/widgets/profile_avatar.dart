import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  final String? url;
  final double radius;

  const ProfileAvatar({super.key, this.url, this.radius = 50});

  @override
  Widget build(BuildContext context) {
    final u = (url ?? '').trim();

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: u.isNotEmpty ? NetworkImage(u) : null,
      onBackgroundImageError: u.isNotEmpty ? (_, __) {} : null,
      child: u.isEmpty
          ? Icon(
              Icons.person,
              color: AppColors.accentBrown,
              size: radius,
            )
          : null,
    );
  }
}