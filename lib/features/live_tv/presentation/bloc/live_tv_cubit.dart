import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/channel_model.dart';

abstract class LiveTvState {}

class LiveTvInitial extends LiveTvState {}

class LiveTvLoading extends LiveTvState {}

class LiveTvLoaded extends LiveTvState {
  final List<LiveChannel> channels;
  final List<String> categories;
  final String selectedCategory;

  LiveTvLoaded({
    required this.channels,
    required this.categories,
    required this.selectedCategory,
  });

  List<LiveChannel> get filteredChannels {
    if (selectedCategory == 'Todos') {
      return channels;
    }
    return channels.where((c) => c.category == selectedCategory).toList();
  }

  LiveTvLoaded copyWith({
    List<LiveChannel>? channels,
    List<String>? categories,
    String? selectedCategory,
  }) {
    return LiveTvLoaded(
      channels: channels ?? this.channels,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class LiveTvError extends LiveTvState {
  final String message;
  LiveTvError(this.message);
}

class LiveTvCubit extends Cubit<LiveTvState> {
  final ApiClient _apiClient;

  LiveTvCubit(this._apiClient) : super(LiveTvInitial());

  Future<void> loadChannels() async {
    emit(LiveTvLoading());
    try {
      final channelsRaw = await _apiClient.getLiveChannels();
      final channels = channelsRaw.map((c) => LiveChannel.fromJson(c as Map<String, dynamic>)).toList();
      
      final Set<String> categoriesSet = {'Todos'};
      for (var c in channels) {
        if (c.category != null && c.category!.isNotEmpty) {
          categoriesSet.add(c.category!);
        }
      }

      emit(LiveTvLoaded(
        channels: channels,
        categories: categoriesSet.toList(),
        selectedCategory: 'Todos',
      ));
    } catch (e) {
      emit(LiveTvError('No se pudieron cargar los canales de TV: $e'));
    }
  }

  void selectCategory(String category) {
    final currentState = state;
    if (currentState is LiveTvLoaded) {
      emit(currentState.copyWith(selectedCategory: category));
    }
  }
}
