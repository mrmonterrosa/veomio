import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_storage.dart';
import '../../data/models/media_item_model.dart';
import '../../data/models/stream_source_model.dart';
import '../../../addons/data/models/addon_manifest_model.dart';

abstract class StreamResolverState {}

class StreamResolverInitial extends StreamResolverState {}

class StreamResolverLoading extends StreamResolverState {}

class StreamResolverLoaded extends StreamResolverState {
  final List<StreamSource> sources;
  StreamResolverLoaded(this.sources);
}

class StreamResolvingDirect extends StreamResolverState {}

class StreamResolveSuccess extends StreamResolverState {
  final String directStreamUrl;
  StreamResolveSuccess(this.directStreamUrl);
}

class StreamResolverError extends StreamResolverState {
  final String message;
  StreamResolverError(this.message);
}

class StreamResolverCubit extends Cubit<StreamResolverState> {
  final ApiClient _apiClient;
  final LocalStorage _localStorage;

  StreamResolverCubit(this._apiClient, this._localStorage) : super(StreamResolverInitial());

  Future<void> resolveSources(MediaItem media, {int? season, int? episode}) async {
    emit(StreamResolverLoading());
    try {
      final List<StreamSource> allSources = [];

      // 1. Fetch sources from local Laravel API Scraper
      try {
        final localResult = await _apiClient.searchMovies(media.title);
        if (localResult['status'] == 'success' && localResult['data'] is Map) {
          final data = localResult['data'] as Map<String, dynamic>;
          
          // Match by title
          for (var title in data.keys) {
            // Check if title is a close match
            if (title.toLowerCase().contains(media.title.toLowerCase()) || 
                media.title.toLowerCase().contains(title.toLowerCase())) {
              final streamsList = data[title] as List<dynamic>;
              for (var stream in streamsList) {
                allSources.add(StreamSource.fromLaravelJson(stream as Map<String, dynamic>));
              }
            }
          }
        }
      } catch (e) {
        // Ignore local scraper resolution errors
      }

      // 2. Fetch sources from installed Stremio Addons
      final addonUrls = _localStorage.getInstalledAddonUrls();
      
      // Determine video ID for Stremio: movies use IMDB ID, series use IMDB ID:season:episode
      var videoId = media.id;
      final isSeries = media.type == 'series' || season != null;
      
      if (isSeries && season != null && episode != null) {
        videoId = '${media.id}:$season:$episode';
      }

      // Query each addon in parallel
      for (var url in addonUrls) {
        try {
          final manifestJson = await _apiClient.fetchAddonManifest(url);
          final addon = StremioAddon.fromJson(manifestJson, url);
          
          if (addon.resources.contains('stream')) {
            final type = isSeries ? 'series' : 'movie';
            final addonResult = await _apiClient.fetchAddonStreams(url, type, videoId);
            
            if (addonResult['streams'] is List) {
              final streams = addonResult['streams'] as List<dynamic>;
              for (var stream in streams) {
                allSources.add(StreamSource.fromStremioJson(stream as Map<String, dynamic>, addon.name));
              }
            }
          }
        } catch (e) {
          // Ignore individual addon failures
        }
      }

      if (allSources.isEmpty) {
        emit(StreamResolverError('No se encontraron enlaces de reproducción para este contenido.'));
      } else {
        emit(StreamResolverLoaded(allSources));
      }
    } catch (e) {
      emit(StreamResolverError('Error al buscar fuentes de reproducción: $e'));
    }
  }

  Future<void> resolvePlayableUrl(StreamSource source) async {
    if (!source.requiresResolve) {
      emit(StreamResolveSuccess(source.url));
      return;
    }

    emit(StreamResolvingDirect());
    try {
      // Resolve the embed url (e.g. Voe, Goodstream, Streamwish) to direct HLS via Laravel resolver
      final result = await _apiClient.resolveStream(source.url);
      
      if (result['status'] == 'success' && result['data'] is Map) {
        final data = result['data'] as Map<String, dynamic>;
        
        // The Laravel endpoint returns stream_proxy which is the rewritten HLS proxy URL
        // (bypasses CORS/Referer in Exoplayer / native players)
        final playUrl = data['stream_proxy'] as String? ?? data['stream_url'] as String?;
        if (playUrl != null) {
          emit(StreamResolveSuccess(playUrl));
        } else {
          emit(StreamResolverError('La respuesta del servidor no contiene una URL de stream válida.'));
        }
      } else {
        emit(StreamResolverError(result['message'] as String? ?? 'No se pudo resolver el enlace.'));
      }
    } catch (e) {
      emit(StreamResolverError('Error al resolver la URL de reproducción: $e'));
    }
  }
}
