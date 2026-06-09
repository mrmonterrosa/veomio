import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/local_storage.dart';

class ApiClient {
  final LocalStorage _localStorage;
  final http.Client _client;

  ApiClient(this._localStorage, [http.Client? client]) : _client = client ?? http.Client();

  String get _laravelBaseUrl => _localStorage.getApiBaseUrl();

  // Unified request helper
  Future<dynamic> get(String url, {Map<String, String>? headers}) async {
    try {
      final response = await _client.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('HTTP Error ${response.statusCode} on GET $url');
      }
    } catch (e) {
      throw Exception('Failed to connect to $url: $e');
    }
  }

  Future<dynamic> post(String url, {Map<String, String>? headers, dynamic body}) async {
    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('HTTP Error ${response.statusCode} on POST $url');
      }
    } catch (e) {
      throw Exception('Failed to connect to $url: $e');
    }
  }

  // --- Laravel Scraper API Endpoints ---

  // Search Movies: /api/v1/search/movie/{query}
  Future<Map<String, dynamic>> searchMovies(String query) async {
    final url = '$_laravelBaseUrl/api/v1/search/movie/${Uri.encodeComponent(query)}';
    final result = await get(url);
    return result as Map<String, dynamic>;
  }

  // Resolve Stream: /api/v1/resolve?url={url}
  Future<Map<String, dynamic>> resolveStream(String streamUrl) async {
    final url = '$_laravelBaseUrl/api/v1/resolve?url=${Uri.encodeComponent(streamUrl)}';
    final result = await get(url);
    return result as Map<String, dynamic>;
  }

  // TMDB Movie Categories: /api/v1/movies/category
  Future<List<dynamic>> getCategories() async {
    final url = '$_laravelBaseUrl/api/v1/movies/category';
    try {
      final result = await get(url);
      if (result['status'] == 'success') {
        return result['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      // Fallback categories list if Laravel API is down or not set up yet
      return [
        {'id': 28, 'name': 'Acción'},
        {'id': 12, 'name': 'Aventura'},
        {'id': 16, 'name': 'Animación'},
        {'id': 35, 'name': 'Comedia'},
        {'id': 80, 'name': 'Crimen'},
        {'id': 99, 'name': 'Documental'},
        {'id': 18, 'name': 'Drama'},
        {'id': 10751, 'name': 'Familia'},
        {'id': 14, 'name': 'Fantasía'},
        {'id': 27, 'name': 'Terror'},
        {'id': 878, 'name': 'Ciencia ficción'},
        {'id': 53, 'name': 'Suspense'},
      ];
    }
  }

  // Movies by Category: /api/v1/movies/category/{categoria}?page={page}
  Future<List<dynamic>> getMoviesByCategory(String categoria, {int page = 1}) async {
    final url = '$_laravelBaseUrl/api/v1/movies/category/${Uri.encodeComponent(categoria)}?page=$page';
    try {
      final result = await get(url);
      if (result['status'] == 'success') {
        return result['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Now Playing Movies: /api/v1/movies/now-playing?page={page}
  Future<List<dynamic>> getNowPlaying({int page = 1}) async {
    final url = '$_laravelBaseUrl/api/v1/movies/now-playing?page=$page';
    try {
      final result = await get(url);
      if (result['status'] == 'success') {
        return result['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Live TV Channels: /api/v1/live/channels?page={page}&platform=android
  Future<List<dynamic>> getLiveChannels({int page = 1}) async {
    final url = '$_laravelBaseUrl/api/v1/live/channels?page=$page&platform=android';
    try {
      final result = await get(url);
      // Laravel controller typically returns channels as data
      if (result is List) {
        return result;
      } else if (result is Map && result.containsKey('data')) {
        return result['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      // Mock fallback channels if API fails
      return [
        {
          'id': '1',
          'name': 'HBO HD',
          'logo': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCWhWSvbFpoJYIDbCCIeBNHO2GoiveASqPfjZ54uX739HqnxxY9XHvzvLOME9NWiKE2V1f0_jn8ybMFXnHynD9fMtY6RxoLDLKdwKPAVDYkGHTe6Cjs3vCBzxwrH4jvUSrimdd-9ND5swdzzUXW6BwtXsFEfKud-2CN2J9rEPm9JAAaYBi_62JhDHjUC2CpJsByH_-2YJ35rJd3XmQmISY9rJQ4A_lIj65vEXimmpyAbCtITXESL2EFyD6i6mfmY452yE67KT00joI',
          'stream_url': 'https://tvfreedom.surge.sh/hbo.m3u8',
          'category': 'Cine',
          'now_playing': 'Blade Runner 2049',
          'start_time': '8:00 PM',
          'end_time': '10:45 PM',
        },
        {
          'id': '2',
          'name': 'AMC',
          'logo': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAsvMejJAxJ_5VgZMuJixUpuHQIOJ6cDHjtpf4mUx_W-7CekYWLG-O9XzhaMKpjbluWbvKQVlRHcq4n6ANRXOkqs0vils3jCiNFEUMObRnBhXeBZysOKRLT3zbZaTyjmcZO_OI2I81-JIrcOmt1CGZXBu9VdtkpiKOsQhxksAMRxGiVseVs4JRnZ9q9BagsjCqDT1mklggzp0lLd1zAZ171BNXUIxpMVigb_87IVz7dnwetQa4bKCSCV2J5VbbHXXrpqYVcOkngSwY',
          'stream_url': 'https://tvfreedom.surge.sh/amc.m3u8',
          'category': 'Series',
          'now_playing': 'Breaking Bad',
          'start_time': '8:00 PM',
          'end_time': '9:00 PM',
        },
        {
          'id': '3',
          'name': 'FX',
          'logo': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAsXwJW5Wbt1DQGU7xO6qRmgnFFi-uj7Tvc8Vm2pOGHwt_H8LvLznu-ibLhO3qVAOWpHNjeN6EMTdAncIN5g8QyjZAvDb5fT5S2zJCAWyfmMPSVcqToj-cW3gmUjhs1kFYt30w06dILs5PiWnfXckT2EEPR-RjV1IjHSqHbQ0ohZtQmAU5F0CkOus1Z4TQHowzRhK3iGzFBczBFcBIxBPUwiE07UEe9yMHEPxKdZgp374ZfFEy_xXYbQ1E20WdFS00cy9Jqv6cgsgs',
          'stream_url': 'https://tvfreedom.surge.sh/fx.m3u8',
          'category': 'Cine',
          'now_playing': 'Fargo',
          'start_time': '8:00 PM',
          'end_time': '10:00 PM',
        },
      ];
    }
  }

  // --- Stremio Addon Endpoints ---

  // Fetch Manifest
  Future<Map<String, dynamic>> fetchAddonManifest(String manifestUrl) async {
    final result = await get(manifestUrl);
    return result as Map<String, dynamic>;
  }

  // Fetch Addon Catalog
  Future<Map<String, dynamic>> fetchAddonCatalog(String addonUrl, String type, String catalogId, {String? extraParams}) async {
    // Addon URL format: e.g. https://torrentio.strem.fun/manifest.json
    // Endpoints for catalogs: {addonBase}/catalog/{type}/{catalogId}.json
    final addonBase = addonUrl.replaceAll('/manifest.json', '');
    var url = '$addonBase/catalog/$type/$catalogId.json';
    if (extraParams != null && extraParams.isNotEmpty) {
      url += '?$extraParams';
    }
    final result = await get(url);
    return result as Map<String, dynamic>;
  }

  // Fetch Addon Streams
  Future<Map<String, dynamic>> fetchAddonStreams(String addonUrl, String type, String videoId) async {
    // Endpoints for streams: {addonBase}/stream/{type}/{videoId}.json
    final addonBase = addonUrl.replaceAll('/manifest.json', '');
    final url = '$addonBase/stream/$type/$videoId.json';
    try {
      final result = await get(url);
      return result as Map<String, dynamic>;
    } catch (e) {
      return {'streams': []};
    }
  }
}
