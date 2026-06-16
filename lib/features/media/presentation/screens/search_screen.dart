import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/presentation/widgets/tv_focus_card.dart';
import '../../data/models/media_item_model.dart';
import '../bloc/search_cubit.dart';
import 'media_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final FocusNode _firstResultFocusNode = FocusNode();
  bool _shouldFocusFirstResult = false;

  final List<List<String>> _keyboardRows = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'BACK'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M', 'SPACE', 'SEARCH']
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _firstResultFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      context.read<SearchCubit>().clearSearch();
    } else {
      context.read<SearchCubit>().search(query);
    }
  }

  void _onKeyPress(String key) {
    if (key == 'BACK') {
      if (_searchController.text.isNotEmpty) {
        _searchController.text = _searchController.text.substring(0, _searchController.text.length - 1);
        _onSearchChanged(_searchController.text);
      }
    } else if (key == 'SPACE') {
      _searchController.text += ' ';
      _onSearchChanged(_searchController.text);
    } else if (key == 'SEARCH') {
      _shouldFocusFirstResult = true;
      _onSearchChanged(_searchController.text);
    } else {
      _searchController.text += key;
      _onSearchChanged(_searchController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 36, bottom: 36, right: 58, left: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Panel: Input & Keyboard
          SizedBox(
            width: 400, // Fixed width for keyboard panel
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Búsqueda',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 24),
                // Custom Search Input Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.surfaceContainer),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppTheme.onSurfaceVariant),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _searchController.text.isEmpty ? 'Películas, series...' : _searchController.text,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: _searchController.text.isEmpty ? AppTheme.onSurfaceVariant.withValues(alpha: 0.5) : AppTheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // On-screen Keyboard Grid
                _buildKeyboard(),
                
                const SizedBox(height: 24),
                Text(
                  'Búsquedas recientes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      _buildRecentSearchItem('El Padrino'),
                      _buildRecentSearchItem('Sci-Fi'),
                      _buildRecentSearchItem('Cyberpunk'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 48),
          
          // Right Panel: Results Grid
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BlocBuilder<SearchCubit, SearchState>(
                  builder: (context, state) {
                    String title = 'Resultados';
                    if (state is SearchLoaded) {
                      title = 'Resultados para "${state.query}"';
                    }
                    return Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    );
                  },
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: BlocConsumer<SearchCubit, SearchState>(
                    listener: (context, state) {
                      if (state is SearchLoaded && _shouldFocusFirstResult) {
                        _shouldFocusFirstResult = false;
                        if (state.results.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _firstResultFocusNode.requestFocus();
                          });
                        }
                      }
                    },
                    builder: (context, state) {
                      if (state is SearchLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                          ),
                        );
                      }

                      if (state is SearchError) {
                        return Center(
                          child: Text(state.message, style: const TextStyle(color: Colors.redAccent)),
                        );
                      }

                      if (state is SearchLoaded) {
                        final results = state.results;
                        if (results.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.sentiment_dissatisfied, color: AppTheme.onSurfaceVariant, size: 64),
                                const SizedBox(height: 16),
                                Text(
                                  'No se encontraron resultados.',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          );
                        }

                        final isMobile = MediaQuery.of(context).size.width < 600;
                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: isMobile ? 120 : 200,
                            mainAxisSpacing: isMobile ? 16 : 32,
                            crossAxisSpacing: isMobile ? 16 : 32,
                            childAspectRatio: 2 / 3,
                          ),
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final item = results[index];
                            return _buildResultCard(context, item, index == 0 ? _firstResultFocusNode : null);
                          },
                        );
                      }

                      // Initial State
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search, color: AppTheme.outline, size: 80),
                            const SizedBox(height: 16),
                            Text(
                              'Usa el teclado para buscar',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.onSurfaceVariant),
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
        ],
      ),
    );
  }

  Widget _buildKeyboard() {
    return Column(
      children: _keyboardRows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: row.map((key) {
              int flex = 1;
              if (key == 'SPACE') flex = 4;
              if (key == 'SEARCH' || key == 'BACK') flex = 2;
              
              return Expanded(
                flex: flex,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: _TvKeyboardKey(
                    label: key,
                    onTap: () => _onKeyPress(key),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentSearchItem(String query) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _searchController.text = query;
            _onSearchChanged(query);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.history, color: AppTheme.onSurfaceVariant, size: 20),
                const SizedBox(width: 16),
                Text(query, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, MediaItem media, FocusNode? focusNode) {
    return TvFocusCard(
      focusNode: focusNode,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MediaDetailScreen(mediaItem: media),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: AppTheme.surfaceContainerHighest,
              child: media.thumbnail.isNotEmpty
                  ? Image.network(
                      media.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.movie, size: 40)),
                    )
                  : const Center(child: Icon(Icons.movie, size: 40, color: AppTheme.onSurfaceVariant)),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppTheme.surfaceContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  media.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      media.releaseYear.isNotEmpty ? media.releaseYear : '-',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                    Text(
                      media.type == 'series' ? 'SERIE' : 'CINE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TvKeyboardKey extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _TvKeyboardKey({required this.label, required this.onTap});

  @override
  State<_TvKeyboardKey> createState() => _TvKeyboardKeyState();
}

class _TvKeyboardKeyState extends State<_TvKeyboardKey> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSpecial = widget.label == 'BACK' || widget.label == 'SEARCH' || widget.label == 'SPACE';
    final isSearch = widget.label == 'SEARCH';
    
    Color baseColor = AppTheme.surfaceContainer;
    if (isSearch) baseColor = AppTheme.primary.withValues(alpha: 0.2);
    if (widget.label == 'BACK') baseColor = AppTheme.surfaceContainerHighest;

    return FocusableActionDetector(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          transform: Matrix4.identity()..scale(_isFocused ? 1.1 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isFocused ? Colors.white : baseColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isFocused ? Colors.white : Colors.transparent,
              width: 2,
            ),
            boxShadow: _isFocused ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              )
            ] : [],
          ),
          alignment: Alignment.center,
          child: _buildKeyContent(isSearch),
        ),
      ),
    );
  }

  Widget _buildKeyContent(bool isSearch) {
    if (widget.label == 'BACK') {
      return Icon(Icons.backspace, size: 20, color: _isFocused ? AppTheme.onPrimary : AppTheme.onSurface);
    }
    if (widget.label == 'SEARCH') {
      return Icon(Icons.search, size: 20, color: _isFocused ? AppTheme.onPrimary : AppTheme.primary);
    }
    if (widget.label == 'SPACE') {
      return Text('Espacio', style: TextStyle(color: _isFocused ? AppTheme.onPrimary : AppTheme.onSurface, fontWeight: FontWeight.bold));
    }
    return Text(
      widget.label,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _isFocused ? AppTheme.onPrimary : AppTheme.onSurface,
      ),
    );
  }
}
