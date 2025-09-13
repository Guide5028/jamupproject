import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/gig.dart';

class GigRepository {
  final supabase = Supabase.instance.client;

  Future<List<Gig>> fetchAllGigs() async {
    final response = await supabase.from('gigs').select('*');

    return (response as List).map((g) => Gig.fromJson(g)).toList();
  }
}
