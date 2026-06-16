import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/presentation/widgets/tv_focus_button.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String streamUrl;
  final String title;
  final String? subtitle;
  final bool isLive;

  const VideoPlayerScreen({
    super.key,
    required this.streamUrl,
    required this.title,
    this.subtitle,
    this.isLive = false,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _nativeController;
  Player? _mkPlayer;
  VideoController? _mkController;
  
  String _playerType = 'native';
  LocalStorage? _localStorage;
  
  final FocusNode _rootFocusNode = FocusNode();
  final FocusNode _swapPlayerFocusNode = FocusNode();
  final FocusNode _errorFocusNode = FocusNode();
  
  bool _showControls = true;
  Timer? _hideTimer;

  // Player state trackers
  bool _isBuffering = true; // start as true until initialized
  String? _errorMessage;
  BoxFit _currentFit = BoxFit.cover;

  IconData _getFitIcon() {
    switch (_currentFit) {
      case BoxFit.cover:
        return Icons.fullscreen_exit;
      case BoxFit.contain:
        return Icons.fit_screen;
      case BoxFit.fill:
        return Icons.aspect_ratio;
      default:
        return Icons.aspect_ratio;
    }
  }

  void _toggleFit() {
    _onUserInteraction();
    setState(() {
      if (_currentFit == BoxFit.cover) {
        _currentFit = BoxFit.contain;
      } else if (_currentFit == BoxFit.contain) {
        _currentFit = BoxFit.fill;
      } else {
        _currentFit = BoxFit.cover;
      }
    });
  }

  StreamSubscription? _mkPlayingSub;
  StreamSubscription? _mkPositionSub;
  StreamSubscription? _mkDurationSub;
  StreamSubscription? _mkBufferingSub;
  StreamSubscription? _mkErrorSub;

  bool get _isMediaKit => _playerType == 'mediakit';
  bool get _isInitialized => _isMediaKit 
      ? (_mkController != null) 
      : (_nativeController?.value.isInitialized ?? false);

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _initPlayerAsync();
  }

  Future<void> _initPlayerAsync() async {
    try {
      _localStorage = await LocalStorage.init();
      if (!mounted) return;
      
      setState(() {
        _playerType = _localStorage!.getPlayerType();
      });

      if (_isMediaKit) {
        _initMediaKit();
      } else {
        _initNativePlayer();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al inicializar el reproductor: $e';
        _isBuffering = false;
      });
    }

    _startHideTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _swapPlayerFocusNode.requestFocus();
    });
  }
  
  void _initMediaKit() {
    _mkPlayer = Player(configuration: const PlayerConfiguration(
      bufferSize: 32 * 1024 * 1024,
    ));
    _mkController = VideoController(
      _mkPlayer!,
      configuration: const VideoControllerConfiguration(
        androidAttachSurfaceAfterVideoParameters: true,
        vo: 'mediacodec_embed',
        hwdec: 'mediacodec',
      ),
    );
    
    _mkPlayingSub = _mkPlayer!.stream.playing.listen((isPlaying) {});
    _mkBufferingSub = _mkPlayer!.stream.buffering.listen((isBuffering) {
      if (mounted) setState(() => _isBuffering = isBuffering);
    });
    _mkErrorSub = _mkPlayer!.stream.error.listen((error) {
      if (mounted && error != 'no error') {
        setState(() {
          _errorMessage = error;
          _isBuffering = false;
          _showControls = false; // ocultar controles para no estorbar
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _errorFocusNode.requestFocus();
        });
      }
    });

    _mkPlayer!.open(Media(widget.streamUrl), play: true).then((_) {
      if (mounted) setState(() => _isBuffering = false);
    }).catchError((e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isBuffering = false;
          _showControls = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _errorFocusNode.requestFocus();
        });
      }
    });
  }

  void _initNativePlayer() {
    _nativeController = VideoPlayerController.networkUrl(
      Uri.parse(widget.streamUrl),
    )..initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _isBuffering = false;
        });
        _nativeController!.play();
      }).catchError((error) {
        if (!mounted) return;
        setState(() {
          _errorMessage = error.toString();
          _isBuffering = false;
          _showControls = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _errorFocusNode.requestFocus();
        });
      });
    _nativeController!.addListener(_onNativePlayerStateChanged);
  }

  Future<void> _togglePlayerTypeOnTheFly() async {
    _onUserInteraction();
    
    final newType = _isMediaKit ? 'native' : 'mediakit';
    
    setState(() {
      _isBuffering = true;
      _errorMessage = null;
      _playerType = newType;
    });

    _nativeController?.removeListener(_onNativePlayerStateChanged);
    
    _mkPlayingSub?.cancel();
    _mkPositionSub?.cancel();
    _mkDurationSub?.cancel();
    _mkBufferingSub?.cancel();
    _mkErrorSub?.cancel();
    
    await _mkPlayer?.dispose();
    await _nativeController?.dispose();
    
    _mkPlayer = null;
    _mkController = null;
    _nativeController = null;

    if (_localStorage != null) {
      await _localStorage!.setPlayerType(newType);
    }

    if (_isMediaKit) {
      _initMediaKit();
    } else {
      _initNativePlayer();
    }
  }

  void _onNativePlayerStateChanged() {
    if (!mounted || _nativeController == null) return;
    
    final wasAlreadyInitialized = _isInitialized;
    bool needsSetState = false;

    if (_isBuffering != _nativeController!.value.isBuffering) {
      _isBuffering = _nativeController!.value.isBuffering;
      needsSetState = true;
    }

    if (_nativeController!.value.hasError && _errorMessage != _nativeController!.value.errorDescription) {
      _errorMessage = _nativeController!.value.errorDescription;
      needsSetState = true;
    }

    if (needsSetState) {
      setState(() {});
    }

    if (!wasAlreadyInitialized && _nativeController!.value.isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_showControls && mounted) {
          _swapPlayerFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _rootFocusNode.dispose();
    _swapPlayerFocusNode.dispose();
    _errorFocusNode.dispose();

    _mkPlayingSub?.cancel();
    _mkPositionSub?.cancel();
    _mkDurationSub?.cancel();
    _mkBufferingSub?.cancel();
    _mkErrorSub?.cancel();

    _mkPlayer?.dispose();
    _nativeController?.removeListener(_onNativePlayerStateChanged);
    _nativeController?.dispose();
    
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
    if (_errorMessage != null) return; // No auto-hide si hay error
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _errorMessage == null) {
        setState(() => _showControls = false);
        _rootFocusNode.requestFocus();
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _swapPlayerFocusNode.requestFocus();
      });
      _startHideTimer();
    } else {
      _rootFocusNode.requestFocus();
      _hideTimer?.cancel();
    }
  }

  void _onUserInteraction() {
    if (_errorMessage != null) return; // No manejar interacción de controles si hay popup
    if (!_showControls) {
      setState(() => _showControls = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _swapPlayerFocusNode.requestFocus();
      });
    }
    _startHideTimer();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (_errorMessage != null) {
        return KeyEventResult.ignored; // Dejar que el Row maneje el foco
      }
      if (!_showControls) {
        _onUserInteraction();
        return KeyEventResult.handled;
      } else {
        _startHideTimer();
        return KeyEventResult.ignored;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PopScope(
        canPop: _errorMessage == null,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_errorMessage != null) {
            setState(() {
              _errorMessage = null;
            });
            _rootFocusNode.requestFocus();
          }
        },
        child: Focus(
          focusNode: _rootFocusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: GestureDetector(
          onTap: _toggleControls,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              if (!_isMediaKit && _nativeController != null && _nativeController!.value.isInitialized)
                Transform.scale(
                  scale: 1.01,
                  child: SizedBox.expand(
                    child: FittedBox(
                      fit: _currentFit,
                      child: SizedBox(
                        width: _nativeController!.value.size.width > 0 ? _nativeController!.value.size.width : 16,
                        height: _nativeController!.value.size.height > 0 ? _nativeController!.value.size.height : 9,
                        child: VideoPlayer(_nativeController!),
                      ),
                    ),
                  ),
                ),
              if (_isMediaKit && _mkController != null)
                Transform.scale(
                  scale: 1.01,
                  child: SizedBox.expand(
                    child: Video(
                      controller: _mkController!,
                      fit: _currentFit,
                      controls: NoVideoControls,
                    ),
                  ),
                ),

              if (_isBuffering || !_isInitialized)
                if (_errorMessage == null)
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
                          'Aviso del Reproductor',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'La señal presenta inestabilidad o el formato no es soportado de forma nativa por este motor. Si el video sigue reproduciéndose, puedes ignorar este aviso.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TvFocusButton(
                              focusNode: _errorFocusNode,
                              isPrimary: true,
                              onTap: () {
                                setState(() {
                                  _errorMessage = null;
                                });
                                _rootFocusNode.requestFocus();
                              },
                              child: const Text('Ignorar', style: TextStyle(color: Colors.black)),
                            ),
                            const SizedBox(width: 16),
                            TvFocusButton(
                              onTap: _togglePlayerTypeOnTheFly,
                              child: const Text(
                                'Cambiar Motor',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 16),
                            TvFocusButton(
                              onTap: () => Navigator.pop(context),
                              child: const Text('Salir', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),

              AnimatedOpacity(
                opacity: _showControls && _errorMessage == null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !_showControls || _errorMessage != null,
                  child: RepaintBoundary(
                    child: _buildControlsOverlay(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    final isMobile = MediaQuery.of(context).size.shortestSide < 600;
    return SafeArea(
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 24.0 : 48.0, vertical: isMobile ? 16.0 : 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              if (widget.subtitle != null)
                Text(
                  widget.subtitle!,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 18,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              TvFocusButton(
                onTap: _toggleFit,
                child: Icon(_getFitIcon(), size: 28, color: Colors.white),
              ),
              const SizedBox(width: 16),
              TvFocusButton(
                focusNode: _swapPlayerFocusNode,
                onTap: _togglePlayerTypeOnTheFly,
                isPrimary: true,
                child: const Icon(Icons.swap_horiz, size: 28, color: AppTheme.onPrimary),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Motor: ${_isMediaKit ? "MediaKit" : "Nativo"}',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ],
            ),
          ],
        ),
      ),
          if (isMobile)
            Positioned(
              top: 16.0,
              left: 24.0,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
