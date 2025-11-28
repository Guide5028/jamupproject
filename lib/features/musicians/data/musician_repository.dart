import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/musician.dart';

class MusicianRepository {
  final supabase = Supabase.instance.client;

  Future<List<Musician>> fetchAll({String? filter}) async {
    // Get all musicians from users table
    final rows = await supabase
        .from('users')
        .select('id, name, avatar_url, bio, genres')
        .eq('role', 'musician')
        .order('name', ascending: true);

    var list = (rows as List).map((j) => Musician.fromJson(j)).toList();

    if (filter == null || filter.isEmpty) return list;

    final f = filter.toLowerCase();
    return list.where((m) {
      return m.genre.toLowerCase() == f ||
          m.type.toLowerCase() == f; // type = Solo/Duo/Band (from model)
    }).toList();
  }
}
