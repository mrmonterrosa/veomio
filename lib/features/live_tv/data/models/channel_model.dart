class LiveChannel {
  final String id;
  final String name;
  final String? logo;
  final String streamUrl;
  final String? category;
  final String? nowPlaying;
  final String? startTime;
  final String? endTime;

  LiveChannel({
    required this.id,
    required this.name,
    this.logo,
    required this.streamUrl,
    this.category,
    this.nowPlaying,
    this.startTime,
    this.endTime,
  });

  factory LiveChannel.fromJson(Map<String, dynamic> json) {
    return LiveChannel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Canal desconocido',
      logo: json['logo'] as String?,
      streamUrl: json['stream_url'] as String? ?? '',
      category: json['category'] as String?,
      nowPlaying: json['now_playing'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
      'stream_url': streamUrl,
      'category': category,
      'now_playing': nowPlaying,
      'start_time': startTime,
      'end_time': endTime,
    };
  }
}
