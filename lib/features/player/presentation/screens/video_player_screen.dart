import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String streamUrl;
  final String title;
  final String? subtitle;

  const VideoPlayerScreen({
    super.key,
    required this.streamUrl,
    required this.title,
    this.subtitle,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player _player;
  late final VideoController _controller;
  
  bool _showControls = true;
  Timer? _hideTimer;
  
  double _volume = 1.0;
  bool _isMuted = false;

  // Player state trackers
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = true;
  bool _isBuffering = false;
  String? _errorMessage;

  // Listeners subscriptions
  late final List<StreamSubscription> _subscriptions;

  @override
  void initState() {
    super.initState();
    // Prevent screen dimming and lock orientation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _player = Player();
    _controller = VideoController(_player);

    // Set up state streams
    _subscriptions = [
      _player.stream.position.listen((p) {
        setState(() => _position = p);
      }),
      _player.stream.duration.listen((d) {
        setState(() => _duration = d);
      }),
      _player.stream.playing.listen((playing) {
        setState(() => _isPlaying = playing);
      }),
      _player.stream.buffering.listen((buffering) {
        setState(() => _isBuffering = buffering);
      }),
      _player.stream.error.listen((error) {
        setState(() => _errorMessage = error.toString());
      }),
    ];

    // Play media
    _player.open(Media(widget.streamUrl));
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    for (var s in _subscriptions) {
      s.cancel();
    }
    _player.dispose();
    
    // Restore UI overlays and orientation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _onUserInteraction() {
    if (!_showControls) {
      setState(() => _showControls = true);
    }
    _startHideTimer();
  }

  Future<void> _seekForward() async {
    _onUserInteraction();
    final target = _position + const Duration(seconds: 10);
    await _player.seek(target < _duration ? target : _duration);
  }

  Future<void> _seekBackward() async {
    _onUserInteraction();
    final target = _position - const Duration(seconds: 10);
    await _player.seek(target > Duration.zero ? target : Duration.zero);
  }

  Future<void> _togglePlayPause() async {
    _onUserInteraction();
    await _player.playOrPause();
  }

  Future<void> _toggleMute() async {
    _onUserInteraction();
    setState(() {
      _isMuted = !_isMuted;
      _player.setVolume(_isMuted ? 0.0 : _volume * 100);
    });
  }

  // Handle D-pad and TV Remote shortcuts
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        _togglePlayPause();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _seekBackward();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _seekForward();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _onUserInteraction();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: GestureDetector(
          onTap: _toggleControls,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // 1. Native Video Player Render
              Center(
                child: Video(
                  controller: _controller,
                  controls: null, // Custom overlay
                ),
              ),

              // 2. Loading / Buffering Indicator
              if (_isBuffering && _errorMessage == null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                      strokeWidth: 4,
                    ),
                  ),
                ),

              // 3. Error Overlay
              if (_errorMessage != null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'Error de reproducción',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Volver'),
                        )
                      ],
                    ),
                  ),
                ),

              // 4. Custom Video Controls HUD
              AnimatedOpacity(
                opacity: _showControls && _errorMessage == null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: _buildControlsOverlay(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black87,
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.9),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Bar
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.sora(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Stream Information tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  widget.streamUrl.contains('.m3u8') ? 'HLS LIVE' : 'MPV DIRECT',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondary,
                  ),
                ),
              ),
            ],
          ),

          // Center Player Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10, color: Colors.white, size: 36),
                onPressed: _seekBackward,
              ),
              const SizedBox(width: 32),
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(width: 32),
              IconButton(
                icon: const Icon(Icons.forward_10, color: Colors.white, size: 36),
                onPressed: _seekForward,
              ),
            ],
          ),

          // Bottom Bar & Timeline
          Column(
            children: [
              // Time bar
              Row(
                children: [
                  Text(
                    _formatDuration(_position),
                    style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 14),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        activeTrackColor: AppTheme.primary,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: AppTheme.primary,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      ),
                      child: Slider(
                        value: _position.inMilliseconds.toDouble(),
                        min: 0.0,
                        max: _duration.inMilliseconds.toDouble() > 0.0
                            ? _duration.inMilliseconds.toDouble()
                            : 1.0,
                        onChanged: (val) {
                          _onUserInteraction();
                          _player.seek(Duration(milliseconds: val.toInt()));
                        },
                      ),
                    ),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Utility row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isMuted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white,
                        ),
                        onPressed: _toggleMute,
                      ),
                      SizedBox(
                        width: 100,
                        child: Slider(
                          value: _isMuted ? 0.0 : _volume,
                          min: 0.0,
                          max: 1.0,
                          activeColor: AppTheme.secondary,
                          onChanged: (val) {
                            _onUserInteraction();
                            setState(() {
                              _volume = val;
                              _isMuted = _volume == 0.0;
                              _player.setVolume(_isMuted ? 0.0 : _volume * 100);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  // Tracks selector (Audio / Subtitles)
                  Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.audiotrack, color: Colors.white, size: 18),
                        label: const Text('Audio', style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          _onUserInteraction();
                          _showTrackSelector('Audio');
                        },
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        icon: const Icon(Icons.subtitles, color: Colors.white, size: 18),
                        label: const Text('Subtítulos', style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          _onUserInteraction();
                          _showTrackSelector('Subtítulos');
                        },
                      ),
                    ],
                  )
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  void _showTrackSelector(String title) {
    // In media_kit, tracks are available inside _player.state.tracks.
    // For our MVP, we display a premium dialog letting the user know they can select tracks,
    // listing the standard MPV tracks (which auto-fetches embedded HLS streams!).
    final tracks = _player.state.tracks;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.outline),
          ),
          title: Text(
            'Seleccionar $title',
            style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: title == 'Audio' ? tracks.audio.length : tracks.subtitle.length,
              itemBuilder: (context, index) {
                final isAudio = title == 'Audio';
                final audioTrack = isAudio ? tracks.audio[index] : null;
                final subtitleTrack = !isAudio ? tracks.subtitle[index] : null;

                final isSelected = isAudio
                    ? _player.state.track.audio == audioTrack
                    : _player.state.track.subtitle == subtitleTrack;

                final trackName = isAudio
                    ? (audioTrack!.title ?? audioTrack.language ?? 'Audio ${index + 1}')
                    : (subtitleTrack!.title ?? subtitleTrack.language ?? 'Subtítulo ${index + 1}');

                return ListTile(
                  leading: Icon(
                    isAudio ? Icons.music_note : Icons.subtitles,
                    color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
                  ),
                  title: Text(
                    trackName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primary) : null,
                  onTap: () {
                    if (isAudio) {
                      _player.setAudioTrack(audioTrack!);
                    } else {
                      _player.setSubtitleTrack(subtitleTrack!);
                    }
                    Navigator.pop(context);
                    final logName = isAudio
                        ? (audioTrack!.title ?? audioTrack.language ?? audioTrack.id)
                        : (subtitleTrack!.title ?? subtitleTrack.language ?? subtitleTrack.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Cambiando a $logName'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}
