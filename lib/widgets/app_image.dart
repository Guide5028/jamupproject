import 'package:flutter/material.dart';

class AppImage extends StatelessWidget {
  final String imageUrl;
  final double borderRadius;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AppImage({
    super.key,
    required this.imageUrl,
    this.borderRadius = 8,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final isAsset = !imageUrl.startsWith("http");

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: isAsset
          ? Image.asset(
              imageUrl,
              width: width,
              height: height,
              fit: fit,
            )
          : Image.network(
              imageUrl,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
            ),
    );
  }
}
