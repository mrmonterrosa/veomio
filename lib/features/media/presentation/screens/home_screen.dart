import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/presentation/widgets/tv_focus_card.dart';
import '../../../../core/presentation/widgets/tv_focus_button.dart';
import '../../data/models/media_item_model.dart';
import '../bloc/catalog_cubit.dart';
import 'media_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final LocalStorage localStorage;
  static final FocusNode heroFocusNode = FocusNode();

  const HomeScreen({super.key, required this.localStorage});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _continueWatching = [];
  final ScrollController _scrollController = ScrollController();
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    context.read<CatalogCubit>().loadCatalog();
    _loadContinueWatching();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadContinueWatching() {
    setState(() {
      _continueWatching = widget.localStorage.getContinueWatching();
    });
  }

  void _openMediaDetail(MediaItem media) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaDetailScreen(mediaItem: media),
      ),
    ).then((_) => _loadContinueWatching());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogCubit, CatalogState>(
      builder: (context, state) {
        if (state is CatalogLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          );
        }

        if (state is CatalogError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text(state.message, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 24),
                TvFocusButton(
                  isPrimary: true,
                  onTap: () => context.read<CatalogCubit>().loadCatalog(),
                  child: const Text('Reintentar'),
                )
              ],
            ),
          );
        }

        if (state is CatalogLoaded) {
          final nowPlaying = state.nowPlaying;
          final categories = state.categories;
          
          final heroMedia = nowPlaying.isNotEmpty 
              ? nowPlaying.first 
              : MediaItem(
                  id: 'neon_horizon',
                  title: 'Neon Horizon',
                  releaseYear: '2024',
                  releaseDate: '2024-01-01',
                  thumbnail: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBCaRVnPoTambZxSPWzVlyK43w6TYUsfDr_F5CK0xTwc-80nkV1TdcKb-xp_7pRXg5h0RJ6GsAIYY2iGLYw1fk5GpvmSGnI-WZUUvX2gRGK9I4BkbiJXbaReWwsQ3cyESPBvY3K6wfV5MlCn1wcRMGKBCaPhZFkuVdzdmbqTUH6XjTILJXhQsvdoqu5NRBywVltc2skuwWSz7gDkQ-knF1B6qoEVkj5hoGzBXFXgBudXoRXtAF9L-GswVxx1BYtJR-GnafFhL5yaGc',
                  backdrop: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBCaRVnPoTambZxSPWzVlyK43w6TYUsfDr_F5CK0xTwc-80nkV1TdcKb-xp_7pRXg5h0RJ6GsAIYY2iGLYw1fk5GpvmSGnI-WZUUvX2gRGK9I4BkbiJXbaReWwsQ3cyESPBvY3K6wfV5MlCn1wcRMGKBCaPhZFkuVdzdmbqTUH6XjTILJXhQsvdoqu5NRBywVltc2skuwWSz7gDkQ-knF1B6qoEVkj5hoGzBXFXgBudXoRXtAF9L-GswVxx1BYtJR-GnafFhL5yaGc',
                  plot: 'En una metrópolis en expansión donde los recuerdos son moneda de cambio...',
                  rating: 8.8,
                  type: 'movie',
                );

          if (_isFirstLoad) {
            _isFirstLoad = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                HomeScreen.heroFocusNode.requestFocus();
              }
            });
          }

          return SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroBanner(heroMedia),
                
                if (_continueWatching.isNotEmpty) ...[
                  _buildSectionTitle('Continuar viendo'),
                  _buildContinueWatchingRail(),
                  const SizedBox(height: 48),
                ],

                if (nowPlaying.length > 1) ...[
                  _buildSectionTitle('En Cartelera'),
                  _buildMovieRail(nowPlaying.skip(1).toList()),
                  const SizedBox(height: 48),
                ],

                // Categorias rails
                ...categories.map((category) {
                  final catId = category['id'] as int;
                  final catName = category['name'] as String;
                  final categoryMovies = state.categoryMovies[catId] ?? [];
                  
                  if (categoryMovies.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(catName),
                      _buildMovieRail(categoryMovies),
                      const SizedBox(height: 48),
                    ],
                  );
                }).toList(),
                
                const SizedBox(height: 60),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Padding(
      padding: EdgeInsets.only(left: isMobile ? 16.0 : 58.0, bottom: isMobile ? 16.0 : 24.0),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, color: AppTheme.primary, size: 20),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(MediaItem media) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      height: MediaQuery.of(context).size.height * (isMobile ? 0.60 : 0.90), // Responsive height
      width: double.infinity,
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 16),
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: media.backdrop.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: media.backdrop,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 500),
                    placeholder: (context, url) => Container(color: AppTheme.surfaceContainerHighest),
                    errorWidget: (context, url, error) => Container(color: AppTheme.surfaceContainerHighest),
                  )
                : Container(color: AppTheme.surfaceContainerHighest),
          ),
          // Gradient Overlay exactly matching hero-gradient from design
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppTheme.background,
                    AppTheme.background.withOpacity(0.4),
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
          // Content
          Positioned(
            bottom: 0,
            left: isMobile ? 16 : 58,
            width: MediaQuery.of(context).size.width * (isMobile ? 0.9 : 0.6),
            child: Padding(
              padding: EdgeInsets.only(bottom: isMobile ? 24.0 : 48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'NUEVO LANZAMIENTO',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.primary,
                          letterSpacing: 2,
                        ),
                  ),
                  const SizedBox(height: 4), // Reduced from 16 to 4 to fix "muy arriba"
                  media.logo.isNotEmpty
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: CachedNetworkImage(
                            imageUrl: media.logo,
                            height: 80,
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.contain,
                            fadeInDuration: const Duration(milliseconds: 500),
                            placeholder: (context, url) => const SizedBox(height: 80, width: 100),
                            errorWidget: (context, url, error) => Text(
                              media.title,
                              style: GoogleFonts.sora(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          media.title,
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
                          color: AppTheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          media.type == 'series' ? 'TV-MA' : 'TV-14',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(media.releaseYear, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.onSurfaceVariant)),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(media.rating > 0 ? '${media.rating}' : 'Nuevo', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.amber)),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.outlineVariant),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('4K HDR', style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      TvFocusButton(
                        focusNode: HomeScreen.heroFocusNode,
                        isPrimary: true,
                        onTap: () => _openMediaDetail(media),
                        onFocusChange: (focused) {
                          if (focused && _scrollController.hasClients) {
                            _scrollController.animateTo(
                              0.0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.play_arrow, size: 24),
                            SizedBox(width: 8),
                            Text('Reproducir'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      TvFocusButton(
                        isPrimary: false,
                        onTap: () => _openMediaDetail(media),
                        onFocusChange: (focused) {
                          if (focused && _scrollController.hasClients) {
                            _scrollController.animateTo(
                              0.0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.info_outline, size: 24),
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
          ),
        ],
      ),
    );
  }

  Widget _buildContinueWatchingRail() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return SizedBox(
      height: isMobile ? 180 : 210, // Increased height to allow for vertical padding and scaling
      child: ListView.builder(
        padding: EdgeInsets.only(left: isMobile ? 16.0 : 58.0, right: isMobile ? 16.0 : 58.0, top: 16.0, bottom: 16.0), // Added vertical and right padding
        clipBehavior: Clip.none, // Prevent clipping the scaled border
        scrollDirection: Axis.horizontal,
        itemCount: _continueWatching.length,
        itemBuilder: (context, index) {
          final item = _continueWatching[index];
          final mediaMap = item['media'] as Map<String, dynamic>;
          final media = MediaItem(
            id: mediaMap['id']?.toString() ?? '',
            title: mediaMap['title'] as String? ?? '',
            releaseYear: mediaMap['release_year']?.toString() ?? '',
            releaseDate: mediaMap['release_date'] as String? ?? '',
            thumbnail: mediaMap['thumbnail'] as String? ?? '',
            backdrop: mediaMap['backdrop'] as String? ?? '',
            plot: mediaMap['plot'] as String? ?? '',
            rating: (mediaMap['rating'] as num?)?.toDouble() ?? 0.0,
            type: mediaMap['type'] as String? ?? 'movie',
          );
          final position = item['position'] as int? ?? 0;
          final duration = item['duration'] as int? ?? 1;
          final percent = position / duration;

          return TvFocusCard(
            margin: EdgeInsets.only(right: isMobile ? 12 : 24),
            onTap: () => _openMediaDetail(media),
            child: SizedBox(
              width: isMobile ? 240 : 320,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image
                  media.backdrop.isNotEmpty 
                      ? CachedNetworkImage(
                          imageUrl: media.backdrop,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 500),
                          placeholder: (context, url) => Container(color: AppTheme.surfaceContainerHighest),
                          errorWidget: (context, url, error) => Container(color: AppTheme.surfaceContainerHighest),
                        )
                      : Container(color: AppTheme.surfaceContainerHighest),
                  
                  // Progress bar container
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 4,
                    child: Container(
                      color: AppTheme.surfaceContainerHigh,
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: percent.clamp(0.0, 1.0),
                        child: Container(color: AppTheme.primary),
                      ),
                    ),
                  ),

                  // Overlay gradient on focus/hover (managed via card state or just always show gradient text)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          media.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.containsKey('episode_info'))
                          Text(
                            item['episode_info'] as String,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMovieRail(List<MediaItem> movies) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return SizedBox(
      height: isMobile ? 220 : 280, // Height to accommodate 240 card + 40 focus shadow margin
      child: ListView.builder(
        padding: EdgeInsets.only(left: isMobile ? 16.0 : 58.0, right: isMobile ? 16.0 : 58.0, top: 20.0, bottom: 20.0),
        clipBehavior: Clip.none, // Prevent clipping the shadow/scale
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final media = movies[index];
          return TvFocusCard(
            margin: EdgeInsets.only(right: isMobile ? 12 : 24),
            onTap: () => _openMediaDetail(media),
            child: SizedBox(
              width: isMobile ? 120 : 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  media.thumbnail.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: media.thumbnail,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 500),
                          placeholder: (context, url) => Container(color: AppTheme.surfaceContainerHighest),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.surfaceContainerHighest,
                            child: const Center(child: Icon(Icons.movie, size: 48, color: AppTheme.onSurfaceVariant)),
                          ),
                        )
                      : Container(
                          color: AppTheme.surfaceContainerHighest,
                          child: const Center(child: Icon(Icons.movie, size: 48, color: AppTheme.onSurfaceVariant)),
                        ),
                  // Gradient Overlay for Text Legibility
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.transparent, Colors.black87],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Superimposed Title
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Text(
                      media.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
                            ],
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
