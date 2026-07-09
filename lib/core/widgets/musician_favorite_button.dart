import 'package:flutter/material.dart';

import '../services/musician_favorites_service.dart';

/// MusicianFavoriteButton
/// ----------------------
/// A tappable heart bound to MusicianFavoritesService. Drop it onto any
/// musician card or profile and pass the musician's id.
///
/// It rebuilds automatically whenever the favorites set changes (anywhere in
/// the app) because it listens to the service's ValueNotifier. That's why we
/// don't store any local `isFav` state here — the service is the single
/// source of truth.
class MusicianFavoriteButton extends StatelessWidget {
  final String musicianId;
  final Color filledColor;
  final Color outlineColor;
  final bool showBackground;
  final double size;

  const MusicianFavoriteButton({
    super.key,
    required this.musicianId,
    this.filledColor = Colors.red,
    this.outlineColor = Colors.white,
    this.showBackground = true,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: MusicianFavoritesService.instance.ids,
      builder: (_, ids, __) {
        final isFav = ids.contains(musicianId);

        return InkWell(
          customBorder: const CircleBorder(),
          onTap: () async {
            try {
              await MusicianFavoritesService.instance.toggle(musicianId);
            } catch (_) {
              // toggle() already rolled back the heart; just tell the user.
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not update favorite. Try again.'),
                  ),
                );
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: showBackground
                ? BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    shape: BoxShape.circle,
                  )
                : null,
            // AnimatedSwitcher + back-eased scale = a satisfying "pop" when the
            // heart toggles. ValueKey(isFav) triggers the animated swap.
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: Tween<double>(begin: 0.6, end: 1.0).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                ),
                child: child,
              ),
              child: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(isFav),
                color: isFav ? filledColor : outlineColor,
                size: size,
              ),
            ),
          ),
        );
      },
    );
  }
}
