import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.content_cut, size: 48, color: AppColors.brass),
              const SizedBox(height: 12),
              Text(
                'Baberia Cuts',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Book your next appointment in under a minute.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Get.offAllNamed(AppRoutes.shell),
                child: const Text('Continue as guest'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Get.toNamed(AppRoutes.login),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
