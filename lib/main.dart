import 'package:flutter/material.dart';
import 'core/network/api_client.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/screens/home_shell_screen.dart';

import 'package:media_kit/media_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  
  // Initialize Local Storage & API client
  final localStorage = await LocalStorage.init();
  final apiClient = ApiClient(localStorage);

  runApp(VeomioApp(
    localStorage: localStorage,
    apiClient: apiClient,
  ));
}

class VeomioApp extends StatelessWidget {
  final LocalStorage localStorage;
  final ApiClient apiClient;

  const VeomioApp({
    super.key,
    required this.localStorage,
    required this.apiClient,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veomio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: HomeShellScreen(
        localStorage: localStorage,
        apiClient: apiClient,
      ),
    );
  }
}
