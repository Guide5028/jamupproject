import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String role, // "musician" | "venue"
  }) async {
    final res = await supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'jamup://auth-callback', // deep link
      data: {
        'name': name,
        'role': role,
      },
    );
    // ⛔️ Do NOT insert into public.users here (no session yet).
    return res;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    await ensureUserRow(); // 👈 create profile row after real login
    return res;
  }

  Future<void> ensureUserRow() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final existing = await supabase
        .from('users')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (existing == null) {
      final meta = user.userMetadata ?? {};
      await supabase.from('users').insert({
        'id': user.id,
        'name': meta['name'] ?? user.email?.split('@').first ?? 'User',
        'email': user.email,
        'role': meta['role'] ?? 'musician',
        'avatar_url': meta['avatar_url'],
        'bio': meta['bio'],
        'genres': meta['genres'],
        'venue_type': meta['venueType'],
      });
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  User? get currentUser => supabase.auth.currentUser;
}
