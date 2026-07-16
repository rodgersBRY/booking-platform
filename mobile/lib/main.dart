import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/services/api_service.dart';
import 'app/services/storage_service.dart';
import 'app/services/theme_controller.dart';
import 'app/theme/app_theme.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');

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
      // Seeds GetX's live theme-mode notifier — ThemeController.setMode()
      // updates it afterwards via Get.changeThemeMode().
      themeMode: initialThemeMode,
      initialRoute: AppRoutes.welcome,
      getPages: AppPages.routes,
    );
  }
}
