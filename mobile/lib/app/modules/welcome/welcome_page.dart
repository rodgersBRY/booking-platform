import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/staff_auth_repository.dart';
import '../../routes/app_routes.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
    _checkSessionAndRoute();
  }

  Future<void> _checkSessionAndRoute() async {
    final accountType = await Get.find<StorageService>().readAccountType();

    if (accountType == 'staff') {
      final results = await Future.wait<Object?>([
        StaffAuthRepository().fetchMe(),
        Future.delayed(const Duration(milliseconds: 500)),
      ]);
      if (!mounted) return;
      final staff = results[0];
      Get.offAllNamed(staff != null ? AppRoutes.barberShell : AppRoutes.login);
      return;
    }

    await Future.wait<Object?>([
      AuthRepository().fetchMe(),
      Future.delayed(const Duration(milliseconds: 500)),
    ]);
    if (!mounted) return;
    Get.offAllNamed(AppRoutes.shell);
  }

  @override
  Widget build(BuildContext context) => const WelcomeSplashContent();
}

class WelcomeSplashContent extends StatefulWidget {
  const WelcomeSplashContent({super.key});

  @override
  State<WelcomeSplashContent> createState() => _WelcomeSplashContentState();
}

class _WelcomeSplashContentState extends State<WelcomeSplashContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween<double>(
    begin: 0.92,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.6,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder:
                  (context, child) => Opacity(
                    opacity: _opacity.value,
                    child: Transform.scale(scale: _scale.value, child: child),
                  ),
              child: Image.asset(
                'assets/images/logo.png',
                width: 88,
                height: 88,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Baberia Cuts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
