import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_storage.dart';
import '../../data/models/channel_model.dart';

abstract class LiveTvState {}

class LiveTvInitial extends LiveTvState {}

class LiveTvLoading extends LiveTvState {}

class LiveTvLoaded extends LiveTvState {
  final List<LiveChannel> channels;
  final List<String> categories;
  final String selectedCategory;
  final String searchQuery;

  LiveTvLoaded({
    required this.channels,
    required this.categories,
    required this.selectedCategory,
    this.searchQuery = '',
  });

  List<LiveChannel> get filteredChannels {
    if (selectedCategory == 'Todos' || selectedCategory == 'Resultados de Búsqueda') {
      return channels;
    }
    return channels.where((c) => c.category == selectedCategory).toList();
  }

  LiveTvLoaded copyWith({
    List<LiveChannel>? channels,
    List<String>? categories,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return LiveTvLoaded(
      channels: channels ?? this.channels,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class LiveTvError extends LiveTvState {
  final String message;
  LiveTvError(this.message);
}

class LiveTvCubit extends Cubit<LiveTvState> {
  final ApiClient _apiClient;
  final LocalStorage _localStorage;

  int _currentSkip = 0;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;
  final List<Map<String, dynamic>> _catalogCache = [];

  LiveTvCubit(this._apiClient, this._localStorage) : super(LiveTvInitial());

  Future<void> loadChannels() async {
    emit(LiveTvLoading());
    _currentSkip = 0;
    _hasReachedMax = false;
    _catalogCache.clear();
    try {
      final addonUrls = _localStorage.getInstalledAddonUrls();
      final List<LiveChannel> allChannels = [];
      final Set<String> categoriesSet = {'Todos'};

      for (var url in addonUrls) {
        try {
          final manifest = await _apiClient.fetchAddonManifest(url);
          final catalogs = manifest['catalogs'] as List<dynamic>? ?? [];
          final tvCatalogs = catalogs.where((c) => c['type'] == 'tv');
          
          for (var catalog in tvCatalogs) {
            final catalogId = catalog['id'];
            final catalogName = catalog['name'] ?? 'TV';
            
            _catalogCache.add({
              'url': url,
              'catalogId': catalogId,
              'catalogName': catalogName,
            });
            
            final catalogResponse = await _apiClient.fetchAddonCatalog(url, 'tv', catalogId);
            final metas = catalogResponse['metas'] as List<dynamic>? ?? [];
            
            for (var c in metas) {
              final metaId = c['id'] ?? '';
              final streamUrl = c['stream_url'] ?? ''; 
              
              allChannels.add(LiveChannel(
                id: metaId,
                name: c['name'] ?? 'Canal desconocido',
                logo: c['poster'],
                streamUrl: streamUrl,
                category: catalogName,
                nowPlaying: 'Transmisión en Vivo',
                addonUrl: url,
              ));
            }
            categoriesSet.add(catalogName);
          }
        } catch (e) {
          print('Error loading tv catalog from $url: $e');
        }
      }

      emit(LiveTvLoaded(
        channels: allChannels,
        categories: categoriesSet.toList(),
        selectedCategory: 'Todos',
      ));
    } catch (e) {
      emit(LiveTvError('No se pudieron cargar los canales de TV: $e'));
    }
  }

  Future<void> loadMoreChannels() async {
    if (_isLoadingMore || _hasReachedMax) return;
    final currentState = state;
    if (currentState is! LiveTvLoaded) return;

    _isLoadingMore = true;
    _currentSkip += 100; // Salto estándar en addons

    try {
      final List<LiveChannel> newChannels = [];
      final Set<String> categoriesSet = Set.from(currentState.categories);

      for (var cached in _catalogCache) {
        try {
          final url = cached['url'] as String;
          final catalogId = cached['catalogId'] as String;
          final catalogName = cached['catalogName'] as String;

          final catalogResponse = await _apiClient.fetchAddonCatalog(
            url, 
            'tv', 
            catalogId, 
            extraParams: 'skip=$_currentSkip'
          );
          
          final metas = catalogResponse['metas'] as List<dynamic>? ?? [];
          
          for (var c in metas) {
            final metaId = c['id'] ?? '';
            final streamUrl = c['stream_url'] ?? ''; 
            
            newChannels.add(LiveChannel(
              id: metaId,
              name: c['name'] ?? 'Canal desconocido',
              logo: c['poster'],
              streamUrl: streamUrl,
              category: catalogName,
              nowPlaying: 'Transmisión en Vivo',
              addonUrl: url,
            ));
          }
          categoriesSet.add(catalogName);
        } catch (e) {
          print('Error loading more channels: $e');
        }
      }

      if (newChannels.isEmpty) {
        _hasReachedMax = true;
      } else {
        emit(currentState.copyWith(
          channels: [...currentState.channels, ...newChannels],
          categories: categoriesSet.toList(),
        ));
      }
    } catch (e) {
      print('Pagination error: $e');
    } finally {
      _isLoadingMore = false;
    }
  }

  void selectCategory(String category) {
    final currentState = state;
    if (currentState is LiveTvLoaded) {
      emit(currentState.copyWith(selectedCategory: category));
    }
  }

  void searchChannels(String query) {
    searchFromAddons(query);
  }

  Future<void> searchFromAddons(String query) async {
    if (query.trim().isEmpty) {
      await loadChannels();
      return;
    }

    emit(LiveTvLoading());
    _currentSkip = 0;
    _hasReachedMax = false;

    try {
      final List<LiveChannel> searchResults = [];
      final Set<String> categoriesSet = {'Resultados de Búsqueda'};

      for (var cached in _catalogCache) {
        final url = cached['url'] as String? ?? '';
        try {
          final catalogId = cached['catalogId'] as String;

          final catalogResponse = await _apiClient.fetchAddonCatalog(
            url, 
            'tv', 
            catalogId, 
            extraParams: 'search=${Uri.encodeComponent(query)}'
          );
          
          final metas = catalogResponse['metas'] as List<dynamic>? ?? [];
          
          for (var c in metas) {
            final metaId = c['id'] ?? '';
            final streamUrl = c['stream_url'] ?? ''; 
            
            searchResults.add(LiveChannel(
              id: metaId,
              name: c['name'] ?? 'Canal desconocido',
              logo: c['poster'],
              streamUrl: streamUrl,
              category: 'Resultados de Búsqueda',
              nowPlaying: 'Transmisión en Vivo',
              addonUrl: url,
            ));
          }
        } catch (e) {
          print('Error searching channels in $url: $e');
        }
      }

      emit(LiveTvLoaded(
        channels: searchResults,
        categories: categoriesSet.toList(),
        selectedCategory: 'Resultados de Búsqueda',
        searchQuery: query,
      ));
    } catch (e) {
      emit(LiveTvError('Error al buscar canales: $e'));
    }
  }

  Future<String?> getStreamUrl(LiveChannel channel) async {
    if (channel.streamUrl.isNotEmpty) {
      return channel.streamUrl;
    }
    if (channel.addonUrl.isEmpty) {
      return null;
    }
    try {
      final response = await _apiClient.fetchAddonStreams(channel.addonUrl, 'tv', channel.id);
      final streams = response['streams'] as List<dynamic>? ?? [];
      if (streams.isNotEmpty) {
        return streams.first['url'] as String?;
      }
    } catch (e) {
      print('Error fetching stream for channel ${channel.id}: $e');
    }
    return null;
  }
}
