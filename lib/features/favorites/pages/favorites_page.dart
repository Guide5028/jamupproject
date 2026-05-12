
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
    _future = _refresh();
  }

  Future<List<Gig>> _refresh() async {
    try {
      await FavoritesService.instance.loadAll();
    } catch (_) {
      // Return cached result on network failure
    }
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

            // Favorites Grid — reactive to heart toggles across the app
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

  // Empty State
  Widget _emptyState() {
    return ListView(
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
