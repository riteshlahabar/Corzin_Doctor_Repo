import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:collection';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/document_picker_tile.dart';
import '../../../core/widgets/doctor_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import 'register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  String _requiredLabel(String label) => '$label *';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Register Doctor',
          style: TextStyle(fontFamily: 'SF Pro Display', fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Basic Details'),
                const SizedBox(height: 14),
                _twoColumn(
                  DoctorTextField(
                    controller: controller.firstNameController,
                    label: _requiredLabel('Dr First Name'),
                    validator: (value) => controller.requiredValidator(value, 'Dr First Name'),
                  ),
                  DoctorTextField(
                    controller: controller.lastNameController,
                    label: _requiredLabel('Last Name'),
                    validator: (value) => controller.requiredValidator(value, 'Last Name'),
                  ),
                ),
                const SizedBox(height: 14),
                _twoColumn(
                  DoctorTextField(
                    controller: controller.degreeController,
                    label: _requiredLabel('Degree'),
                    validator: (value) => controller.requiredValidator(value, 'Degree'),
                  ),
                  DoctorTextField(
                    controller: controller.contactController,
                    label: _requiredLabel('Contact Number'),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: controller.contactNumberValidator,
                  ),
                ),
                const SizedBox(height: 14),
                DoctorTextField(
                  controller: controller.whatsappController,
                  label: 'WhatsApp Number',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: controller.optionalContactNumberValidator,
                ),
                const SizedBox(height: 14),
                _twoColumn(
                  DoctorTextField(
                    controller: controller.emailController,
                    label: _requiredLabel('Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Email is required';
                      if (!GetUtils.isEmail(value.trim())) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  DoctorTextField(
                    controller: controller.adharController,
                    label: _requiredLabel('Aadhar Number'),
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                    ],
                    validator: controller.adharNumberValidator,
                  ),
                ),
                const SizedBox(height: 14),
                _twoColumn(
                  DoctorTextField(
                    controller: controller.panController,
                    label: _requiredLabel('PAN Number'),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                      LengthLimitingTextInputFormatter(10),
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        final upper = newValue.text.toUpperCase();
                        return newValue.copyWith(
                          text: upper,
                          selection: newValue.selection,
                        );
                      }),
                    ],
                    validator: controller.panNumberValidator,
                  ),
                  DoctorTextField(
                    controller: controller.mmcController,
                    label: _requiredLabel('MMC Reg No'),
                    validator: (value) => controller.requiredValidator(value, 'MMC Reg No'),
                  ),
                ),
                const SizedBox(height: 14),
                _twoColumn(
                  DoctorTextField(
                    controller: controller.clinicNameController,
                    label: 'Clinic Name',
                  ),
                  DoctorTextField(
                    controller: controller.clinicRegController,
                    label: 'Clinic Reg No',
                  ),
                ),
                const SizedBox(height: 14),
                DoctorTextField(
                  controller: controller.clinicAddressController,
                  label: 'Clinic Address',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                _sectionTitle('Location Details'),
                const SizedBox(height: 14),
                Obx(
                  () => _dropdownField(
                    label: _requiredLabel('State'),
                    hintLabel: 'State',
                    value: controller.stateController.text.trim().isEmpty
                        ? null
                        : controller.stateController.text.trim(),
                    items: controller.states,
                    enabled: !controller.isLocationLoading.value,
                    onChanged: (value) {
                      if (value == null) return;
                      controller.onStateChanged(value);
                    },
                    validator: (value) => controller.requiredValidator(value, 'State'),
                  ),
                ),
                const SizedBox(height: 14),
                Obx(
                  () => _dropdownField(
                    label: _requiredLabel('District'),
                    hintLabel: 'District',
                    value: controller.districtController.text.trim().isEmpty
                        ? null
                        : controller.districtController.text.trim(),
                    items: controller.districts,
                    enabled: controller.districts.isNotEmpty,
                    onChanged: (value) {
                      if (value == null) return;
                      controller.onDistrictChanged(value);
                    },
                    validator: (value) => controller.requiredValidator(value, 'District'),
                  ),
                ),
                const SizedBox(height: 14),
                Obx(
                  () => _dropdownField(
                    label: _requiredLabel('Taluka / Subdistrict / City'),
                    hintLabel: 'Taluka / Subdistrict / City',
                    value: controller.talukaController.text.trim().isEmpty
                        ? null
                        : controller.talukaController.text.trim(),
                    items: controller.talukas,
                    enabled: controller.talukas.isNotEmpty,
                    onChanged: (value) {
                      if (value == null) return;
                      controller.onTalukaChanged(value);
                    },
                    validator: (value) =>
                        controller.requiredValidator(value, 'Taluka / Subdistrict / City'),
                  ),
                ),
                const SizedBox(height: 14),
                DoctorTextField(
                  controller: controller.villageController,
                  label: _requiredLabel('Village'),
                  validator: (value) => controller.requiredValidator(value, 'Village'),
                ),
                const SizedBox(height: 14),
                DoctorTextField(
                  controller: controller.pincodeController,
                  label: _requiredLabel('Pincode'),
                  keyboardType: TextInputType.number,
                  validator: (value) => controller.requiredValidator(value, 'Pincode'),
                ),
                const SizedBox(height: 24),
                _sectionTitle('Required Documents'),
                const SizedBox(height: 12),
                Obx(
                  () {
                    final isAadharFrontMissing = controller.isRequiredDocumentMissing('adhar_document_front');
                    final isAadharBackMissing = controller.isRequiredDocumentMissing('adhar_document_back');
                    final aadharHasError = isAadharFrontMissing || isAadharBackMissing;
                    final aadharErrorText = isAadharFrontMissing && isAadharBackMissing
                        ? 'Please upload Aadhar front and back.'
                        : (isAadharFrontMissing
                            ? 'Please upload Aadhar front.'
                            : (isAadharBackMissing ? 'Please upload Aadhar back.' : null));

                    return Column(
                      children: [
                        DocumentPickerTile(
                          title: _requiredLabel('Aadhar Attachment'),
                          fileName: _aadharAttachmentSummary(),
                          onTap: _openAadharAttachmentPicker,
                          hasError: aadharHasError,
                          errorText: aadharErrorText,
                        ),
                        const SizedBox(height: 12),
                        DocumentPickerTile(
                          title: _requiredLabel('PAN Attachment'),
                          fileName: controller.files['pan_document']?.name,
                          onTap: () => controller.pickFile('pan_document'),
                          hasError: controller.isRequiredDocumentMissing('pan_document'),
                          errorText: 'Please upload PAN attachment.',
                        ),
                        const SizedBox(height: 12),
                        DocumentPickerTile(
                          title: _requiredLabel('MMC Attachment'),
                          fileName: controller.files['mmc_document']?.name,
                          onTap: () => controller.pickFile('mmc_document'),
                          hasError: controller.isRequiredDocumentMissing('mmc_document'),
                          errorText: 'Please upload MMC attachment.',
                        ),
                        const SizedBox(height: 12),
                        DocumentPickerTile(
                          title: 'Clinic Registration Attachment',
                          fileName: controller.files['clinic_registration_document']?.name,
                          onTap: () => controller.pickFile('clinic_registration_document'),
                        ),
                        const SizedBox(height: 12),
                        DocumentPickerTile(
                          title: _requiredLabel('Doctor photo'),
                          fileName: controller.files['doctor_photo']?.name,
                          onTap: () => controller.pickFile('doctor_photo', imageOnly: true),
                          hasError: controller.isRequiredDocumentMissing('doctor_photo'),
                          errorText: 'Please upload doctor photo.',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _sectionTitle('Security'),
                const SizedBox(height: 14),
                _twoColumn(
                  DoctorTextField(
                    controller: controller.passwordController,
                    label: _requiredLabel('Password'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Password is required';
                      if (value.trim().length < 8) return 'Password must be at least 8 characters';
                      return null;
                    },
                  ),
                  DoctorTextField(
                    controller: controller.repeatPasswordController,
                    label: _requiredLabel('Repeat Password'),
                    obscureText: true,
                    validator: (value) => controller.requiredValidator(value, 'Repeat Password'),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Terms And Conditions',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Obx(
                        () => Text(
                          controller.termsText.value,
                          style: const TextStyle(fontSize: 13, color: AppColors.grey),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => CheckboxListTile(
                          value: controller.agreeTerms.value,
                          onChanged: (value) => controller.agreeTerms.value = value ?? false,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text(
                            'I Agree Terms And Condition',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Obx(
                  () => PrimaryButton(
                    label: 'Register',
                    loading: controller.isSubmitting.value,
                    onPressed: controller.registerDoctor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'SF Pro Display',
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _twoColumn(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 14),
        Expanded(child: right),
      ],
    );
  }

  Widget _dropdownField({
    required String label,
    required String hintLabel,
    required String? value,
    required List<String> items,
    required bool enabled,
    required ValueChanged<String?> onChanged,
    required String? Function(String?) validator,
  }) {
    final uniqueItems = LinkedHashSet<String>.from(
      items.map((item) => item.trim()).where((item) => item.isNotEmpty),
    ).toList(growable: false);
    final selectedValue = (value != null && uniqueItems.contains(value.trim()))
        ? value.trim()
        : null;
    return DropdownButtonFormField<String>(
      key: ValueKey('$label|${uniqueItems.length}|${selectedValue ?? ''}'),
      initialValue: selectedValue,
      isExpanded: true,
      hint: Text('Select $hintLabel'),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
      items: uniqueItems
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
      validator: validator,
    );
  }

  String? _aadharAttachmentSummary() {
    final front = controller.files['adhar_document_front']?.name;
    final back = controller.files['adhar_document_back']?.name;
    if (front != null && back != null) {
      return 'Front + Back selected';
    }
    if (front != null) {
      return 'Front selected, Back pending';
    }
    if (back != null) {
      return 'Back selected, Front pending';
    }
    return null;
  }

  void _openAadharAttachmentPicker({bool showBackOnly = false}) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aadhar Attachment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              showBackOnly
                  ? 'Front selected. Now upload back side.'
                  : 'Choose which side to upload',
              style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
            ),
            const SizedBox(height: 12),
            if (!showBackOnly)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.credit_card_rounded, color: AppColors.primary),
                title: const Text('Front'),
                subtitle: Text(
                  controller.files['adhar_document_front']?.name ?? 'Tap to upload front side',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: _pickAadharFrontThenBack,
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.credit_card_rounded, color: AppColors.primary),
              title: const Text('Back'),
              subtitle: Text(
                controller.files['adhar_document_back']?.name ?? 'Tap to upload back side',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: _pickAadharBackAndFinish,
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _pickAadharFrontThenBack() async {
    Get.back();
    final pickedFront = await controller.pickFile('adhar_document_front');
    if (!pickedFront) {
      _openAadharAttachmentPicker();
      return;
    }

    if (controller.files['adhar_document_back'] == null) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      _openAadharAttachmentPicker(showBackOnly: true);
    }
  }

  Future<void> _pickAadharBackAndFinish() async {
    Get.back();
    await controller.pickFile('adhar_document_back');
  }
}
