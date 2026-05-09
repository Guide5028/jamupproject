import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../data/review_repository.dart';

/// Lets a user submit a star-rating + comment for the other party
/// of a completed booking (venue rates musician, musician rates venue).
class ReviewPage extends StatefulWidget {
  final String bookingId;
  final String reviewedUserId;
  final String reviewedUserName;
  final String? reviewerId;       // defaults to current Supabase user
  final ReviewRepository? repo;   // injectable for testing

  const ReviewPage({
    super.key,
    required this.bookingId,
    required this.reviewedUserId,
    this.reviewedUserName = '',
    this.reviewerId,
    this.repo,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late final ReviewRepository _repo;
  final _commentCtrl = TextEditingController();

  int _rating = 0;       // 0 = none selected yet
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _repo = widget.repo ?? ReviewRepository();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a star rating first')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final reviewerId = widget.reviewerId ??
          Supabase.instance.client.auth.currentUser?.id ??
          '';

      await _repo.addReview(
        bookingId: widget.bookingId,
        reviewerId: reviewerId,
        reviewedUserId: widget.reviewedUserId,
        rating: _rating,
        comment: _commentCtrl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted ✅')),
      );
      Navigator.pop(context, true); // true = submitted
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Leave a Review'),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBrown),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.reviewedUserName.isEmpty
                  ? 'How was your experience?'
                  : 'How was your experience with\n${widget.reviewedUserName}?',
              style: AppFonts.textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),

            // ── Star rating row ──────────────────────────────────
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final filled = i < _rating;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.star,
                        color: filled ? Colors.amber : Colors.grey.shade300,
                        size: 40,
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 8),
            Center(
              child: Text(
                _rating == 0
                    ? 'Tap a star to rate'
                    : ['', 'Poor', 'Fair', 'Good', 'Great', 'Excellent!'][_rating],
                style: AppFonts.textTheme.bodyMedium?.copyWith(
                  color: _rating == 0
                      ? AppColors.accentBrown
                      : AppColors.primaryGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Comment ──────────────────────────────────────────
            Text('Comment (optional)', style: AppFonts.textTheme.bodyLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),

            const Spacer(),

            // ── Submit button ────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Submit',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
