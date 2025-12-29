import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../models/gig.dart';
import '../controllers/gig_controller.dart';
import '../data/gig_repository.dart';
import 'create_gig_page.dart';
import 'gig_detail_page.dart';

class VenueMyGigsPage extends StatelessWidget {
  const VenueMyGigsPage({super.key});

  String _shortDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return "${d.year}-$mm-$dd";
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text("My Gigs"),
          backgroundColor: AppColors.background,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.darkBrown),
        ),
        body: Center(
          child: Text(
            "Please sign in to manage your gigs.",
            style: AppFonts.textTheme.bodyLarge,
          ),
        ),
      );
    }

    final venueId = user.id;

    return ChangeNotifierProvider(
      create: (_) => GigController(GigRepository())..loadMyGigs(venueId),
      child: Consumer<GigController>(
        builder: (context, ctrl, _) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text("My Gigs"),
              backgroundColor: AppColors.background,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.darkBrown),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateGigPage()),
                    );
                    // refresh after creating
                    if (context.mounted) {
                      await context.read<GigController>().loadMyGigs(venueId);
                    }
                  },
                ),
              ],
            ),

            body: ctrl.loading
                ? const Center(child: CircularProgressIndicator())
                : ctrl.error != null
                    ? Center(child: Text("Error: ${ctrl.error}"))
                    : RefreshIndicator(
                        onRefresh: () =>
                            context.read<GigController>().loadMyGigs(venueId),
                        child: (ctrl.myGigs.isEmpty)
                            ? ListView(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 120),
                                  Center(child: Text("No gigs yet. Tap + to create one.")),
                                ],
                              )
                            : ListView.separated(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                itemCount: ctrl.myGigs.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, i) {
                                  final gig = ctrl.myGigs[i];
                                  return _GigItem(
                                    gig: gig,
                                    dateText: _shortDate(gig.date),
                                  );
                                },
                              ),
                      ),
          );
        },
      ),
    );
  }
}

class _GigItem extends StatelessWidget {
  final Gig gig;
  final String dateText;

  const _GigItem({
    required this.gig,
    required this.dateText,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = gig.imageUrl.isNotEmpty;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GigDetailPage(gig: gig)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: hasImage
                  ? Image.network(
                      gig.imageUrl,
                      height: 90,
                      width: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ph(),
                    )
                  : _ph(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(gig.title, style: AppFonts.textTheme.bodyLarge),
                    const SizedBox(height: 4),
                    Text(
                      "${gig.location} • $dateText",
                      style: AppFonts.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: gig.genres.take(3).map((g) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(g, style: const TextStyle(fontSize: 11)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.accentBrown),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _ph() {
    return Container(
      height: 90,
      width: 90,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.music_note, color: AppColors.accentBrown),
    );
  }
}
