import 'package:flutter/material.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/presentation/widgets/tv_focus_button.dart';

class SettingsScreen extends StatefulWidget {
  final LocalStorage localStorage;
  final VoidCallback onSettingsSaved;
  
  static final FocusNode firstFocusNode = FocusNode();
  static final FocusNode mediaKitFocusNode = FocusNode();

  const SettingsScreen({
    super.key,
    required this.localStorage,
    required this.onSettingsSaved,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _playerType;

  @override
  void initState() {
    super.initState();
    _playerType = widget.localStorage.getPlayerType();
  }

  Future<void> _setPlayerType(String type) async {
    setState(() {
      _playerType = type;
    });
    await widget.localStorage.setPlayerType(type);
    widget.onSettingsSaved();
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada automáticamente.'),
          backgroundColor: AppTheme.primary,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuración',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Ajustes del motor de reproducción',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 40),

            // Player Selector Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tipo de Reproductor',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selecciona el motor de reproducción principal para películas, series y canales.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        TvFocusButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          focusNode: SettingsScreen.firstFocusNode,
                          isPrimary: _playerType == 'native',
                          onTap: () => _setPlayerType('native'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_circle_outline,
                                color: _playerType == 'native' ? Colors.black : Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Nativo',
                                style: TextStyle(
                                  color: _playerType == 'native' ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        TvFocusButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          focusNode: SettingsScreen.mediaKitFocusNode,
                          isPrimary: _playerType == 'mediakit',
                          onTap: () => _setPlayerType('mediakit'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.high_quality,
                                color: _playerType == 'mediakit' ? Colors.black : Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'MediaKit',
                                style: TextStyle(
                                  color: _playerType == 'mediakit' ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Info Card
            Card(
              color: AppTheme.surfaceLow,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.primary, size: 36),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detalles del Entorno',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Veomio MVP v1.0.0 • Motor de Reproducción Activo: ${_playerType == 'mediakit' ? 'MediaKit' : 'Nativo'}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
