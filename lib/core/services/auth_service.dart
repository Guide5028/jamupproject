import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // Sign up (email confirmation may be required → user can be null here)
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String role, // "musician" or "venue"
  }) async {
    final res = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'role': role,
        'avatar_url': null,
        'bio': '',
      },
      emailRedirectTo: 'jamup://auth-callback', 
    );

    // If your project auto-confirms, res.user will be non-null and you can upsert.
    if (res.user != null) {
      await supabase.from('users').upsert({
        'id': res.user!.id,
        'email': email,
        'name': name,
        'role': role,
        'avatar_url': null,
        'bio': '',
      });
    }

    return res;
  }

  // Login (guarantee there's a row in public.users)
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = res.user;
    if (user != null) {
      // mirror minimal fields; you can fetch metadata if needed
      await supabase.from('users').upsert({
        'id': user.id,
        'email': user.email,
        // name/role might be in user.userMetadata; keep null-safe
        'name': user.userMetadata?['name'],
        'role': user.userMetadata?['role'],
        'avatar_url': user.userMetadata?['avatar_url'],
        'bio': user.userMetadata?['bio'],
      });
    }

    return res;
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  User? get currentUser => supabase.auth.currentUser;
}
