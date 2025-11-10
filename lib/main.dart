import 'package:flutter/material.dart';
import 'src/app/app.dart';
import 'src/core/lifecycle/app_lifecycle_manager.dart';
import 'src/features/cat/service/cat_background_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final backgroundService = CatBackgroundService.instance;
  await backgroundService.configure();
  AppLifecycleManager(backgroundService: backgroundService).attach();

  runApp(const App());
}
