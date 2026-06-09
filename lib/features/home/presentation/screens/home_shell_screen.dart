import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/app_theme.dart';

// Import features cubits
import '../../../addons/presentation/bloc/addons_cubit.dart';
import '../../../media/presentation/bloc/catalog_cubit.dart';
import '../../../media/presentation/bloc/search_cubit.dart';
import '../../../media/presentation/bloc/stream_resolver_cubit.dart';
import '../../../live_tv/presentation/bloc/live_tv_cubit.dart';

// Import screens
import '../../../media/presentation/screens/home_screen.dart';
import '../../../live_tv/presentation/screens/live_tv_screen.dart';
import '../../../media/presentation/screens/search_screen.dart';
import '../../../addons/presentation/screens/addons_screen.dart';
import 'settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeShellScreen extends StatefulWidget {
  final LocalStorage localStorage;
  final ApiClient apiClient;

  const HomeShellScreen({
    super.key,
    required this.localStorage,
    required this.apiClient,
  });

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _activeTab = 0;
  bool _sidebarExpanded = false;

  final List<String> _tabTitles = [
    'Inicio',
    'TV en Vivo',
    'Búsqueda',
    'Complementos',
    'Configuración',
  ];

  final List<IconData> _tabIcons = [
    Icons.home_filled,
    Icons.live_tv,
    Icons.search,
    Icons.extension,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CatalogCubit(widget.apiClient)),
        BlocProvider(create: (_) => LiveTvCubit(widget.apiClient)),
        BlocProvider(create: (_) => SearchCubit(widget.apiClient, widget.localStorage)),
        BlocProvider(create: (_) => AddonsCubit(widget.apiClient, widget.localStorage)..loadAddons()),
        BlocProvider(create: (_) => StreamResolverCubit(widget.apiClient, widget.localStorage)),
      ],
      child: Scaffold(
        body: Builder(
          builder: (context) {
            return Row(
              children: [
                // 1. Collapsible Sidebar Navigation
                FocusTraversalGroup(
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _sidebarExpanded = true),
                    onExit: (_) => setState(() => _sidebarExpanded = false),
                    child: Focus(
                      onFocusChange: (focused) {
                        setState(() => _sidebarExpanded = focused);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _sidebarExpanded ? 260 : 88,
                        color: AppTheme.surfaceContainerLow,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 36),
                            
                            // Logo Section
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.play_circle_fill,
                                    color: AppTheme.primary,
                                    size: 40,
                                  ),
                                  if (_sidebarExpanded) ...[
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Veomio',
                                            style: GoogleFonts.sora(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                          Text(
                                            'Premium Media Hub',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: AppTheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Navigation Buttons
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: List.generate(_tabTitles.length, (index) {
                                  final isSelected = _activeTab == index;
                                  return _SidebarNavItem(
                                    icon: _tabIcons[index],
                                    title: _tabTitles[index],
                                    isSelected: isSelected,
                                    sidebarExpanded: _sidebarExpanded,
                                    onTap: () {
                                      setState(() => _activeTab = index);
                                      // Auto-trigger loads depending on tab selection
                                      if (index == 0) {
                                        context.read<CatalogCubit>().loadCatalog();
                                      } else if (index == 1) {
                                        context.read<LiveTvCubit>().loadChannels();
                                      } else if (index == 3) {
                                        context.read<AddonsCubit>().loadAddons();
                                      }
                                    },
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Main Content View Area (switches based on activeTab)
                Expanded(
                  child: FocusTraversalGroup(
                    child: Container(
                      color: AppTheme.background,
                      child: IndexedStack(
                        index: _activeTab,
                        children: [
                          HomeScreen(localStorage: widget.localStorage),
                          const LiveTvScreen(),
                          const SearchScreen(),
                          const AddonsScreen(),
                          SettingsScreen(
                            localStorage: widget.localStorage,
                            onSettingsSaved: () {
                              // Reload Laravel API client data after settings change
                              context.read<CatalogCubit>().loadCatalog();
                              context.read<LiveTvCubit>().loadChannels();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final bool sidebarExpanded;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.sidebarExpanded,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = _isFocused || _isHovered;
    
    Color backgroundColor = Colors.transparent;
    if (widget.isSelected) {
      backgroundColor = isHighlighted 
          ? AppTheme.primary.withValues(alpha: 0.25)
          : AppTheme.primary.withValues(alpha: 0.15);
    } else if (isHighlighted) {
      backgroundColor = Colors.white.withValues(alpha: 0.08);
    }

    Border border;
    if (isHighlighted) {
      border = Border.all(color: AppTheme.secondary, width: 2.0);
    } else if (widget.isSelected) {
      border = Border.all(color: AppTheme.primary, width: 2.0);
    } else {
      border = Border.all(color: Colors.transparent, width: 2.0);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Focus(
        onFocusChange: (focused) {
          setState(() {
            _isFocused = focused;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: border,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: widget.onTap,
            canRequestFocus: false, // Let the parent Focus widget manage the D-pad focus
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    color: widget.isSelected
                        ? AppTheme.primary
                        : (isHighlighted ? Colors.white : AppTheme.onSurfaceVariant),
                    size: 26,
                  ),
                  if (widget.sidebarExpanded) ...[
                    const SizedBox(width: 16),
                    Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: (widget.isSelected || isHighlighted) ? FontWeight.bold : FontWeight.normal,
                        color: (widget.isSelected || isHighlighted) ? Colors.white : AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
