class MediaItem {
  final String id;
  final String title;
  final String releaseYear;
  final String releaseDate;
  final String thumbnail;
  final String backdrop;
  final String plot;
  final double rating;
  final String type; // 'movie' or 'series'

  MediaItem({
    required this.id,
    required this.title,
    required this.releaseYear,
    required this.releaseDate,
    required this.thumbnail,
    required this.backdrop,
    required this.plot,
    required this.rating,
    required this.type,
  });

  factory MediaItem.fromLaravelJson(Map<String, dynamic> json, {String type = 'movie'}) {
    return MediaItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Sin título',
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
    // Stremio uses poster, background, name, description, releaseInfo
    final name = json['name'] as String? ?? 'Unnamed';
    final poster = json['poster'] as String? ?? '';
    final background = json['background'] as String? ?? '';
    final description = json['description'] as String? ?? '';
    final releaseInfo = json['releaseInfo']?.toString() ?? '';
    final id = json['id'] as String? ?? '';
    final type = json['type'] as String? ?? 'movie';

    return MediaItem(
      id: id,
      title: name,
      releaseYear: releaseInfo,
      releaseDate: releaseInfo,
      thumbnail: poster,
      backdrop: background,
      plot: description,
      rating: 0.0, // Stremio lists typically don't include TMDB rating directly
      type: type,
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
