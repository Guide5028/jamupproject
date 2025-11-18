import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/musician.dart';

class MusicianRepository {
  final supabase = Supabase.instance.client;

  Future<List<Musician>> fetchAll() async {
    final rows = await supabase
        .from('users')
        .select('id, name, avatar_url, genres, bio, role')
        .eq('role', 'musician');

    return (rows as List)
        .map((j) => Musician.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
