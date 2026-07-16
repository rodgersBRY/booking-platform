import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'storage_service.dart';

/// Holds the user's appearance preference (system/light/dark) and keeps it
/// in sync with GetX's live theme switching and on-device storage.
/// Registered as a permanent GetxService in main.dart.
class ThemeController extends GetxService {
  final mode = ThemeMode.system.obs;

  Future<ThemeController> init() async {
    mode.value = await Get.find<StorageService>().readThemeMode();
    return this;
  }

  Future<void> setMode(ThemeMode newMode) async {
    mode.value = newMode;
    Get.changeThemeMode(newMode);
    await Get.find<StorageService>().writeThemeMode(newMode);
  }
}
