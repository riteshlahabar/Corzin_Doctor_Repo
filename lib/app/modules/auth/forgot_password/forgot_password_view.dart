import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/doctor_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import 'forgot_password_controller.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Forgot Password',
          style: TextStyle(fontFamily: 'SF Pro Display', fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Form(
            key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                const SizedBox(height: 4),
                DoctorTextField(
                  controller: controller.emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Email is required';
                    if (!GetUtils.isEmail(value.trim())) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Obx(
                  () => DoctorTextField(
                    controller: controller.passwordController,
                    label: 'New Password',
                    obscureText: controller.hidePassword.value,
                    suffixIcon: IconButton(
                      onPressed: () => controller.hidePassword.toggle(),
                      icon: Icon(
                        controller.hidePassword.value ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'New Password is required';
                      if (value.trim().length < 8) return 'Password must be at least 8 characters';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Obx(
                  () => DoctorTextField(
                    controller: controller.confirmPasswordController,
                    label: 'Confirm Password',
                    obscureText: controller.hideConfirmPassword.value,
                    suffixIcon: IconButton(
                      onPressed: () => controller.hideConfirmPassword.toggle(),
                      icon: Icon(
                        controller.hideConfirmPassword.value ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Confirm Password is required';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Obx(
                  () => PrimaryButton(
                    label: 'Reset Password',
                    loading: controller.isSubmitting.value,
                    onPressed: controller.submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
