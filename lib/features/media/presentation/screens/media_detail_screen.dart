import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  @override
  Widget build(BuildContext context) {
    final media = widget.mediaItem;
    final isSeries = media.type == 'series';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // 1. Fullscreen Backdrop Image
          Positioned.fill(
            child: media.backdrop.isNotEmpty
                ? Image.network(
                    media.backdrop,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: AppTheme.surfaceContainerHighest),
                  )
                : Container(color: AppTheme.surfaceContainerHighest),
          ),
          
          // Gradients
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppTheme.background,
                    AppTheme.background.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppTheme.background.withValues(alpha: 0.9),
                    AppTheme.background.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 2. Content Container
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 58, right: 58, top: 120, bottom: 58),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metadata
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${media.rating}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 16),
                      Text('•', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                      const SizedBox(width: 16),
                      Text(
                        media.releaseYear,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 16),
                      Text('•', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          media.type == 'series' ? 'SERIE' : 'PELÍCULA',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: Text(
                      media.title,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        shadows: [
                          const Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Plot
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: Text(
                      media.plot.isNotEmpty ? media.plot : 'No hay descripción disponible.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.onSurfaceVariant),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Actions
                  Row(
                    children: [
                      TvFocusButton(
                        isPrimary: true,
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
                          children: const [
                            Icon(Icons.play_arrow, size: 28),
                            SizedBox(width: 8),
                            Text('Reproducir'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      TvFocusButton(
                        isPrimary: false,
                        onTap: () {
                          // Add to list action
                        },
                        child: Row(
                          children: const [
                            Icon(Icons.add, size: 28),
                            SizedBox(width: 8),
                            Text('Añadir a Mi Lista'),
                          ],
                        ),
                      ),
                    ],
                  ),

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
          ),

          // Floating Back Button
          Positioned(
            top: 24,
            left: 24,
            child: TvFocusButton(
              isPrimary: false,
              focusedScale: 1.1,
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back),
            ),
          ),
        ],
      ),
    );
  }
}
