import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/presentation/widgets/tv_focus_button.dart';
import '../bloc/live_tv_cubit.dart';
import '../../data/models/channel_model.dart';
import '../../../player/presentation/screens/video_player_screen.dart';

class LiveTvScreen extends StatefulWidget {
  const LiveTvScreen({super.key});

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen> {
  LiveChannel? _selectedChannel;

  @override
  void initState() {
    super.initState();
    context.read<LiveTvCubit>().loadChannels();
  }

  void _playChannel(LiveChannel channel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          streamUrl: channel.streamUrl,
          title: channel.name,
          subtitle: channel.nowPlaying ?? 'TV en Vivo',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LiveTvCubit, LiveTvState>(
      listener: (context, state) {
        if (state is LiveTvLoaded && _selectedChannel == null && state.channels.isNotEmpty) {
          setState(() {
            _selectedChannel = state.channels.first;
          });
        }
      },
      builder: (context, state) {
        if (state is LiveTvLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          );
        }

        if (state is LiveTvError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text(state.message, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 24),
                TvFocusButton(
                  isPrimary: true,
                  onTap: () => context.read<LiveTvCubit>().loadChannels(),
                  child: const Text('Reintentar'),
                )
              ],
            ),
          );
        }

        if (state is LiveTvLoaded) {
          final channels = state.filteredChannels;

          return Scaffold(
            backgroundColor: AppTheme.background,
            body: Padding(
              padding: const EdgeInsets.only(top: 36, bottom: 0, left: 58, right: 58),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Section: Preview & Info
                  if (_selectedChannel != null)
                    SizedBox(
                      height: 320,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Preview Window
                          Container(
                            width: 480,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.outlineVariant),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _selectedChannel!.logo != null && _selectedChannel!.logo!.isNotEmpty
                                    ? Image.network(
                                        _selectedChannel!.logo!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Center(
                                          child: Icon(Icons.live_tv, size: 64, color: AppTheme.onSurfaceVariant),
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(Icons.live_tv, size: 64, color: AppTheme.onSurfaceVariant),
                                      ),
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: const [
                                        Icon(Icons.circle, size: 8, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          // Program Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _selectedChannel!.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    if (_selectedChannel!.startTime != null && _selectedChannel!.endTime != null)
                                      Text(
                                        '${_selectedChannel!.startTime} - ${_selectedChannel!.endTime}',
                                        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.onSurfaceVariant),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedChannel!.nowPlaying ?? 'Televisión en Vivo',
                                  style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Sintoniza ${_selectedChannel!.name} para disfrutar de la mejor programación en vivo.',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.onSurfaceVariant),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    TvFocusButton(
                                      isPrimary: true,
                                      onTap: () => _playChannel(_selectedChannel!),
                                      child: Row(
                                        children: const [
                                          Icon(Icons.play_arrow, size: 28),
                                          SizedBox(width: 8),
                                          Text('Ver Ahora'),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    TvFocusButton(
                                      isPrimary: false,
                                      onTap: () {},
                                      child: Row(
                                        children: const [
                                          Icon(Icons.info_outline, size: 28),
                                          SizedBox(width: 8),
                                          Text('Detalles'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Bottom Section: EPG Grid Simulation
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        border: Border(top: BorderSide(color: AppTheme.surfaceVariant)),
                      ),
                      child: Column(
                        children: [
                          // Timeline Header
                          Container(
                            height: 48,
                            padding: const EdgeInsets.only(left: 180),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppTheme.surfaceVariant)),
                            ),
                            child: Row(
                              children: [
                                _buildTimeHeader('Ahora'),
                                _buildTimeHeader('Siguiente'),
                              ],
                            ),
                          ),
                          // Channels & Programs List
                          Expanded(
                            child: channels.isEmpty
                                ? Center(
                                    child: Text(
                                      'No hay canales disponibles.',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.onSurfaceVariant),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: channels.length,
                                    itemBuilder: (context, index) {
                                      final channel = channels[index];
                                      final isSelected = _selectedChannel?.id == channel.id;
                                      
                                      return Container(
                                        height: 72,
                                        decoration: const BoxDecoration(
                                          border: Border(bottom: BorderSide(color: AppTheme.surfaceVariant)),
                                        ),
                                        child: Row(
                                          children: [
                                            // Channel Name Column
                                            Container(
                                              width: 180,
                                              padding: const EdgeInsets.symmetric(horizontal: 24),
                                              alignment: Alignment.centerLeft,
                                              decoration: const BoxDecoration(
                                                color: AppTheme.surfaceDim,
                                                border: Border(right: BorderSide(color: AppTheme.surfaceVariant)),
                                              ),
                                              child: Text(
                                                channel.name,
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            // Programs Row
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                                                child: FocusableActionDetector(
                                                  onFocusChange: (focused) {
                                                    if (focused) {
                                                      setState(() => _selectedChannel = channel);
                                                    }
                                                  },
                                                  actions: {
                                                    ActivateIntent: CallbackAction<ActivateIntent>(
                                                      onInvoke: (_) {
                                                        _playChannel(channel);
                                                        return null;
                                                      },
                                                    ),
                                                  },
                                                  child: Builder(
                                                    builder: (context) {
                                                      final isFocused = Focus.of(context).hasFocus;
                                                      return GestureDetector(
                                                        onTap: () => _playChannel(channel),
                                                        child: AnimatedContainer(
                                                          duration: const Duration(milliseconds: 150),
                                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                                          decoration: BoxDecoration(
                                                            color: isFocused ? AppTheme.primary : (isSelected ? AppTheme.surfaceContainerHighest : AppTheme.surfaceContainer),
                                                            borderRadius: BorderRadius.circular(8),
                                                            border: Border.all(
                                                              color: isFocused ? AppTheme.primary : Colors.transparent,
                                                              width: 2,
                                                            ),
                                                          ),
                                                          alignment: Alignment.centerLeft,
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Text(
                                                                channel.nowPlaying ?? 'TV en Vivo',
                                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                                  color: isFocused ? AppTheme.onPrimary : Colors.white,
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                              if (channel.startTime != null && channel.endTime != null)
                                                                Text(
                                                                  '${channel.startTime} - ${channel.endTime}',
                                                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                                    color: isFocused ? AppTheme.onPrimary.withValues(alpha: 0.8) : AppTheme.onSurfaceVariant,
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTimeHeader(String time) {
    return Container(
      width: 400,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.centerLeft,
      child: Text(
        time,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold),
      ),
    );
  }
}
