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

  CatalogCubit(this._apiClient) : super(CatalogInitial());

  Future<void> loadCatalog() async {
    emit(CatalogLoading());
    try {
      final categories = await _apiClient.getCategories();
      final nowPlayingRaw = await _apiClient.getNowPlaying();
      final nowPlaying = nowPlayingRaw.map((m) => MediaItem.fromLaravelJson(m)).toList();

      int initialCategory = -1;
      if (categories.isNotEmpty) {
        initialCategory = categories.first['id'] as int;
      }

      final Map<int, List<MediaItem>> categoryMovies = {};
      if (initialCategory != -1) {
        final categoryName = categories.first['name'] as String;
        final moviesRaw = await _apiClient.getMoviesByCategory(categoryName);
        categoryMovies[initialCategory] = moviesRaw.map((m) => MediaItem.fromLaravelJson(m)).toList();
      }

      emit(CatalogLoaded(
        categories: categories,
        nowPlaying: nowPlaying,
        categoryMovies: categoryMovies,
        selectedCategoryId: initialCategory,
      ));
    } catch (e) {
      emit(CatalogError('No se pudo conectar con el servidor API local: $e'));
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

      // Load category movies
      try {
        final moviesRaw = await _apiClient.getMoviesByCategory(categoryName);
        final movies = moviesRaw.map((m) => MediaItem.fromLaravelJson(m)).toList();
        
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
