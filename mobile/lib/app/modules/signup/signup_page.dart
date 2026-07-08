import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/app_colors.dart';
import 'signup_controller.dart';

class SignupPage extends GetView<SignupController> {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Full name'),
              onChanged: (v) => controller.name.value = v,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Phone number',
                helperText: "Used the same phone before? We'll link your history.",
              ),
              keyboardType: TextInputType.phone,
              onChanged: (v) => controller.phone.value = v,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              onChanged: (v) => controller.email.value = v,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              onChanged: (v) => controller.password.value = v,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Confirm password'),
              obscureText: true,
              onChanged: (v) => controller.confirmPassword.value = v,
            ),
            const SizedBox(height: 24),
            Obx(
              () => ElevatedButton(
                onPressed: controller.submitting.value ? null : controller.submit,
                child: Text(controller.submitting.value ? 'Creating account…' : 'Sign up'),
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final error = controller.errorMessage.value;
              if (error == null) return const SizedBox.shrink();
              return Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.late, fontSize: 13),
              );
            }),
            Obx(() {
              final success = controller.successMessage.value;
              if (success == null) return const SizedBox.shrink();
              return Text(
                success,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.free, fontSize: 13),
              );
            }),
          ],
        ),
      ),
    );
  }
}
