// ============================================================================
// favorite_heart_button.dart   —   reactive heart icon for any gig
// ============================================================================
// Teacher notes for Guide:
//
//   • Drop this anywhere you have a gigId. It will:
//     - Show outline heart when not favorited, filled heart when favorited
//     - Toggle on tap, with optimistic UI from FavoritesService
//     - Rebuild itself automatically when ANY heart in the app changes
//       (because they all listen to the same ValueNotifier)
//   • Why ValueListenableBuilder? It's the lightest reactive primitive
//     in Flutter — no Provider needed. The builder runs only when the
//     wrapped ValueNotifier emits a new value.
//   • The widget is stateless because all the state lives in the service.
//     Stateless + reactive = small, testable, no lifecycle bugs.
// ============================================================================

import 'package:flutter/material.dart';

import '../services/favorites_service.dart';

class FavoriteHeartButton extends StatelessWidget {
  final String gigId;
  /// Color of the filled (favorited) heart.
  final Color filledColor;
  /// Color of the outline (not-favorited) heart.
  final Color outlineColor;
  /// Optional background bubble (used on photo overlays for legibility).
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
