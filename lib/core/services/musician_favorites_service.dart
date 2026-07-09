import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/musician.dart';

/// MusicianFavoritesService
/// ------------------------
/// Lets a logged-in user (typically a venue) "favorite" musicians.
///
/// This is a SEPARATE service from FavoritesService on purpose:
///   • FavoritesService stores favorited *gigs*   (table: favorites)
///   • This service stores favorited *musicians*  (table: favorite_musicians)
/// Keeping them apart means each has its own reactive set and can't
/// accidentally clash IDs.
///
/// It's a singleton so every musician card in the app shares ONE source of
/// truth. When the set changes, every heart button listening to it rebuilds.
class MusicianFavoritesService {
  MusicianFavoritesService._();
  static final MusicianFavoritesService instance =
      MusicianFavoritesService._();

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Reactive set of favorited musician IDs. UI widgets listen to this via
  /// ValueListenableBuilder, so a toggle anywhere updates every heart at once.
  final ValueNotifier<Set<String>> ids = ValueNotifier(<String>{});

  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// Load the current user's favorited musician IDs from Supabase.
  /// Safe to call on every app launch — RLS guarantees we only get our rows.
  Future<void> loadAll() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ids.value = <String>{};
      _loaded = false;
      return;
    }

    try {
      final rows = await _supabase
          .from('favorite_musicians')
          .select('musician_id')
          .eq('user_id', user.id);

      ids.value = (rows as List)
          .map<String>((r) => r['musician_id'].toString())
          .toSet();
      _loaded = true;
    } catch (e) {
      if (kDebugMode) print('MusicianFavoritesService.loadAll: $e');
    }
  }

  bool isFavorite(String musicianId) => ids.value.contains(musicianId);

  /// Add/remove a musician from favorites.
  ///
  /// We update the in-memory set FIRST (optimistic update) so the heart fills
  /// instantly, then write to the database. If the write fails we roll the set
  /// back, so the UI never lies about what's actually saved.
  Future<void> toggle(String musicianId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final wasFav = ids.value.contains(musicianId);

    final next = {...ids.value};
    if (wasFav) {
      next.remove(musicianId);
    } else {
      next.add(musicianId);
    }
    ids.value = next;

    try {
      if (wasFav) {
        await _supabase
            .from('favorite_musicians')
            .delete()
            .eq('user_id', user.id)
            .eq('musician_id', musicianId);
      } else {
        await _supabase.from('favorite_musicians').insert({
          'user_id': user.id,
          'musician_id': musicianId,
        });
      }
    } catch (e) {
      // Roll back the optimistic change so UI matches the database.
      final rollback = {...ids.value};
      if (wasFav) {
        rollback.add(musicianId);
      } else {
        rollback.remove(musicianId);
      }
      ids.value = rollback;
      if (kDebugMode) print('MusicianFavoritesService.toggle: $e');
      rethrow;
    }
  }

  /// Fetch the full Musician records for everything currently favorited.
  /// Used by the "Favorite Musicians" page. Mirrors the gig FavoritesService.
  Future<List<Musician>> listFavoriteMusicians() async {
    if (ids.value.isEmpty) return [];

    // Same columns the musicians list uses, so Musician.fromJson is happy.
    final rows = await _supabase
        .from('users')
        .select('id, name, avatar_url, bio, genres, role')
        .inFilter('id', ids.value.toList());

    return (rows as List)
        .map((r) => Musician.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Clear local state on logout so the next user doesn't inherit these.
  void clear() {
    ids.value = <String>{};
    _loaded = false;
  }
}
