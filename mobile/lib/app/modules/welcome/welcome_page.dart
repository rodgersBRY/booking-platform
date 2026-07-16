import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/repositories/auth_repository.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

/// Splash screen — checks for a valid stored session, then always lands in
/// the shell. The shell's tabs already handle guest vs signed-in state on
/// their own (sign-in prompts on Appointments/Profile, greeting on Home),
/// so there's nothing else to branch on here.
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
    // Keep the splash on screen briefly even when the session check is
    // instant, so it reads as an intentional splash rather than a flash.
    await Future.wait([
      AuthRepository().fetchMe(),
      Future.delayed(const Duration(milliseconds: 500)),
    ]);
    if (!mounted) return;
    Get.offAllNamed(AppRoutes.shell);
  }

  @override
  Widget build(BuildContext context) => const WelcomeSplashContent();
}

/// The splash's static visuals, kept separate from [WelcomePage] so they
/// can be rendered/tested without triggering the session check or the
/// navigation timer.
class WelcomeSplashContent extends StatelessWidget {
  const WelcomeSplashContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', width: 88, height: 88),
            const SizedBox(height: 12),
            const Text(
              'Baberia Cuts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
