import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/presentation/widgets/tv_focus_card.dart';
import '../../../../core/presentation/widgets/tv_focus_button.dart';
import '../../data/models/media_item_model.dart';
import 'stream_selector_screen.dart';

class MediaDetailScreen extends StatefulWidget {
  final MediaItem mediaItem;

  const MediaDetailScreen({
    super.key,
    required this.mediaItem,
  });

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends State<MediaDetailScreen> {
  int _selectedSeason = 1;
  int _selectedEpisode = 1;
  String? _logoUrl;
  String? _resolvedImdbId;
  List<String> _detailedCast = [];
  bool _isLoadingLogo = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _logoUrl = widget.mediaItem.logo.isNotEmpty ? widget.mediaItem.logo : null;
    _resolvedImdbId = widget.mediaItem.id.startsWith('tt') ? widget.mediaItem.id : null;
    
    if (_logoUrl == null || _resolvedImdbId == null) {
      _fetchCinemetaDetails();
    }
  }

  Future<void> _fetchCinemetaDetails() async {
    if (_isLoadingLogo) return;
    setState(() {
      _isLoadingLogo = true;
    });

    try {
      final type = widget.mediaItem.type;
      if (widget.mediaItem.id.startsWith('tt')) {
        final url = Uri.parse('https://v3-cinemeta.strem.io/meta/$type/${widget.mediaItem.id}.json');
        final response = await http.get(url).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          if (data is Map && data.containsKey('meta')) {
            final meta = data['meta'];
            if (meta is Map) {
              final logo = meta['logo'] as String?;
              final castRaw = meta['cast'] as List<dynamic>? ?? [];
              final fetchedCast = castRaw.map((e) => e.toString()).toList();
              
              if (mounted) {
                setState(() {
                  _logoUrl = (logo != null && logo.isNotEmpty)
                      ? logo
                      : 'https://images.metahub.space/logo/medium/${widget.mediaItem.id}/img';
                  _resolvedImdbId = widget.mediaItem.id;
                  _detailedCast = fetchedCast;
                });
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching Cinemeta details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLogo = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaItem(
      id: (_resolvedImdbId != null && _resolvedImdbId!.isNotEmpty) ? _resolvedImdbId! : widget.mediaItem.id,
      title: widget.mediaItem.title,
      logo: (_logoUrl != null && _logoUrl!.isNotEmpty) ? _logoUrl! : widget.mediaItem.logo,
      releaseYear: widget.mediaItem.releaseYear,
      releaseDate: widget.mediaItem.releaseDate,
      thumbnail: widget.mediaItem.thumbnail,
      backdrop: widget.mediaItem.backdrop,
      plot: widget.mediaItem.plot,
      rating: widget.mediaItem.rating,
      type: widget.mediaItem.type,
      cast: _detailedCast.isNotEmpty ? _detailedCast : widget.mediaItem.cast,
    );
    final isSeries = media.type == 'series';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Stack(
          children: [
            // Backdrop
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.9,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  media.backdrop.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: media.backdrop,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 500),
                          placeholder: (context, url) => Container(color: AppTheme.surfaceContainerHighest),
                          errorWidget: (context, url, error) => Container(color: AppTheme.surfaceContainerHighest),
                        )
                      : Container(color: AppTheme.surfaceContainerHighest),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          Colors.transparent,
                          AppTheme.background.withValues(alpha: 0.8),
                          AppTheme.background,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.background.withValues(alpha: 0.6),
                          AppTheme.background,
                        ],
                        stops: const [0.4, 0.8, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.only(left: 88.0, top: 80.0, bottom: 48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title or Logo
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.30,
                      maxHeight: 45,
                    ),
                    child: _isLoadingLogo
                        ? const Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                          )
                        : (media.logo.isNotEmpty)
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: CachedNetworkImage(
                                  imageUrl: media.logo,
                                  alignment: Alignment.centerLeft,
                                  fit: BoxFit.contain,
                                  fadeInDuration: const Duration(milliseconds: 500),
                                  placeholder: (context, url) => const SizedBox(height: 45, width: 100),
                                  errorWidget: (context, url, error) => Text(
                                    media.title,
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        const Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                media.title,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    const Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
                                  ],
                                ),
                              ),
                  ),
                  const SizedBox(height: 16),

                  // Metadata
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppTheme.primary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        media.rating > 0 ? '${media.rating}' : 'Nuevo',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 12),
                      Text('•', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                      const SizedBox(width: 12),
                      Text(
                        media.releaseYear,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 12),
                      Text('•', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          media.type == 'series' ? 'SERIE' : 'PELÍCULA',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.onSurface, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Plot
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.55,
                    child: Text(
                      media.plot.isNotEmpty ? media.plot : 'No hay descripción disponible.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 16,
                        height: 1.4,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Actions
                  Row(
                    children: [
                      TvFocusButton(
                        isPrimary: true,
                        onFocusChange: (focused) {
                          if (focused && _scrollController.hasClients) {
                            _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                          }
                        },
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StreamSelectorScreen(
                                mediaItem: media,
                                season: isSeries ? _selectedSeason : null,
                                episode: isSeries ? _selectedEpisode : null,
                              ),
                            ),
                          );
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
                        onFocusChange: (focused) {
                          if (focused && _scrollController.hasClients) {
                            _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                          }
                        },
                        onTap: () {
                          // Add to list action
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add, size: 24),
                            SizedBox(width: 8),
                            Text('Añadir a lista'),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Cast Section
                  if (media.cast.isNotEmpty) ...[
                    const SizedBox(height: 48),
                    Text(
                      'Reparto Principal',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: media.cast.length,
                        itemBuilder: (context, index) {
                          final name = media.cast[index];
                          final parts = name.split(' ');
                          String initials = '';
                          if (parts.isNotEmpty) {
                            if (parts[0].isNotEmpty) initials += parts[0][0];
                            if (parts.length > 1 && parts[1].isNotEmpty) {
                              initials += parts[1][0];
                            }
                          }
                          return SizedBox(
                            width: 96,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16.0, bottom: 10.0, top: 10.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  TvFocusButton(
                                    isPrimary: false,
                                    focusedScale: 1.15,
                                    isCircle: true,
                                    onTap: () {},
                                    child: CircleAvatar(
                                      radius: 34,
                                      backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                                      child: Text(
                                        initials.toUpperCase(),
                                        style: const TextStyle(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.visible,
                                    style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.2),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // Series Selector
                  if (isSeries) ...[
                    const SizedBox(height: 64),
                    Text(
                      'Temporadas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          final seasonNumber = index + 1;
                          final isSelected = _selectedSeason == seasonNumber;
                          return Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: TvFocusButton(
                              isPrimary: isSelected,
                              focusedScale: 1.05,
                              onTap: () {
                                setState(() => _selectedSeason = seasonNumber);
                              },
                              child: Text('T$seasonNumber'),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Episodios',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 15,
                        itemBuilder: (context, index) {
                          final epNumber = index + 1;
                          final isSelected = _selectedEpisode == epNumber;
                          return Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: TvFocusButton(
                              isPrimary: isSelected,
                              focusedScale: 1.05,
                              onTap: () {
                                setState(() => _selectedEpisode = epNumber);
                              },
                              child: Text('Ep $epNumber'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 64),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
