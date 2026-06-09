import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/addons_cubit.dart';
import '../../data/models/addon_manifest_model.dart';
import 'package:google_fonts/google_fonts.dart';

class AddonsScreen extends StatefulWidget {
  const AddonsScreen({super.key});

  @override
  State<AddonsScreen> createState() => _AddonsScreenState();
}

class _AddonsScreenState extends State<AddonsScreen> {
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _showInstallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.outline),
          ),
          title: Text(
            'Instalar Complemento Stremio',
            style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ingresa la URL del archivo manifest.json del addon compatible con Stremio (ej: Torrentio, Cinemeta, etc.)',
                  style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant, fontSize: 14),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _urlController,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'URL del Manifiesto',
                    hintText: 'https://addon.com/manifest.json',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.outline),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa una URL.';
                    }
                    if (!value.startsWith('http://') && !value.startsWith('https://') && !value.startsWith('stremio://')) {
                      return 'La URL debe ser válida.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _urlController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final url = _urlController.text.trim();
                  context.read<AddonsCubit>().installAddon(url);
                  _urlController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text('Instalar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complementos (Addons)',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Instala y gestiona addons compatibles con el protocolo de Stremio',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showInstallDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Agregar Addon'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Addons List View
          Expanded(
            child: BlocBuilder<AddonsCubit, AddonsState>(
              builder: (context, state) {
                if (state is AddonsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  );
                }

                if (state is AddonsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                        const SizedBox(height: 16),
                        Text(state.message, style: const TextStyle(color: Colors.redAccent)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context.read<AddonsCubit>().loadAddons(),
                          child: const Text('Reintentar'),
                        )
                      ],
                    ),
                  );
                }

                if (state is AddonsLoaded) {
                  final addons = state.addons;
                  if (addons.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.extension_off_outlined, color: AppTheme.outline, size: 80),
                          const SizedBox(height: 24),
                          Text(
                            'No hay complementos instalados',
                            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Agrega tus propios repositorios de streaming o catálogos',
                            style: GoogleFonts.inter(color: AppTheme.outline),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: addons.length,
                    itemBuilder: (context, index) {
                      final addon = addons[index];
                      return _buildAddonCard(context, addon);
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddonCard(BuildContext context, StremioAddon addon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Addon Logo / Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outline),
              ),
              child: addon.logo != null && addon.logo!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(addon.logo!, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.extension, color: AppTheme.secondary, size: 32),
            ),
            const SizedBox(width: 24),

            // Addon Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        addon.name,
                        style: GoogleFonts.sora(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLow,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.outline),
                        ),
                        child: Text(
                          'v${addon.version}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    addon.description ?? 'Sin descripción disponible.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Addon Resource Capabilities Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var resource in addon.resources)
                        _buildCapabilityTag(resource, AppTheme.primary),
                      for (var type in addon.types)
                        _buildCapabilityTag(type, AppTheme.secondary),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(width: 24),

            // Uninstall Action Button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    backgroundColor: AppTheme.surface,
                    title: const Text('¿Desinstalar complemento?'),
                    content: Text('¿Estás seguro de que deseas eliminar "${addon.name}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text('Cancelar', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: () {
                          context.read<AddonsCubit>().uninstallAddon(addon.manifestUrl);
                          Navigator.pop(dialogCtx);
                        },
                        child: const Text('Desinstalar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}


