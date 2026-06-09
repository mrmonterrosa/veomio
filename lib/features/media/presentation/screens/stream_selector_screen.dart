import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/media_item_model.dart';
import '../../data/models/stream_source_model.dart';
import '../bloc/stream_resolver_cubit.dart';
import '../../../player/presentation/screens/video_player_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class StreamSelectorScreen extends StatefulWidget {
  final MediaItem mediaItem;
  final int? season;
  final int? episode;

  const StreamSelectorScreen({
    super.key,
    required this.mediaItem,
    this.season,
    this.episode,
  });

  @override
  State<StreamSelectorScreen> createState() => _StreamSelectorScreenState();
}

class _StreamSelectorScreenState extends State<StreamSelectorScreen> {
  @override
  void initState() {
    super.initState();
    context.read<StreamResolverCubit>().resolveSources(
      widget.mediaItem,
      season: widget.season,
      episode: widget.episode,
    );
  }

  void _playStream(StreamSource source) {
    context.read<StreamResolverCubit>().resolvePlayableUrl(source);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mediaItem.title;
    final subtitle = widget.season != null && widget.episode != null
        ? 'Temporada ${widget.season} • Episodio ${widget.episode}'
        : widget.mediaItem.releaseYear;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fuentes de Reproducción',
              style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              '$title (${widget.mediaItem.releaseYear})',
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: BlocConsumer<StreamResolverCubit, StreamResolverState>(
        listener: (context, state) {
          if (state is StreamResolveSuccess) {
            // Navigate to Native MPV Video Player Screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(
                  streamUrl: state.directStreamUrl,
                  title: title,
                  subtitle: subtitle,
                ),
              ),
            );
          }
          if (state is StreamResolverError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is StreamResolverLoading || state is StreamResolvingDirect) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    state is StreamResolvingDirect 
                        ? 'Desencriptando y resolviendo stream local...' 
                        : 'Buscando enlaces en servidores locales y complementos...',
                    style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          if (state is StreamResolverLoaded || state is StreamResolveSuccess) {
            // Keep showing loaded list even on success so user doesn't see empty screen when pops
            final sources = state is StreamResolverLoaded 
                ? state.sources 
                : (context.read<StreamResolverCubit>().state as StreamResolverLoaded).sources;

            // Group by source type (Laravel scrapers vs Stremio Addons)
            final localSources = sources.where((s) => s.requiresResolve).toList();
            final addonSources = sources.where((s) => !s.requiresResolve).toList();

            return ListView(
              padding: const EdgeInsets.all(32),
              children: [
                if (localSources.isNotEmpty) ...[
                  _buildHeaderSection('Servidores Locales (Scrapers)'),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      mainAxisExtent: 96,
                    ),
                    itemCount: localSources.length,
                    itemBuilder: (context, index) {
                      final source = localSources[index];
                      return _buildStreamTile(source);
                    },
                  ),
                  const SizedBox(height: 32),
                ],

                if (addonSources.isNotEmpty) ...[
                  _buildHeaderSection('Complementos (Stremio Addons)'),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      mainAxisExtent: 96,
                    ),
                    itemCount: addonSources.length,
                    itemBuilder: (context, index) {
                      final source = addonSources[index];
                      return _buildStreamTile(source);
                    },
                  ),
                ],
              ],
            );
          }

          if (state is StreamResolverError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sentiment_dissatisfied_outlined, color: AppTheme.onSurfaceVariant, size: 80),
                  const SizedBox(height: 24),
                  Text(
                    state.message,
                    style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<StreamResolverCubit>().resolveSources(
                        widget.mediaItem,
                        season: widget.season,
                        episode: widget.episode,
                      );
                    },
                    child: const Text('Reintentar Búsqueda'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeaderSection(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.sora(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStreamTile(StreamSource source) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _playStream(source),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon Indicator
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: source.requiresResolve
                      ? AppTheme.secondary.withValues(alpha: 0.1)
                      : AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: source.requiresResolve
                        ? AppTheme.secondary.withValues(alpha: 0.3)
                        : AppTheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  source.requiresResolve ? Icons.vpn_lock : Icons.bolt,
                  color: source.requiresResolve ? AppTheme.secondary : AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Text Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      source.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      source.description ?? source.sourceName,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Play Icon
              const Icon(
                Icons.play_circle_outline,
                color: AppTheme.onSurfaceVariant,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
