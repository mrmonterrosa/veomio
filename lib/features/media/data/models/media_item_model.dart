class MediaItem {
  final String id;
  final String title;
  final String logo;
  final String releaseYear;
  final String releaseDate;
  final String thumbnail;
  final String backdrop;
  final String plot;
  final double rating;
  final String type; // 'movie' or 'series'
  final List<String> cast;

  MediaItem({
    required this.id,
    required this.title,
    this.logo = '',
    required this.releaseYear,
    required this.releaseDate,
    required this.thumbnail,
    required this.backdrop,
    required this.plot,
    required this.rating,
    required this.type,
    this.cast = const [],
  });

  factory MediaItem.fromLaravelJson(Map<String, dynamic> json, {String type = 'movie'}) {
    return MediaItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Sin título',
      logo: json['logo'] as String? ?? '',
      releaseYear: json['release_year']?.toString() ?? '',
      releaseDate: json['release_date'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      backdrop: json['backdrop'] as String? ?? '',
      plot: json['plot'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      type: type,
    );
  }

  factory MediaItem.fromStremioJson(Map<String, dynamic> json) {
    // Stremio uses poster, background, name, description, releaseInfo, logo
    final name = json['name'] as String? ?? 'Unnamed';
    final poster = json['poster'] as String? ?? '';
    final background = json['background'] as String? ?? '';
    final logo = json['logo'] as String? ?? '';
    final description = json['description'] as String? ?? '';
    final releaseInfo = json['releaseInfo']?.toString() ?? '';
    final id = json['id'] as String? ?? '';
    final type = json['type'] as String? ?? 'movie';

    final imdbRatingStr = json['imdbRating']?.toString();
    double rating = 0.0;
    if (imdbRatingStr != null && imdbRatingStr.isNotEmpty) {
      rating = double.tryParse(imdbRatingStr) ?? 0.0;
    }

    final castRaw = json['cast'] as List<dynamic>? ?? [];
    final cast = castRaw.map((e) => e.toString()).toList();

    return MediaItem(
      id: id,
      title: name,
      logo: logo,
      releaseYear: releaseInfo,
      releaseDate: releaseInfo,
      thumbnail: poster,
      backdrop: background,
      plot: description,
      rating: rating,
      type: type,
      cast: cast,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'release_year': releaseYear,
      'release_date': releaseDate,
      'thumbnail': thumbnail,
      'backdrop': backdrop,
      'plot': plot,
      'rating': rating,
      'type': type,
    };
  }
}
