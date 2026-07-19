import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/password_field.dart';
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
            Center(
              child: Image.asset('assets/images/logo.png', width: 56, height: 56),
            ),
            const SizedBox(height: 20),
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
            PasswordField(
              label: 'Password',
              onChanged: (v) => controller.password.value = v,
            ),
            const SizedBox(height: 16),
            PasswordField(
              label: 'Confirm password',
              onChanged: (v) => controller.confirmPassword.value = v,
            ),
            const SizedBox(height: 24),
            Obx(
              () => ElevatedButton(
                onPressed: controller.submitting.value ? null : controller.submit,
                child: Text(controller.submitting.value ? 'Creating account…' : 'Sign up'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
