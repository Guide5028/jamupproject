// ============================================================================
// portfolio_grid.dart   —   Musician's photo + video gallery
// ============================================================================
// Teacher notes for Guide:
//  • This widget is shared by BOTH profile_page.dart (your own) AND
//    musician_detail_page.dart (a venue viewing a musician). That's why
//    it lives in core/widgets/ — the rule I taught earlier: if 2+ features
//    need a widget, it belongs in core/.
//  • `Image.network` has THREE builders: loading / error / main. Without
//    a `loadingBuilder` the tile is blank until the image arrives, which
//    looks broken on slow networks.
//  • Videos don't have native Flutter thumbnail support without an extra
//    package (video_thumbnail). For your MVP we show a branded placeholder
//    with a play icon, which is what Instagram/TikTok do on low-bandwidth.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:jamup_app/core/constants/app_colors.dart';
import 'package:jamup_app/core/constants/app_fonts.dart';
import 'package:jamup_app/core/services/portfolio_service.dart';

class PortfolioGrid extends StatefulWidget {
  final String userId;
  final bool showDeleteButton;

  const PortfolioGrid({
    super.key,
    required this.userId,
    this.showDeleteButton = false,
  });

  @override
  State<PortfolioGrid> createState() => _PortfolioGridState();
}

class _PortfolioGridState extends State<PortfolioGrid> {
  final _service = PortfolioService();

  // Changing this key forces FutureBuilder to re-run (used after upload/delete).
  Key _key = UniqueKey();
  void refresh() => setState(() => _key = UniqueKey());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: _key,
      future: _service.fetchPortfolio(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Could not load portfolio.',
              style: AppFonts.textTheme.bodyMedium,
            ),
          );
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No portfolio items yet.',
              style: AppFonts.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.accentBrown),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          // MUST be NeverScrollable because this grid lives inside a
          // parent ListView. Two scrollables stacked = fight over gestures.
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final item = items[i];
            return _PortfolioTile(
              item: item,
              showDelete: widget.showDeleteButton,
              onDelete: () async {
                await _service.deletePortfolioItem(
                  portfolioId: item['id'],
                  mediaUrl: item['media_url'],
                  userId: widget.userId,
                );
                refresh();
              },
            );
          },
        );
      },
    );
  }
}

class _PortfolioTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool showDelete;
  final VoidCallback onDelete;

  const _PortfolioTile({
    required this.item,
    required this.showDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = item['media_type'] == 'video';
    final url = (item['media_url'] ?? '').toString();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── main content ──────────────────────────────────────
          if (isVideo)
            _VideoPlaceholder()
          else
            Image.network(
              url,
              fit: BoxFit.cover,
              // loadingBuilder fires every progress tick. When the download
              // is done, `progress == null` and the real image shows.
              loadingBuilder: (ctx, child, progress) {
                if (progress == null) return child;
                return _ShimmerPlaceholder(
                  progress: progress.expectedTotalBytes == null
                      ? null
                      : progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!,
                );
              },
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFF2F0EA),
                child: const Icon(Icons.broken_image,
                    color: AppColors.accentBrown),
              ),
            ),

          // ── delete button ─────────────────────────────────────
          if (showDelete)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 14),
                ),
              ),
            ),

          // ── "video" badge in the top-left of video tiles ──────
          if (isVideo)
            const Positioned(
              top: 6,
              left: 6,
              child: _Badge(icon: Icons.videocam, label: 'Video'),
            ),
        ],
      ),
    );
  }
}

/// While the image is downloading, show a subtle shimmer block with
/// a thin progress bar at the bottom. Much nicer than a blank tile.
class _ShimmerPlaceholder extends StatelessWidget {
  final double? progress;
  const _ShimmerPlaceholder({this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.accentBrown.withOpacity(0.08),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          LinearProgressIndicator(
            value: progress,
            minHeight: 2,
            backgroundColor: Colors.transparent,
            valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryGold),
          ),
        ],
      ),
    );
  }
}

/// Dark gradient tile with a centered play icon. No external package needed.
class _VideoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.darkBrown.withOpacity(0.85),
            AppColors.accentBrown.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.play_circle_fill,
            size: 48, color: Colors.white),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }
}
