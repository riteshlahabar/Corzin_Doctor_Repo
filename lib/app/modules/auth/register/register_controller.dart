import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/api_service.dart';
import '../../../routes/app_pages.dart';

class RegisterController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final isSubmitting = false.obs;
  final agreeTerms = false.obs;
  final termsText = 'Terms content is managed from backend and accepted during registration.'.obs;

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final clinicNameController = TextEditingController();
  final degreeController = TextEditingController();
  final contactController = TextEditingController();
  final emailController = TextEditingController();
  final adharController = TextEditingController();
  final panController = TextEditingController();
  final mmcController = TextEditingController();
  final clinicRegController = TextEditingController();
  final clinicAddressController = TextEditingController();
  final villageController = TextEditingController();
  final cityController = TextEditingController();
  final talukaController = TextEditingController();
  final districtController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();
  final passwordController = TextEditingController();
  final repeatPasswordController = TextEditingController();

  final files = <String, PlatformFile?>{
    'adhar_document_front': null,
    'adhar_document_back': null,
    'pan_document': null,
    'mmc_document': null,
    'clinic_registration_document': null,
    'doctor_photo': null,
  }.obs;

  final ApiService _apiService = ApiService();

  @override
  void onInit() {
    super.onInit();
    stateController.text = 'Maharashtra';
    _loadSettings();
  }

  @override
  void onReady() {
    super.onReady();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _apiService.fetchDoctorSettings();
      if (settings.termsAndConditions.trim().isNotEmpty) {
        termsText.value = settings.termsAndConditions.trim();
      }
    } catch (_) {}
  }

  Future<void> pickFile(String key, {bool imageOnly = false}) async {
    final result = await FilePicker.platform.pickFiles(
      type: imageOnly ? FileType.image : FileType.custom,
      allowedExtensions: imageOnly ? null : ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      files[key] = result.files.single;
      files.refresh();
    }
  }

  String? requiredValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  Future<void> registerDoctor() async {
    if (!formKey.currentState!.validate()) return;
    if (!agreeTerms.value) {
      Get.snackbar('Terms required', 'Please accept terms and conditions');
      return;
    }

    final hasMissingFile = files.values.any((file) => file == null);
    if (hasMissingFile) {
      Get.snackbar('Documents required', 'Please upload all required documents');
      return;
    }

    if (passwordController.text != repeatPasswordController.text) {
      Get.snackbar('Password mismatch', 'Password and repeat password must match');
      return;
    }

    try {
      isSubmitting.value = true;
      final response = await _apiService.register(
        fields: {
          'first_name': firstNameController.text.trim(),
          'last_name': lastNameController.text.trim(),
          'clinic_name': clinicNameController.text.trim(),
          'degree': degreeController.text.trim(),
          'contact_number': contactController.text.trim(),
          'email': emailController.text.trim(),
          'adhar_number': adharController.text.trim(),
          'pan_number': panController.text.trim(),
          'mmc_registration_number': mmcController.text.trim(),
          'clinic_registration_number': clinicRegController.text.trim(),
          'clinic_address': clinicAddressController.text.trim(),
          'village': villageController.text.trim(),
          'city': cityController.text.trim(),
          'taluka': talukaController.text.trim(),
          'district': districtController.text.trim(),
          'state': stateController.text.trim(),
          'pincode': pincodeController.text.trim(),
          'password': passwordController.text.trim(),
          'password_confirmation': repeatPasswordController.text.trim(),
          'terms_accepted': '1',
        },
        files: files.map((key, value) => MapEntry(key, value!)),
      );
      Get.snackbar('Registration successful', response['message']?.toString() ?? 'Doctor registration submitted');
      Get.offAllNamed(AppRoutes.login);
    } catch (error) {
      Get.snackbar('Registration failed', error.toString().replaceFirst('Exception: ', ''));
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    for (final controller in [
      firstNameController,
      lastNameController,
      clinicNameController,
      degreeController,
      contactController,
      emailController,
      adharController,
      panController,
      mmcController,
      clinicRegController,
      clinicAddressController,
      villageController,
      cityController,
      talukaController,
      districtController,
      stateController,
      pincodeController,
      passwordController,
      repeatPasswordController,
    ]) {
      controller.dispose();
    }
    super.onClose();
  }
}
