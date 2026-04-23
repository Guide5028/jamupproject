import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewRepository {

  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getReviews(String userId) async {

    final res = await supabase
        .from('reviews')
        .select()
        .eq('reviewed_user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<double> getAverageRating(String userId) async {

  final res = await supabase
      .from('reviews')
      .select('rating')
      .eq('reviewed_user_id', userId);

  if (res.isEmpty) return 0;

  final ratings = res.map((r) => r['rating'] as int).toList();

  final avg = ratings.reduce((a, b) => a + b) / ratings.length;

  return avg;
}

  Future<void> addReview({
    required String bookingId,
    required String reviewerId,
    required String reviewedUserId,
    required int rating,
    required String comment,
  }) async {

    await supabase.from('reviews').insert({
      "booking_id": bookingId,
      "reviewer_id": reviewerId,
      "reviewed_user_id": reviewedUserId,
      "rating": rating,
      "comment": comment,
    });
  }
}