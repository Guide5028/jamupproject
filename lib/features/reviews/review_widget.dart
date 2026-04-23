import 'package:flutter/material.dart';
import 'package:jamup_app/features/reviews/data/review_repository.dart';

class ReviewWidget extends StatelessWidget {
  final String musicianId;

  const ReviewWidget({super.key, required this.musicianId});

  // Repo as field — not recreated on every build
  static final _repo = ReviewRepository();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _repo.getReviews(musicianId),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Error state — was completely missing before
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Could not load reviews.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final reviews = snapshot.data ?? [];

        if (reviews.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No reviews yet'),
          );
        }

        return Column(
          children: reviews.map((r) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                child: Icon(Icons.person, size: 16),
              ),
              title: Row(
                children: List.generate(
                  (r['rating'] as int? ?? 0).clamp(0, 5),
                  (_) => const Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.amber,
                  ),
                ),
              ),
              subtitle: r['comment'] != null && r['comment'].toString().isNotEmpty
                  ? Text(r['comment'].toString())
                  : null,
            );
          }).toList(),
        );
      },
    );
  }
}