class StreamSource {
  final String title;
  final String url;
  final String? description;
  final String sourceName; // e.g. "Cuevana", "Torrentio"
  final bool requiresResolve;
  final String? resolveUrl;

  StreamSource({
    required this.title,
    required this.url,
    this.description,
    required this.sourceName,
    required this.requiresResolve,
    this.resolveUrl,
  });

  factory StreamSource.fromLaravelJson(Map<String, dynamic> json) {
    // Laravel output:
    // { "source_page": "Cuevana", "server_url": "Voe", "url": "...", "url_resolve": "..." }
    final sourcePage = json['source_page'] as String? ?? 'Scraper';
    final serverUrl = json['server_url'] as String? ?? 'Link';
    final urlResolve = json['url_resolve'] as String?;
    final directUrl = json['url'] as String? ?? '';

    return StreamSource(
      title: '$sourcePage - $serverUrl',
      url: directUrl,
      sourceName: sourcePage,
      requiresResolve: urlResolve != null,
      resolveUrl: urlResolve,
    );
  }

  factory StreamSource.fromStremioJson(Map<String, dynamic> json, String addonName) {
    // Stremio output:
    // { "title": "Stream title", "url": "https://...", "name": "...", "description": "..." }
    final streamTitle = json['title'] as String? ?? json['name'] as String? ?? 'Stream source';
    final directUrl = json['url'] as String? ?? '';
    final desc = json['description'] as String?;

    return StreamSource(
      title: streamTitle,
      url: directUrl,
      description: desc,
      sourceName: addonName,
      requiresResolve: false, // Stremio URLs are usually direct media URLs or torrent links
    );
  }
}
