import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // Sign up
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String role, // "musician" or "venue"
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'role': role,
      },
    );

    // Also insert into users table
    await supabase.from('users').insert({
      'id': response.user!.id,
      'name': name,
      'email': email,
      'role': role,
    });

    return response;
  }

  // Login
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Logout
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // Get current user
  User? get currentUser => supabase.auth.currentUser;
}
