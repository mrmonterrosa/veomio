import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/presentation/widgets/tv_focus_card.dart';
import '../../../../core/presentation/widgets/tv_focus_button.dart';
import '../bloc/live_tv_cubit.dart';
import '../../data/models/channel_model.dart';
import '../../../player/presentation/screens/video_player_screen.dart';

class LiveTvScreen extends StatefulWidget {
  const LiveTvScreen({super.key});

  static final FocusNode playButtonNode = FocusNode();

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen> {
  final ValueNotifier<LiveChannel?> _selectedChannel = ValueNotifier(null);
  VideoPlayerController? _videoController;
  Timer? _debounceTimer;
  final ScrollController _scrollController = ScrollController();
  final Map<String, FocusNode> _channelFocusNodes = {};
  DateTime? _lastUpPress;
  bool _isFirstLoad = true;
  bool _isCompactMode = false;
  int _upPressCount = 0;
  bool _shouldFocusFirstChannelAfterSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    LiveTvScreen.playButtonNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowDown) {
        final channelIdToFocus = _selectedChannel.value?.id;
        if (channelIdToFocus != null && _channelFocusNodes.containsKey(channelIdToFocus)) {
          _channelFocusNodes[channelIdToFocus]!.requestFocus();
        } else if (_channelFocusNodes.isNotEmpty) {
          _channelFocusNodes.values.first.requestFocus();
        }
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };
    context.read<LiveTvCubit>().loadChannels();
  }

  @override
  void dispose() {
    for (var node in _channelFocusNodes.values) {
      node.dispose();
    }
    _scrollController.dispose();
    _debounceTimer?.cancel();
    _videoController?.dispose();
    _selectedChannel.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    if (_scrollController.offset > 50 && !_isCompactMode) {
      setState(() {
        _isCompactMode = true;
        _upPressCount = 0; // reset press count when scrolling down
      });
      _videoController?.pause();
    } else if (_scrollController.offset <= 10 && _isCompactMode) {
      setState(() {
        _isCompactMode = false;
        _upPressCount = 0;
      });
      _videoController?.play();
    }

    // Infinite scrolling logic
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (currentScroll >= maxScroll - 400) { // Cargar cuando falten 400px para el final
        context.read<LiveTvCubit>().loadMoreChannels();
      }
    }
  }

  void _onChannelFocused(LiveChannel channel) {
    if (_selectedChannel.value?.id == channel.id) return;
    _selectedChannel.value = channel;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _loadBackgroundVideo(channel);
    });
  }

  Future<void> _loadBackgroundVideo(LiveChannel channel) async {
    final oldController = _videoController;
    _videoController = null;
    if (mounted) setState(() {});
    await oldController?.dispose();

    if (!mounted) return;
    final url = await context.read<LiveTvCubit>().getStreamUrl(channel);
    
    if (url != null && url.isNotEmpty && mounted && _selectedChannel.value?.id == channel.id) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      try {
        await controller.initialize();
        controller.setVolume(0.0);
        controller.setLooping(true);
        controller.play();

        if (mounted && _selectedChannel.value?.id == channel.id) {
          setState(() {
            _videoController = controller;
          });
        } else {
          controller.dispose();
        }
      } catch (e) {
        controller.dispose();
      }
    }
  }

  void _playChannel(LiveChannel channel) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
        ),
      ),
    );

    final streamUrl = await context.read<LiveTvCubit>().getStreamUrl(channel);
    
    if (mounted) {
      Navigator.pop(context);
    }

    if (streamUrl != null && streamUrl.isNotEmpty) {
      if (mounted) {
        // Pause background video
        _videoController?.pause();
        
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(
              streamUrl: streamUrl,
              title: channel.name,
              subtitle: channel.nowPlaying ?? 'TV en Vivo',
              isLive: true,
            ),
          ),
        );
        
        // Resume background video when returning
        if (mounted) {
          _videoController?.play();
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay transmisiones disponibles para este canal')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return BlocConsumer<LiveTvCubit, LiveTvState>(
      listener: (context, state) {
        if (state is LiveTvLoaded) {
          if (_selectedChannel.value == null && state.channels.isNotEmpty) {
            _onChannelFocused(state.channels.first);
          }
          if (_shouldFocusFirstChannelAfterSearch && state.filteredChannels.isNotEmpty) {
            _shouldFocusFirstChannelAfterSearch = false;
            final firstChannelId = state.filteredChannels.first.id;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _channelFocusNodes.containsKey(firstChannelId)) {
                _channelFocusNodes[firstChannelId]!.requestFocus();
              }
            });
          }
        }
      },
      builder: (context, state) {
        if (state is LiveTvLoading) {
          return const Center(
            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary)),
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
          
          if (_isFirstLoad && channels.isNotEmpty) {
            _isFirstLoad = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _selectedChannel.value = channels.first;
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) LiveTvScreen.playButtonNode.requestFocus();
                });
              }
            });
          }

          return Scaffold(
            backgroundColor: AppTheme.background,
            body: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                          // Foreground Metadata
                          ValueListenableBuilder<LiveChannel?>(
                            valueListenable: _selectedChannel,
                            builder: (context, selected, _) {
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(opacity: animation, child: SizeTransition(sizeFactor: animation, child: child));
                                },
                                child: selected == null
                                    ? const SizedBox(key: ValueKey('empty'))
                                    : (_isCompactMode || (isMobile && isKeyboardOpen))
                                        ? _buildCompactHeader(selected)
                                        : _buildExpandedHeader(selected),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Search Bar
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 88.0),
                            child: TextField(
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: 'Buscar canal...',
                                hintStyle: const TextStyle(color: Colors.white54),
                                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                                filled: true,
                                fillColor: Colors.white10,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              onSubmitted: (value) {
                                _shouldFocusFirstChannelAfterSearch = true;
                                context.read<LiveTvCubit>().searchChannels(value);
                              },
                            ),
                          ),
                          
                          const SizedBox(height: 16),

                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: isMobile ? 16.0 : 88.0, right: isMobile ? 16.0 : 58.0),
                              child: channels.isEmpty
                                ? Center(
                                    child: Text(
                                      'No hay canales disponibles.',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.onSurfaceVariant),
                                    ),
                                  )
                                : Focus(
                                    onKeyEvent: (node, event) {
                                      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                                        // Saltamos al banner superior SOLO si es una pulsación larga (KeyRepeat)
                                        // Las pulsaciones cortas permitirán subir a la barra de búsqueda naturalmente
                                        if (event is KeyRepeatEvent) {
                                          if (!_isCompactMode) {
                                            LiveTvScreen.playButtonNode.requestFocus();
                                          } else {
                                            setState(() {
                                              _isCompactMode = false;
                                            });
                                            _videoController?.play();
                                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                              if (mounted) LiveTvScreen.playButtonNode.requestFocus();
                                            });
                                          }
                                          return KeyEventResult.handled;
                                        }
                                      }
                                      return KeyEventResult.ignored;
                                    },
                                    child: GridView.builder(
                                      clipBehavior: Clip.hardEdge,
                                      controller: _scrollController,
                                      padding: const EdgeInsets.only(top: 24, bottom: 64, left: 16, right: 16),
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: isMobile ? 2 : 3,
                                        childAspectRatio: isMobile ? 1.0 : 4.0,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                      ),
                                      itemCount: channels.length,
                                          itemBuilder: (context, index) {
                                            final channel = channels[index];
                                            final node = _channelFocusNodes.putIfAbsent(channel.id, () => FocusNode());

                                            return ValueListenableBuilder<LiveChannel?>(
                                              valueListenable: _selectedChannel,
                                              builder: (context, selected, _) {
                                                final isSelected = selected?.id == channel.id;

                                                return TvFocusCard(
                                                  key: ValueKey(channel.id),
                                                  focusNode: node,
                                                  focusedScale: 1.1,
                                                  onTap: () => _playChannel(channel),
                                                  onFocusChange: (focused) {
                                                    if (focused) _onChannelFocused(channel);
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: isSelected ? const Color(0xFF2A2A35) : const Color(0xFF1E1E24), // Solid dark grey always
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                                    alignment: isMobile ? Alignment.center : Alignment.centerLeft,
                                                    child: Text(
                                                      channel.name,
                                                      textAlign: isMobile ? TextAlign.center : TextAlign.left,
                                                      style: TextStyle(
                                                        color: isSelected ? AppTheme.primary : Colors.white,
                                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                        fontSize: 16,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                      if (isMobile)
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
          }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFallback() {
    return const SizedBox();
  }

  Widget _buildCompactHeader(LiveChannel selected) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      key: const ValueKey('compact'),
      padding: EdgeInsets.only(left: isMobile ? 16.0 : 88.0, top: isMobile ? 80.0 : 40.0, right: isMobile ? 16.0 : 58.0, bottom: 16.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _BlinkingDot(),
                SizedBox(width: 4),
                Text('EN VIVO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            selected.name,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedHeader(LiveChannel selected) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      key: const ValueKey('expanded'),
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.7,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Video / Image
          _videoController != null && _videoController!.value.isInitialized
              ? FittedBox(
                  fit: BoxFit.cover,
                  alignment: isMobile ? Alignment.topCenter : Alignment.center,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                )
              : (selected.logo != null && selected.logo!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: selected.logo!,
                      fit: BoxFit.cover,
                      alignment: isMobile ? Alignment.topCenter : Alignment.center,
                      fadeInDuration: const Duration(milliseconds: 500),
                      placeholder: (context, url) => Container(color: AppTheme.background),
                      errorWidget: (context, url, error) => Container(color: AppTheme.background),
                    )
                  : Container(color: AppTheme.background),
                  
          // Gradient Overlay exactly matching hero-gradient from home_screen
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppTheme.background,
                    AppTheme.background.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppTheme.background,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4],
                ),
              ),
            ),
          ),
          
          // Metadata Content
          Positioned(
            bottom: 0,
            left: isMobile ? 16.0 : 88.0, // Mathing gridview offset
            width: MediaQuery.of(context).size.width * (isMobile ? 0.9 : 0.6),
            child: Padding(
              padding: EdgeInsets.only(bottom: isMobile ? 80.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TRANSMISIÓN EN VIVO',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.primary,
                          letterSpacing: 2,
                        ),
                  ),
                  const SizedBox(height: 4),
                  selected.logo != null && selected.logo!.isNotEmpty
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: CachedNetworkImage(
                            imageUrl: selected.logo!,
                            height: 80,
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.contain,
                            fadeInDuration: const Duration(milliseconds: 500),
                            placeholder: (context, url) => const SizedBox(height: 80, width: 100),
                            errorWidget: (context, url, error) => Text(
                              selected.name,
                              style: GoogleFonts.sora(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          selected.name,
                          style: GoogleFonts.sora(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
                            ],
                          ),
                        ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            _BlinkingDot(),
                            SizedBox(width: 4),
                            Text('EN VIVO', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.outlineVariant),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('FHD', style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      TvFocusButton(
                        focusNode: LiveTvScreen.playButtonNode,
                        isPrimary: true,
                        onTap: () => _playChannel(selected),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.play_arrow, size: 24),
                            SizedBox(width: 8),
                            Text('Ver Ahora'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot();

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: const Icon(Icons.circle, size: 8, color: Colors.white),
    );
  }
}
