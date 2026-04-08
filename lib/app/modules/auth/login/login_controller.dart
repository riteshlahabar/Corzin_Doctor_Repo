import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/doctor_profile.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/session_service.dart';
import '../../../routes/app_pages.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final isSubmitting = false.obs;
  final hidePassword = true.obs;
  final ApiService _apiService = ApiService();

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isSubmitting.value = true;
      final response = await _apiService.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final profile = DoctorProfile.fromJson(response['data'] as Map<String, dynamic>);
      await SessionService.saveProfile(profile);
      Get.offAllNamed(AppRoutes.home);
      Get.snackbar('Success', response['message']?.toString() ?? 'Signed in successfully');
    } catch (error) {
      Get.snackbar('Login failed', error.toString().replaceFirst('Exception: ', ''));
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
