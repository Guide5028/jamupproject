// ============================================================================
// favorites_page.dart   —   list of gigs the user has favorited
// ============================================================================
// Teacher notes for Guide:
//
//   • This page reads the FavoritesService cache for IDs, then fetches
//     the full Gig rows from Supabase. Why two-step? The cache only
//     stores IDs (lightweight, used for hearts). Showing full cards
//     needs title, image, location, etc., so we look those up here.
//   • We use a ValueListenableBuilder on FavoritesService.ids so that
//     toggling a heart anywhere in the app immediately removes the gig
//     from this list — no manual refresh needed.
//   • Empty state is opinionated: instead of a blank screen, we tell
//     the user how to USE the feature ("tap the heart on any gig"). A
//     well-designed empty state is half the onboarding for a feature.
// ============================================================================

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/services/favorites_service.dart';
import '../../../models/gig.dart';
import '../../gigs/widgets/gig_card.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<Gig>> _future;

  @override
  void initState() {
    super.initState();
    // Make sure the cache is fresh before listing.
    _future = _refresh();
  }

  Future<List<Gig>> _refresh() async {
    await FavoritesService.instance.loadAll();
    return FavoritesService.instance.listFavoriteGigs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBrown),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _future = _refresh());
          await _future;
        },
        child: FutureBuilder<List<Gig>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
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

            // ── Live-updated list ──────────────────────────────────
            // Even after the Future resolves, we rebuild whenever
            // FavoritesService.ids changes — so unfavoriting from this
            // page (or anywhere) instantly removes the card.
            return ValueListenableBuilder<Set<String>>(
              valueListenable: FavoritesService.instance.ids,
              builder: (_, favIds, __) {
                final all = snap.data ?? const <Gig>[];
                final visible =
                    all.where((g) => favIds.contains(g.id)).toList();

                if (visible.isEmpty) return _emptyState();

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (_, i) => GigCard(gig: visible[i]),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Empty state guides the user toward the action that fills this page.
  /// A blank screen would just confuse — "is the app broken?".
  Widget _emptyState() {
    return ListView(
      // Keep it scrollable so RefreshIndicator's pull-to-refresh works
      // even on an empty list.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      children: [
        const Center(
          child: Icon(Icons.favorite_border,
              size: 64, color: AppColors.accentBrown),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'No favorites yet',
            style: AppFonts.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Tap the heart on any gig to save it here for quick access.',
            textAlign: TextAlign.center,
            style: AppFonts.textTheme.bodyMedium?.copyWith(
              color: AppColors.accentBrown,
            ),
          ),
        ),
      ],
    );
  }
}
