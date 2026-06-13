import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/media_item_model.dart';

abstract class CatalogState {}

class CatalogInitial extends CatalogState {}

class CatalogLoading extends CatalogState {}

class CatalogLoaded extends CatalogState {
  final List<dynamic> categories;
  final List<MediaItem> nowPlaying;
  final Map<int, List<MediaItem>> categoryMovies; // cache of movies by category ID
  final int selectedCategoryId;

  CatalogLoaded({
    required this.categories,
    required this.nowPlaying,
    required this.categoryMovies,
    required this.selectedCategoryId,
  });

  CatalogLoaded copyWith({
    List<dynamic>? categories,
    List<MediaItem>? nowPlaying,
    Map<int, List<MediaItem>>? categoryMovies,
    int? selectedCategoryId,
  }) {
    return CatalogLoaded(
      categories: categories ?? this.categories,
      nowPlaying: nowPlaying ?? this.nowPlaying,
      categoryMovies: categoryMovies ?? this.categoryMovies,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
    );
  }
}

class CatalogError extends CatalogState {
  final String message;
  CatalogError(this.message);
}

class CatalogCubit extends Cubit<CatalogState> {
  final ApiClient _apiClient;

  static const List<Map<String, dynamic>> cinemetaCatalogs = [
    {'id': 1, 'name': 'Películas Populares', 'type': 'movie', 'catalog': 'top'},
    {'id': 2, 'name': 'Series Populares', 'type': 'series', 'catalog': 'top'},
    {'id': 3, 'name': 'Películas Aclamadas', 'type': 'movie', 'catalog': 'imdbRating'},
    {'id': 4, 'name': 'Series Aclamadas', 'type': 'series', 'catalog': 'imdbRating'},
  ];

  CatalogCubit(this._apiClient) : super(CatalogInitial());

  Future<void> loadCatalog() async {
    emit(CatalogLoading());
    try {
      // Load 'Now Playing' from Cinemeta top movies
      final rawTopMovies = await _apiClient.fetchAddonCatalog(
        'https://v3-cinemeta.strem.io/manifest.json',
        'movie',
        'top',
      );
      
      final nowPlayingRaw = rawTopMovies['metas'] as List<dynamic>? ?? [];
      final nowPlaying = nowPlayingRaw.map((m) => MediaItem.fromStremioJson(m)).toList();

      final initialCategory = cinemetaCatalogs.first['id'] as int;

      final Map<int, List<MediaItem>> categoryMovies = {
        initialCategory: nowPlaying, // Cache the first category since we just loaded it
      };

      emit(CatalogLoaded(
        categories: cinemetaCatalogs,
        nowPlaying: nowPlaying,
        categoryMovies: categoryMovies,
        selectedCategoryId: initialCategory,
      ));
    } catch (e) {
      emit(CatalogError('No se pudo conectar con Cinemeta: $e'));
    }
  }

  Future<void> selectCategory(int categoryId, String categoryName) async {
    final currentState = state;
    if (currentState is CatalogLoaded) {
      if (currentState.categoryMovies.containsKey(categoryId)) {
        // Already cached
        emit(currentState.copyWith(selectedCategoryId: categoryId));
        return;
      }

      // Load category movies from Cinemeta
      try {
        final cat = cinemetaCatalogs.firstWhere((c) => c['id'] == categoryId, orElse: () => cinemetaCatalogs.first);
        final rawMovies = await _apiClient.fetchAddonCatalog(
          'https://v3-cinemeta.strem.io/manifest.json',
          cat['type'] as String,
          cat['catalog'] as String,
        );

        final moviesRawList = rawMovies['metas'] as List<dynamic>? ?? [];
        final movies = moviesRawList.map((m) => MediaItem.fromStremioJson(m)).toList();
        
        final newCache = Map<int, List<MediaItem>>.from(currentState.categoryMovies);
        newCache[categoryId] = movies;

        emit(currentState.copyWith(
          selectedCategoryId: categoryId,
          categoryMovies: newCache,
        ));
      } catch (e) {
        // Silent error, just show empty
        final newCache = Map<int, List<MediaItem>>.from(currentState.categoryMovies);
        newCache[categoryId] = [];
        emit(currentState.copyWith(
          selectedCategoryId: categoryId,
          categoryMovies: newCache,
        ));
      }
    }
  }
}
