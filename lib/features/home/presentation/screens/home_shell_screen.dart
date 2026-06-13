import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late List<FocusNode> _sidebarNodes;
  late FocusNode _mainContentFocusNode;

  @override
  void initState() {
    super.initState();
    _mainContentFocusNode = FocusNode();
    _sidebarNodes = List.generate(5, (_) => FocusNode());
    for (int i = 0; i < _sidebarNodes.length; i++) {
      _sidebarNodes[i].onKeyEvent = (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown && i < _sidebarNodes.length - 1) {
            _sidebarNodes[i + 1].requestFocus();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp && i > 0) {
            _sidebarNodes[i - 1].requestFocus();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            if (_activeTab == 0) {
              HomeScreen.heroFocusNode.requestFocus();
            } else if (_activeTab == 1) {
              LiveTvScreen.playButtonNode.requestFocus();
            } else if (_activeTab == 3) {
              AddonsScreen.addAddonFocusNode.requestFocus();
            } else if (_activeTab == 4) {
              SettingsScreen.firstFocusNode.requestFocus();
            } else {
              _mainContentFocusNode.requestFocus();
            }
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      };
    }

    HomeScreen.heroFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (!_sidebarExpanded) {
          _sidebarNodes[_activeTab].requestFocus();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };

    LiveTvScreen.playButtonNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (!_sidebarExpanded) {
          _sidebarNodes[_activeTab].requestFocus();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };

    AddonsScreen.addAddonFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (!_sidebarExpanded) {
          _sidebarNodes[_activeTab].requestFocus();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };

    SettingsScreen.firstFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          if (!_sidebarExpanded) {
            _sidebarNodes[_activeTab].requestFocus();
            return KeyEventResult.handled;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          SettingsScreen.mediaKitFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };

    SettingsScreen.mediaKitFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        SettingsScreen.firstFocusNode.requestFocus();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  void dispose() {
    _mainContentFocusNode.dispose();
    for (var node in _sidebarNodes) {
      node.dispose();
    }
    super.dispose();
  }

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

  Widget _buildMobileLayout(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: SafeArea(
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
                context.read<CatalogCubit>().loadCatalog();
                context.read<LiveTvCubit>().loadChannels();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _activeTab,
        onTap: (index) {
          setState(() => _activeTab = index);
          if (index == 0) {
            context.read<CatalogCubit>().loadCatalog();
          } else if (index == 1) {
            context.read<LiveTvCubit>().loadChannels();
          } else if (index == 3) {
            context.read<AddonsCubit>().loadAddons();
          }
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.onSurfaceVariant,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.normal, fontSize: 11),
        type: BottomNavigationBarType.fixed,
        items: List.generate(_tabTitles.length, (index) {
          return BottomNavigationBarItem(
            icon: Icon(_tabIcons[index]),
            label: _tabTitles[index],
          );
        }),
      ),
    );
  }

  Widget _buildTvLayout(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          left: 88, // Reserve space for collapsed sidebar
          child: FocusTraversalGroup(
            child: Focus(
              focusNode: _mainContentFocusNode,
              child: Container(
                color: AppTheme.background,
                child: IndexedStack(
                  index: _activeTab,
                  children: [
                    ExcludeFocus(
                      excluding: _activeTab != 0,
                      child: HomeScreen(localStorage: widget.localStorage),
                    ),
                    ExcludeFocus(
                      excluding: _activeTab != 1,
                      child: const LiveTvScreen(),
                    ),
                    ExcludeFocus(
                      excluding: _activeTab != 2,
                      child: const SearchScreen(),
                    ),
                    ExcludeFocus(
                      excluding: _activeTab != 3,
                      child: const AddonsScreen(),
                    ),
                    ExcludeFocus(
                      excluding: _activeTab != 4,
                      child: SettingsScreen(
                        localStorage: widget.localStorage,
                        onSettingsSaved: () {
                          context.read<CatalogCubit>().loadCatalog();
                          context.read<LiveTvCubit>().loadChannels();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Dimming overlay when sidebar is expanded
        if (_sidebarExpanded)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _sidebarExpanded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black87,
                        Colors.black54,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // 1. Collapsible Sidebar Navigation
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: FocusTraversalGroup(
            child: MouseRegion(
              onEnter: (_) => setState(() => _sidebarExpanded = true),
              onExit: (_) => setState(() => _sidebarExpanded = false),
              child: Focus(
                onFocusChange: (focused) {
                  if (focused && !_sidebarExpanded) {
                    _sidebarNodes[_activeTab].requestFocus();
                  }
                  setState(() => _sidebarExpanded = focused);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _sidebarExpanded ? 260 : 88,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: _sidebarExpanded 
                        ? [
                            AppTheme.background.withValues(alpha: 0.98),
                            Colors.transparent,
                          ]
                        : [
                            AppTheme.surfaceContainerLow,
                            AppTheme.surfaceContainerLow,
                          ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 36),
                      
                      // Logo Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _sidebarExpanded 
                          ? Image.asset(
                              'assets/images/banner_menu.png',
                              height: 60,
                              fit: BoxFit.contain,
                              alignment: Alignment.centerLeft,
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/images/logo_menu.png',
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                            ),
                      ),
                      const SizedBox(height: 40),

                      // Navigation Buttons
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...List.generate(_tabTitles.length - 1, (index) {
                                final isSelected = _activeTab == index;
                                return _SidebarNavItem(
                                  key: ValueKey('sidebar_item_$index'),
                                  icon: _tabIcons[index],
                                  title: _tabTitles[index],
                                  isSelected: isSelected,
                                  sidebarExpanded: _sidebarExpanded,
                                  focusNode: _sidebarNodes[index],
                                  onTap: () {
                                    setState(() => _activeTab = index);
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
                              const Spacer(),
                              Builder(
                                builder: (context) {
                                  final index = _tabTitles.length - 1;
                                  final isSelected = _activeTab == index;
                                  return _SidebarNavItem(
                                    key: ValueKey('sidebar_item_$index'),
                                    icon: _tabIcons[index],
                                    title: _tabTitles[index],
                                    isSelected: isSelected,
                                    sidebarExpanded: _sidebarExpanded,
                                    focusNode: _sidebarNodes[index],
                                    onTap: () {
                                      setState(() => _activeTab = index);
                                    },
                                  );
                                }
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CatalogCubit(widget.apiClient)),
        BlocProvider(create: (_) => LiveTvCubit(widget.apiClient, widget.localStorage)),
        BlocProvider(create: (_) => SearchCubit(widget.apiClient, widget.localStorage)),
        BlocProvider(create: (_) => AddonsCubit(widget.apiClient, widget.localStorage)..loadAddons()),
        BlocProvider(create: (_) => StreamResolverCubit(widget.apiClient, widget.localStorage)),
      ],
      child: PopScope(
        canPop: isMobile ? (_activeTab == 0) : (!_sidebarExpanded && _activeTab == 0),
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          
          if (!isMobile && _sidebarExpanded) {
            setState(() => _sidebarExpanded = false);
            _mainContentFocusNode.requestFocus();
          } else if (_activeTab != 0) {
            setState(() => _activeTab = 0);
          }
        },
        child: Scaffold(
          body: isMobile ? _buildMobileLayout(context) : _buildTvLayout(context),
          bottomNavigationBar: isMobile ? _buildBottomNavigationBar(context) : null,
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
  final FocusNode focusNode;
  final VoidCallback onTap;

  const _SidebarNavItem({
    super.key,
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.sidebarExpanded,
    required this.focusNode,
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
      child: FocusableActionDetector(
        focusNode: widget.focusNode,
        onFocusChange: (focused) {
          setState(() {
            _isFocused = focused;
          });
        },
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
            margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: border,
            ),
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
