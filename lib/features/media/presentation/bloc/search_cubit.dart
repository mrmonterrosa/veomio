import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_storage.dart';
import '../../data/models/media_item_model.dart';
import '../../../addons/data/models/addon_manifest_model.dart';

abstract class SearchState {}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<MediaItem> results;
  final String query;
  SearchLoaded(this.results, this.query);
}

class SearchError extends SearchState {
  final String message;
  SearchError(this.message);
}

class SearchCubit extends Cubit<SearchState> {
  final ApiClient _apiClient;
  final LocalStorage _localStorage;

  SearchCubit(this._apiClient, this._localStorage) : super(SearchInitial());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading());
    try {
      final List<MediaItem> resultsList = [];
      
      // 1. Search via Laravel Scraper API
      try {
        final searchResult = await _apiClient.searchMovies(query);
        // Laravel searchMovies returns status: success and data: Map<Title, List<Streams>>
        if (searchResult['status'] == 'success' && searchResult['data'] is Map) {
          final moviesData = searchResult['data'] as Map<String, dynamic>;
          for (var movieTitle in moviesData.keys) {
            // Since local search doesn't give us TMDB poster, we create a placeholder card 
            // and try to resolve details on click. We set the thumbnail to a placeholder or empty, 
            // which the UI will handle elegantly with a beautiful text overlay card!
            resultsList.add(MediaItem(
              id: 'local_$movieTitle',
              title: movieTitle,
              releaseYear: '',
              releaseDate: '',
              thumbnail: '',
              backdrop: '',
              plot: 'Resultados encontrados en servidores locales.',
              rating: 0.0,
              type: 'movie',
            ));
          }
        }
      } catch (e) {
        // Silently fail local scraper search if down or empty
      }

      // 2. Search via Stremio Addons (Cinemeta, etc.)
      final addonUrls = _localStorage.getInstalledAddonUrls();
      for (var url in addonUrls) {
        try {
          final manifestJson = await _apiClient.fetchAddonManifest(url);
          final addon = StremioAddon.fromJson(manifestJson, url);
          
          // Look for catalogs that match 'movie' or 'series' and query search
          for (var catalog in addon.catalogs) {
            try {
              final searchResult = await _apiClient.fetchAddonCatalog(
                url,
                catalog.type,
                catalog.id,
                extraParams: 'search=${Uri.encodeComponent(query)}',
              );
              
              if (searchResult['metas'] is List) {
                final metas = searchResult['metas'] as List<dynamic>;
                for (var meta in metas) {
                  resultsList.add(MediaItem.fromStremioJson(meta));
                }
              }
            } catch (e) {
              // Ignore catalog specific search errors
            }
          }
        } catch (e) {
          // Ignore addon errors
        }
      }

      // De-duplicate results by title/ID
      final seenIds = <String>{};
      final uniqueResults = <MediaItem>[];
      for (var item in resultsList) {
        if (!seenIds.contains(item.id) && !seenIds.contains(item.title.toLowerCase())) {
          seenIds.add(item.id);
          seenIds.add(item.title.toLowerCase());
          uniqueResults.add(item);
        }
      }

      emit(SearchLoaded(uniqueResults, query));
    } catch (e) {
      emit(SearchError('Error al buscar películas: $e'));
    }
  }

  void clearSearch() {
    emit(SearchInitial());
  }
}
