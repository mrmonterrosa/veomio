import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _keyApiBaseUrl = 'api_base_url';
  static const String _keyInstalledAddons = 'installed_addons';
  static const String _keyContinueWatching = 'continue_watching';
  static const String _keyMyList = 'my_list';
  static const String _keyPlayerType = 'player_type';

  final SharedPreferences _prefs;

  LocalStorage(this._prefs);

  static Future<LocalStorage> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorage(prefs);
  }

  // API Base URL
  String getApiBaseUrl() {
    return _prefs.getString(_keyApiBaseUrl) ?? 'https://api-veomio.mrmonterrosa.com';
  }

  Future<void> setApiBaseUrl(String url) async {
    await _prefs.setString(_keyApiBaseUrl, url);
  }

  // Player Type Setting (native / vlc)
  String getPlayerType() {
    return _prefs.getString(_keyPlayerType) ?? 'native';
  }

  Future<void> setPlayerType(String type) async {
    await _prefs.setString(_keyPlayerType, type);
  }

  // Installed Addons (list of manifest URLs)
  List<String> getInstalledAddonUrls() {
    return _prefs.getStringList(_keyInstalledAddons) ?? [
      // Pre-configure a few standard Stremio addons for demo purposes
      'https://v3-cinemeta.strem.io/manifest.json', // Cinemeta (Official Catalogs)
      'https://veomio-stremio.onrender.com/manifest.json', // Live TV Addon
    ];
  }

  Future<void> saveInstalledAddonUrls(List<String> urls) async {
    await _prefs.setStringList(_keyInstalledAddons, urls);
  }

  Future<void> addAddonUrl(String url) async {
    final urls = getInstalledAddonUrls();
    if (!urls.contains(url)) {
      urls.add(url);
      await saveInstalledAddonUrls(urls);
    }
  }

  Future<void> removeAddonUrl(String url) async {
    final urls = getInstalledAddonUrls();
    urls.remove(url);
    await saveInstalledAddonUrls(urls);
  }

  // Continue Watching list
  List<Map<String, dynamic>> getContinueWatching() {
    final data = _prefs.getStringList(_keyContinueWatching) ?? [];
    return data.map((item) => json.decode(item) as Map<String, dynamic>).toList();
  }

  Future<void> saveContinueWatching(List<Map<String, dynamic>> items) async {
    final data = items.map((item) => json.encode(item)).toList();
    await _prefs.setStringList(_keyContinueWatching, data);
  }

  Future<void> updateContinueWatching(Map<String, dynamic> mediaItem, int positionMs, int durationMs) async {
    final items = getContinueWatching();
    final mediaId = mediaItem['id'];
    
    // Remove if already exists to move to top
    items.removeWhere((item) => item['media']['id'] == mediaId);
    
    items.insert(0, {
      'media': mediaItem,
      'position': positionMs,
      'duration': durationMs,
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Keep only top 10 items
    if (items.length > 10) {
      items.removeLast();
    }
    
    await saveContinueWatching(items);
  }

  // My List / Favorites
  List<Map<String, dynamic>> getMyList() {
    final data = _prefs.getStringList(_keyMyList) ?? [];
    return data.map((item) => json.decode(item) as Map<String, dynamic>).toList();
  }

  Future<void> saveMyList(List<Map<String, dynamic>> items) async {
    final data = items.map((item) => json.encode(item)).toList();
    await _prefs.setStringList(_keyMyList, data);
  }

  bool isInMyList(String mediaId) {
    final items = getMyList();
    return items.any((item) => item['id'] == mediaId);
  }

  Future<void> toggleMyList(Map<String, dynamic> mediaItem) async {
    final items = getMyList();
    final mediaId = mediaItem['id'];
    
    if (isInMyList(mediaId)) {
      items.removeWhere((item) => item['id'] == mediaId);
    } else {
      items.add(mediaItem);
    }
    
    await saveMyList(items);
  }
}
