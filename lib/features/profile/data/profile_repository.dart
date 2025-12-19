import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getMyProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final row = await supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return (row ?? <String, dynamic>{});
  }

  Future<void> updateMyProfile({
    required String name,
    required String bio,
    required List<String> genres,
    String? avatarUrl,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final payload = <String, dynamic>{
      'name': name.trim(),
      'bio': bio.trim(),
      'genres': genres,
    };

    if (avatarUrl != null) {
      payload['avatar_url'] = avatarUrl.trim();
    }

    await supabase.from('users').update(payload).eq('id', user.id);
  }
}
