import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/doctor_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/services/session_service.dart';
import '../../../routes/app_pages.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF5EA), AppColors.surface, AppColors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  DoctorTextField(
                    controller: controller.emailController,
                    label: 'Email',
                    singleLineVerticalPadding: 10,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Email is required';
                      if (!GetUtils.isEmail(value.trim())) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Obx(
                    () => DoctorTextField(
                      controller: controller.passwordController,
                      label: 'Password',
                      obscureText: controller.hidePassword.value,
                      suffixIcon: IconButton(
                        onPressed: () => controller.hidePassword.toggle(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        visualDensity: VisualDensity.compact,
                        splashRadius: 18,
                        icon: Icon(
                          controller.hidePassword.value ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 18,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Password is required';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        final email = controller.emailController.text.trim();
                        if (email.isNotEmpty) {
                          await SessionService.saveLastLoginEmail(email);
                        }
                        Get.toNamed(
                          AppRoutes.forgotPassword,
                          arguments: {'email': email},
                        );
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Obx(
                    () => PrimaryButton(
                      label: 'Sign in',
                      loading: controller.isSubmitting.value,
                      onPressed: controller.login,
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () => Get.toNamed(AppRoutes.register),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      side: const BorderSide(color: AppColors.black, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text(
                      'Register Doctor',
                      style: TextStyle(color: AppColors.black, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
