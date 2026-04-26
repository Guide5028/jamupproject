// ============================================================================
// favorites_service.dart   —   reactive cache for user's favorited gigs
// ============================================================================
// Teacher notes for Guide:
//
// PROBLEM: each gig card shows a heart that should reflect "is this gig in
// my favorites?". The naive way is for every card to fire a query on init.
// 50 cards on screen → 50 round trips. That's bad for battery, network,
// and UX (heart icons flicker into place).
//
// SOLUTION: a singleton service that caches the user's favorite gig IDs in
// memory and exposes them as a `ValueNotifier<Set<String>>`. UI widgets
// subscribe via `ValueListenableBuilder` and rebuild themselves the moment
// the set changes — no manual setState plumbing.
//
// KEY DESIGN POINTS:
//   • Singleton: `FavoritesService.instance`. We want exactly ONE source
//     of truth across the whole app, and Provider is overkill for a Set.
//   • ValueNotifier: lighter than ChangeNotifier; Flutter has built-in
//     ValueListenableBuilder support for hot-reactive UI.
//   • loadAll() must be called once after the user logs in (we'll add the
//     call to AuthService.signIn so it always happens).
//   • Optimistic update: toggle() updates the in-memory set FIRST, then
//     awaits the DB. If the DB call fails, we revert. This makes the UI
//     feel instant even on a slow network.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/gig.dart';

class FavoritesService {
  // Private constructor + static instance = singleton pattern.
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  // Lazy getter so the singleton can be constructed in unit tests
  // BEFORE Supabase has been initialised. Without this, just touching
  // FavoritesService.instance from a test would crash.
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Reactive set of gig IDs the current user has favorited.
  /// Listen to this in your widget tree to auto-rebuild on changes.
  final ValueNotifier<Set<String>> ids = ValueNotifier(<String>{});

  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// Fetch every favorite for the current user and populate the cache.
  /// Safe to call multiple times — it just refreshes.
  Future<void> loadAll() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ids.value = <String>{};
      _loaded = false;
      return;
    }

    try {
      final rows = await _supabase
          .from('favorites')
          .select('gig_id')
          .eq('user_id', user.id);

      ids.value = (rows as List)
          .map<String>((r) => r['gig_id'].toString())
          .toSet();
      _loaded = true;
    } catch (e) {
      // We swallow the error: a failed load shouldn't crash the app, the
      // hearts just stay un-filled until next attempt.
      if (kDebugMode) {
        print('FavoritesService.loadAll error: $e');
      }
    }
  }

  /// Returns true if the gig is currently in the user's favorites.
  /// Synchronous because we read from the in-memory cache.
  bool isFavorite(String gigId) => ids.value.contains(gigId);

  /// Adds or removes a favorite. Optimistic — updates the in-memory
  /// notifier first so the UI reacts instantly, then writes to Supabase.
  /// On failure, rolls back the in-memory change.
  Future<void> toggle(String gigId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final wasFav = ids.value.contains(gigId);

    // 1) optimistic update — UI hearts swap immediately
    final next = {...ids.value};
    if (wasFav) {
      next.remove(gigId);
    } else {
      next.add(gigId);
    }
    ids.value = next;

    // 2) persist to DB
    try {
      if (wasFav) {
        await _supabase
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('gig_id', gigId);
      } else {
        await _supabase.from('favorites').insert({
          'user_id': user.id,
          'gig_id': gigId,
        });
      }
    } catch (e) {
      // 3) rollback on error so UI matches reality.
      // We rebuild the set from the previous state to avoid races where
      // the user tapped multiple hearts quickly.
      final rollback = {...ids.value};
      if (wasFav) {
        rollback.add(gigId);
      } else {
        rollback.remove(gigId);
      }
      ids.value = rollback;
      if (kDebugMode) {
        print('FavoritesService.toggle error: $e');
      }
      rethrow;
    }
  }

  /// Returns the full Gig objects for everything the user has favorited.
  /// Used by FavoritesPage. Empty list if the user has no favorites yet.
  Future<List<Gig>> listFavoriteGigs() async {
    if (ids.value.isEmpty) return [];

    // `inFilter` translates to PostgREST "in.()" operator. Single round-trip
    // for all favorited gigs — much better than N queries.
    final rows = await _supabase
        .from('gigs')
        .select('*')
        .inFilter('id', ids.value.toList());

    return (rows as List)
        .map((r) => Gig.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Clears the cache — call from sign-out flow so the next user
  /// doesn't briefly see the previous user's favorites.
  void clear() {
    ids.value = <String>{};
    _loaded = false;
  }
}
