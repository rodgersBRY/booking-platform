import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/services/api_service.dart';
import 'app/services/storage_service.dart';
import 'app/theme/app_theme.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');

  await Get.putAsync(() => StorageService().init());
  await Get.putAsync(() => ApiService().init());

  runApp(const BarberiaCutsApp());
}

class BarberiaCutsApp extends StatelessWidget {
  const BarberiaCutsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Baberia Cuts',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.welcome,
      getPages: AppPages.routes,
    );
  }
}
