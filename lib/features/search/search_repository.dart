import '../../core/services/api_service.dart';
import '../../models/musician.dart';
import '../../models/venue.dart';

class SearchRepository {
  final ApiService api;
  SearchRepository(this.api);

  Future<List<Musician>> searchMusicians({
    String? query,
    String? genre,
    String? type,
  }) async {
    final list = await api.getList('/musicians', query: {
      if (query?.isNotEmpty == true) 'q': query!,
      if (genre?.isNotEmpty == true) 'genre': genre!,
      if (type?.isNotEmpty == true) 'type': type!,
    });
    return list.map((e) => Musician.fromJson(e)).toList();
  }

  Future<List<Venue>> searchVenues({
    String? query,
    String? venueType, // Restaurant/Club/Bar
  }) async {
    final list = await api.getList('/venues', query: {
      if (query?.isNotEmpty == true) 'q': query!,
      if (venueType?.isNotEmpty == true) 'type': venueType!,
    });
    return list.map((e) => Venue.fromJson(e)).toList();
  }
}
