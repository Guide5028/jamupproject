import 'package:flutter/material.dart';
import 'package:jamup_app/core/constants/app_colors.dart';
import 'package:jamup_app/core/constants/app_fonts.dart';
import 'package:jamup_app/core/services/portfolio_service.dart';

// PortfolioGrid is in core/widgets/ because BOTH profile_page.dart
// and musician_detail_page.dart need to display portfolio items.
// Rule: used by 2+ features → lives in core/

class PortfolioGrid extends StatefulWidget {
  final String userId;

  // showDeleteButton is true only when viewing YOUR OWN profile.
  // When a venue views a musician's page, it's false.
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

  // Key trick: changing this key forces FutureBuilder to re-run.
  // We use this to refresh the grid after an upload or delete.
  Key _key = UniqueKey();

  void refresh() => setState(() => _key = UniqueKey());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: _key,
      future: _service.fetchPortfolio(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
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
          // IMPORTANT: NeverScrollableScrollPhysics because this grid
          // lives inside a parent ListView. Two scrollable widgets
          // stacked = scrolling conflict. This disables the inner scroll.
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
                refresh(); // triggers FutureBuilder re-run
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

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: isVideo
              ? Container(
                  color: AppColors.accentBrown.withOpacity(0.15),
                  child: const Icon(
                    Icons.play_circle_outline,
                    size: 40,
                    color: AppColors.primaryGold,
                  ),
                )
              : Image.network(
                  item['media_url'],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFF2F0EA),
                    child: const Icon(Icons.broken_image,
                        color: AppColors.accentBrown),
                  ),
                ),
        ),

        // Only show delete button on your own profile page
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
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
      ],
    );
  }
}