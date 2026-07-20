import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';

import 'package:firebase_core/firebase_core.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/services/api_service.dart';
import 'app/services/storage_service.dart';
import 'app/services/theme_controller.dart';
import 'app/theme/app_theme.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Get.putAsync(() => StorageService().init());
  await Get.putAsync(() => ApiService().init());
  final themeController = await Get.putAsync(() => ThemeController().init());

  runApp(BarberiaCutsApp(initialThemeMode: themeController.mode.value));
}

class BarberiaCutsApp extends StatelessWidget {
  final ThemeMode initialThemeMode;

  const BarberiaCutsApp({super.key, required this.initialThemeMode});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Baberia Cuts',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: initialThemeMode,
      initialRoute: AppRoutes.welcome,
      getPages: AppPages.routes,
    );
  }
}
