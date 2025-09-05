class Musician {
  final String id;
  final String name;
  final List<String> genres; // edm, dance, hiphop, pop, jazz, etc.
  final String type; // solo, duo, band
  final String profileImage; // URL or asset path

  Musician({
    required this.id,
    required this.name,
    required this.genres,
    required this.type,
    required this.profileImage,
  });
}
