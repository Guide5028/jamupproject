import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/services/musician_favorites_service.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/fade_in.dart';
import '../../../models/musician.dart';
import '../../musicians/widgets/musician_card.dart';

/// FavoriteMusiciansPage
/// ---------------------
/// Shows the musicians the current user (a venue) has hearted. It's the
/// counterpart to FavoritesPage (which shows favorited gigs).
///
/// How it stays in sync: it loads the list once via FutureBuilder, then wraps
/// the grid in a ValueListenableBuilder on the shared favorites set. So if the
/// user un-hearts a musician here, that card disappears immediately without a
/// reload — same reactive pattern as the gig favorites page.
class FavoriteMusiciansPage extends StatefulWidget {
  const FavoriteMusiciansPage({super.key});

  @override
  State<FavoriteMusiciansPage> createState() => _FavoriteMusiciansPageState();
}

class _FavoriteMusiciansPageState extends State<FavoriteMusiciansPage> {
  late Future<List<Musician>> _future;

  @override
  void initState() {
    super.initState();
    _future = _refresh();
  }

  Future<List<Musician>> _refresh() async {
    try {
      await MusicianFavoritesService.instance.loadAll();
    } catch (_) {
      // Fall back to whatever is cached if the network call fails.
    }
    return MusicianFavoritesService.instance.listFavoriteMusicians();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Favorite Musicians'),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBrown),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _future = _refresh());
          await _future;
        },
        child: FutureBuilder<List<Musician>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SkeletonCardGrid(childAspectRatio: 0.68);
            }

            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 36, color: AppColors.accentBrown),
                      const SizedBox(height: 8),
                      Text('Could not load favorites',
                          style: AppFonts.textTheme.bodyLarge),
                    ],
                  ),
                ),
              );
            }

            // Reactive to heart toggles anywhere in the app.
            return ValueListenableBuilder<Set<String>>(
              valueListenable: MusicianFavoritesService.instance.ids,
              builder: (_, favIds, __) {
                final all = snap.data ?? const <Musician>[];
                final visible =
                    all.where((m) => favIds.contains(m.id)).toList();

                if (visible.isEmpty) {
                  return const EmptyState(
                    icon: Icons.favorite_border,
                    title: 'No favorite musicians yet',
                    message:
                        'Tap the heart on any musician to save them here for quick access.',
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (_, i) => FadeInUp(
                    delay: Duration(milliseconds: (i % 6) * 60),
                    child: MusicianCard(musician: visible[i]),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

}
