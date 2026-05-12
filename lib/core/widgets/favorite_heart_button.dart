
import 'package:flutter/material.dart';

import '../services/favorites_service.dart';

class FavoriteHeartButton extends StatelessWidget {
  final String gigId;
  final Color filledColor;
  final Color outlineColor;
  final bool showBackground;
  final double size;

  const FavoriteHeartButton({
    super.key,
    required this.gigId,
    this.filledColor = Colors.red,
    this.outlineColor = Colors.white,
    this.showBackground = true,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: FavoritesService.instance.ids,
      builder: (_, ids, __) {
        final isFav = ids.contains(gigId);
        final iconWidget = Icon(
          isFav ? Icons.favorite : Icons.favorite_border,
          color: isFav ? filledColor : outlineColor,
          size: size,
        );

        return InkWell(
          customBorder: const CircleBorder(),
          onTap: () => FavoritesService.instance.toggle(gigId),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: showBackground
                ? BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    shape: BoxShape.circle,
                  )
                : null,
            child: iconWidget,
          ),
        );
      },
    );
  }
}
