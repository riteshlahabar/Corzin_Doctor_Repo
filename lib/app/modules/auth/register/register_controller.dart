
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/api_service.dart';
import '../../../routes/app_pages.dart';

class RegisterController extends GetxController {
  static const List<String> requiredFileKeys = <String>[
    'adhar_document_front',
    'adhar_document_back',
    'pan_document',
    'mmc_document',
    'doctor_photo',
  ];

  final formKey = GlobalKey<FormState>();
  final isSubmitting = false.obs;
  final agreeTerms = false.obs;
  final termsText = 'Terms content is managed from backend and accepted during registration.'.obs;
  final isLocationLoading = false.obs;
  final documentValidationTriggered = false.obs;

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
  final states = <String>[].obs;
  final districts = <String>[].obs;
  final talukas = <String>[].obs;
  int _stateRequestToken = 0;
  int _districtRequestToken = 0;

  @override
  void onInit() {
    super.onInit();
    stateController.text = 'Maharashtra';
    _loadSettings();
    _loadLocationCascade();
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

  Future<void> _loadLocationCascade() async {
    isLocationLoading.value = true;
    try {
      final stateList = await _apiService.fetchLocationStates();
      states.assignAll(_uniqueLocationValues(stateList));

      if (!states.contains(stateController.text.trim())) {
        stateController.text = states.contains('Maharashtra')
            ? 'Maharashtra'
            : (states.isNotEmpty ? states.first : 'Maharashtra');
      }

      await onStateChanged(stateController.text.trim(), autoSelectFirst: false);
    } catch (_) {
      if (states.isEmpty) {
        states.assignAll(['Maharashtra']);
        stateController.text = 'Maharashtra';
      }
    } finally {
      isLocationLoading.value = false;
    }
  }

  Future<void> onStateChanged(String state, {bool autoSelectFirst = false}) async {
    final selected = state.trim();
    if (selected.isEmpty) return;
    final token = ++_stateRequestToken;
    _districtRequestToken++;

    stateController.text = selected;
    districtController.clear();
    talukaController.clear();
    cityController.clear();
    districts.clear();
    talukas.clear();

    try {
      final districtList = await _apiService.fetchLocationDistricts(state: selected);
      if (token != _stateRequestToken || stateController.text.trim() != selected) return;
      districts.assignAll(_uniqueLocationValues(districtList));
      if (autoSelectFirst && districts.isNotEmpty) {
        await onDistrictChanged(districts.first, autoSelectFirst: true);
      }
    } catch (_) {}
  }

  Future<void> onDistrictChanged(String district, {bool autoSelectFirst = false}) async {
    final selectedState = stateController.text.trim();
    final selectedDistrict = district.trim();
    if (selectedState.isEmpty || selectedDistrict.isEmpty) return;
    final token = ++_districtRequestToken;

    districtController.text = selectedDistrict;
    talukaController.clear();
    cityController.clear();
    talukas.clear();

    try {
      final talukaList = await _apiService.fetchLocationTalukas(
        state: selectedState,
        district: selectedDistrict,
      );
      if (token != _districtRequestToken) return;
      if (stateController.text.trim() != selectedState) return;
      if (districtController.text.trim() != selectedDistrict) return;
      talukas.assignAll(_uniqueLocationValues(talukaList));
      if (autoSelectFirst && talukas.isNotEmpty) {
        await onTalukaChanged(talukas.first, autoSelectFirst: true);
      }
    } catch (_) {}
  }

  Future<void> onTalukaChanged(String taluka, {bool autoSelectFirst = false}) async {
    final selectedTaluka = taluka.trim();
    if (selectedTaluka.isEmpty) return;

    talukaController.text = selectedTaluka;
    cityController.text = selectedTaluka;
  }

  Future<bool> pickFile(String key, {bool imageOnly = false}) async {
    final result = await FilePicker.platform.pickFiles(
      type: imageOnly ? FileType.image : FileType.custom,
      allowedExtensions: imageOnly ? null : ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      files[key] = result.files.single;
      files.refresh();
      return true;
    }
    return false;
  }

  bool isRequiredDocumentMissing(String key) {
    if (!requiredFileKeys.contains(key)) return false;
    if (!documentValidationTriggered.value) return false;
    return files[key] == null;
  }

  String? requiredValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  String? adharNumberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Aadhar Number is required';
    }
    final digitsOnly = value.trim();
    if (!RegExp(r'^\d{12}$').hasMatch(digitsOnly)) {
      return 'Aadhar Number must be exactly 12 digits';
    }
    return null;
  }

  String? contactNumberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Contact Number is required';
    }
    final contact = value.trim();
    if (!RegExp(r'^\d{10}$').hasMatch(contact)) {
      return 'Contact Number must be exactly 10 digits';
    }
    return null;
  }

  String? panNumberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'PAN Number is required';
    }
    final pan = value.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(pan)) {
      return 'Enter valid PAN (example: ABCDE1234F)';
    }
    return null;
  }

  Future<void> registerDoctor() async {
    documentValidationTriggered.value = true;

    if (!formKey.currentState!.validate()) return;
    if (!agreeTerms.value) {
      Get.snackbar('Terms required', 'Please accept terms and conditions');
      return;
    }

    final missingFiles = <String>[
      if (files['adhar_document_front'] == null) 'Aadhar Front',
      if (files['adhar_document_back'] == null) 'Aadhar Back',
      if (files['pan_document'] == null) 'PAN Attachment',
      if (files['mmc_document'] == null) 'MMC Attachment',
      if (files['doctor_photo'] == null) 'Doctor Photo',
    ];
    final hasMissingFile = missingFiles.isNotEmpty;
    if (hasMissingFile) {
      Get.snackbar('Documents required', 'Please upload: ${missingFiles.join(', ')}');
      return;
    }

    if (passwordController.text != repeatPasswordController.text) {
      Get.snackbar('Password mismatch', 'Password and repeat password must match');
      return;
    }

    try {
      isSubmitting.value = true;
      final uploadFiles = <String, PlatformFile>{};
      for (final entry in files.entries) {
        final file = entry.value;
        if (file != null) {
          uploadFiles[entry.key] = file;
        }
      }

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
          'city': talukaController.text.trim(),
          'taluka': talukaController.text.trim(),
          'district': districtController.text.trim(),
          'state': stateController.text.trim(),
          'pincode': pincodeController.text.trim(),
          'password': passwordController.text.trim(),
          'password_confirmation': repeatPasswordController.text.trim(),
          'terms_accepted': '1',
        },
        files: uploadFiles,
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

  List<String> _uniqueLocationValues(List<String> values) {
    final unique = <String, String>{};
    for (final raw in values) {
      final value = raw.trim();
      if (value.isEmpty) continue;
      final key = value.toLowerCase();
      unique.putIfAbsent(key, () => value);
    }
    return unique.values.toList(growable: false);
  }
}
