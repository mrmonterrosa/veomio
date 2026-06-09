import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_storage.dart';
import '../../data/models/addon_manifest_model.dart';

abstract class AddonsState {}

class AddonsInitial extends AddonsState {}

class AddonsLoading extends AddonsState {}

class AddonsLoaded extends AddonsState {
  final List<StremioAddon> addons;
  AddonsLoaded(this.addons);
}

class AddonsError extends AddonsState {
  final String message;
  AddonsError(this.message);
}

class AddonsCubit extends Cubit<AddonsState> {
  final ApiClient _apiClient;
  final LocalStorage _localStorage;

  AddonsCubit(this._apiClient, this._localStorage) : super(AddonsInitial());

  Future<void> loadAddons() async {
    emit(AddonsLoading());
    try {
      final urls = _localStorage.getInstalledAddonUrls();
      final List<StremioAddon> addonsList = [];

      for (var url in urls) {
        try {
          final jsonManifest = await _apiClient.fetchAddonManifest(url);
          addonsList.add(StremioAddon.fromJson(jsonManifest, url));
        } catch (e) {
          // If an addon fails to load, create a placeholder addon so we don't break the list
          addonsList.add(StremioAddon(
            id: 'failed_${url.hashCode}',
            name: 'Error al cargar complemento',
            version: '0.0.0',
            description: 'No se pudo conectar a la URL: $url',
            resources: [],
            types: [],
            catalogs: [],
            manifestUrl: url,
          ));
        }
      }
      emit(AddonsLoaded(addonsList));
    } catch (e) {
      emit(AddonsError('Error al leer complementos guardados: $e'));
    }
  }

  Future<void> installAddon(String url) async {
    emit(AddonsLoading());
    try {
      // Clean url (some users might input stremio:// protocols, replace with https://)
      var cleanedUrl = url.trim();
      if (cleanedUrl.startsWith('stremio://')) {
        cleanedUrl = cleanedUrl.replaceAll('stremio://', 'https://');
      }
      
      // Fetch manifest to validate
      final jsonManifest = await _apiClient.fetchAddonManifest(cleanedUrl);
      StremioAddon.fromJson(jsonManifest, cleanedUrl);

      // Save url
      await _localStorage.addAddonUrl(cleanedUrl);

      // Reload addons
      await loadAddons();
    } catch (e) {
      emit(AddonsError('No se pudo instalar el complemento. Verifica la URL. Detalles: $e'));
      // Reload previous ones
      await loadAddons();
    }
  }

  Future<void> uninstallAddon(String url) async {
    emit(AddonsLoading());
    try {
      await _localStorage.removeAddonUrl(url);
      await loadAddons();
    } catch (e) {
      emit(AddonsError('Error al desinstalar el complemento: $e'));
      await loadAddons();
    }
  }
}
