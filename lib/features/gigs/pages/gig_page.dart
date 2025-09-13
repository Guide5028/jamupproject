import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../models/gig.dart';
import '../widgets/gig_card.dart';
import '../controllers/gig_controller.dart';
import '../data/gig_repository.dart';

class GigPage extends StatelessWidget {
  const GigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GigController(GigRepository())..loadGigs(),
      child: Consumer<GigController>(
        builder: (context, ctrl, _) {
          if (ctrl.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (ctrl.error != null) {
            return Center(child: Text("Error: ${ctrl.error}"));
          }
          if (ctrl.gigs.isEmpty) {
            return const Center(child: Text("No gigs available"));
          }

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text("Gigs"),
              backgroundColor: AppColors.background,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.darkBrown),
            ),
            body: Column(
              children: [
                // 🔹 Filters row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      "Jazz",
                      "EDM",
                      "Rock",
                      "Acoustic",
                      "HipHop",
                    ].map((f) {
                      final isSelected = ctrl.selectedFilter == f;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: isSelected,
                          selectedColor: AppColors.primaryGold.withOpacity(0.8),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.darkBrown,
                          ),
                          onSelected: (_) => ctrl.toggleFilter(f),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // 🔹 Gigs Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: ctrl.filtered.length,
                    itemBuilder: (context, i) {
                      return GigCard(gig: ctrl.filtered[i]);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
