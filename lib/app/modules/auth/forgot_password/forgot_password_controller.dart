import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/api_service.dart';
import '../../../routes/app_pages.dart';

class ForgotPasswordController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final hidePassword = true.obs;
  final hideConfirmPassword = true.obs;
  final isSubmitting = false.obs;

  final ApiService _apiService = ApiService();

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    if (passwordController.text.trim() != confirmPasswordController.text.trim()) {
      Get.snackbar('Password mismatch', 'Password and confirm password must match');
      return;
    }

    try {
      isSubmitting.value = true;
      final response = await _apiService.forgotPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        passwordConfirmation: confirmPasswordController.text.trim(),
      );
      Get.snackbar('Success', response['message']?.toString() ?? 'Password reset successful');
      Get.offAllNamed(AppRoutes.login);
    } catch (error) {
      Get.snackbar('Reset failed', error.toString().replaceFirst('Exception: ', ''));
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
