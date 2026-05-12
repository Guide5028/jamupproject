
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/gig.dart';

class FavoritesService {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  SupabaseClient get _supabase => Supabase.instance.client;

  // Reactive set of favorited gig IDs
  final ValueNotifier<Set<String>> ids = ValueNotifier(<String>{});

  bool _loaded = false;
  bool get isLoaded => _loaded;

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
      if (kDebugMode) print('FavoritesService.loadAll: $e');
    }
  }

  bool isFavorite(String gigId) => ids.value.contains(gigId);

  Future<void> toggle(String gigId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final wasFav = ids.value.contains(gigId);

    // Optimistic update — UI hearts swap immediately
    final next = {...ids.value};
    if (wasFav) {
      next.remove(gigId);
    } else {
      next.add(gigId);
    }
    ids.value = next;

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
      // Rollback optimistic update on error
      final rollback = {...ids.value};
      if (wasFav) {
        rollback.add(gigId);
      } else {
        rollback.remove(gigId);
      }
      ids.value = rollback;
      if (kDebugMode) print('FavoritesService.toggle: $e');
      rethrow;
    }
  }

  Future<List<Gig>> listFavoriteGigs() async {
    if (ids.value.isEmpty) return [];

    final rows = await _supabase
        .from('gigs')
        .select('*')
        .inFilter('id', ids.value.toList());

    return (rows as List)
        .map((r) => Gig.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  void clear() {
    ids.value = <String>{};
    _loaded = false;
  }
}
