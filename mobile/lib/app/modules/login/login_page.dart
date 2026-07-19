import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../widgets/password_field.dart';
import 'login_controller.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Image.asset('assets/images/logo.png', width: 56, height: 56),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              onChanged: (v) => controller.email.value = v,
            ),
            const SizedBox(height: 16),
            PasswordField(
              label: 'Password',
              onChanged: (v) => controller.password.value = v,
            ),
            const SizedBox(height: 24),
            Obx(
              () => ElevatedButton(
                onPressed: controller.submitting.value ? null : controller.submit,
                child: Text(controller.submitting.value ? 'Signing in…' : 'Sign in'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Get.toNamed(AppRoutes.signup),
              child: const Text('No account yet? Sign up'),
            ),
          ],
        ),
      ),
    );
  }
}
