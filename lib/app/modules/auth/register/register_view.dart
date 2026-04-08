import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/document_picker_tile.dart';
import '../../../core/widgets/doctor_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import 'register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
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
                    label: 'Dr First Name',
                    validator: (value) => controller.requiredValidator(value, 'Dr First Name'),
                  ),
                  DoctorTextField(
                    controller: controller.lastNameController,
                    label: 'Last Name',
                    validator: (value) => controller.requiredValidator(value, 'Last Name'),
                  ),
                ),
                const SizedBox(height: 14),
                DoctorTextField(
                  controller: controller.clinicNameController,
                  label: 'Clinic Name',
                  validator: (value) => controller.requiredValidator(value, 'Clinic Name'),
                ),
                const SizedBox(height: 14),
                _twoColumn(
                  DoctorTextField(
                    controller: controller.degreeController,
                    label: 'Degree',
                    validator: (value) => controller.requiredValidator(value, 'Degree'),
                  ),
                  DoctorTextField(
                    controller: controller.contactController,
                    label: 'Contact Number',
                    keyboardType: TextInputType.phone,
                    validator: (value) => controller.requiredValidator(value, 'Contact Number'),
                  ),
                ),
                const SizedBox(height: 14),
                _twoColumn(
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
                  DoctorTextField(
                    controller: controller.adharController,
                    label: 'Aadhar Number',
                    keyboardType: TextInputType.number,
                    validator: (value) => controller.requiredValidator(value, 'Aadhar Number'),
                  ),
                ),
                const SizedBox(height: 14),
                _twoColumn(
                  DoctorTextField(
                    controller: controller.panController,
                    label: 'PAN Number',
                    validator: (value) => controller.requiredValidator(value, 'PAN Number'),
                  ),
                  DoctorTextField(
                    controller: controller.mmcController,
                    label: 'MMC Reg No',
                    validator: (value) => controller.requiredValidator(value, 'MMC Reg No'),
                  ),
                ),
                const SizedBox(height: 14),
                _twoColumn(
                  DoctorTextField(
                    controller: controller.clinicRegController,
                    label: 'Clinic Reg No',
                    validator: (value) => controller.requiredValidator(value, 'Clinic Reg No'),
                  ),
                  const SizedBox.shrink(),
                ),
                const SizedBox(height: 14),
                DoctorTextField(
                  controller: controller.clinicAddressController,
                  label: 'Clinic Address',
                  maxLines: 3,
                  validator: (value) => controller.requiredValidator(value, 'Clinic Address'),
                ),
                const SizedBox(height: 24),
                _sectionTitle('Location Details'),
                const SizedBox(height: 14),
                _twoColumn(
                  DoctorTextField(
                    controller: controller.villageController,
                    label: 'Village',
                    validator: (value) => controller.requiredValidator(value, 'Village'),
                  ),
                  DoctorTextField(
                    controller: controller.cityController,
                    label: 'City',
                    validator: (value) => controller.requiredValidator(value, 'City'),
                  ),
                ),
                const SizedBox(height: 14),
                _twoColumn(
                  DoctorTextField(
                    controller: controller.talukaController,
                    label: 'Taluka',
                    validator: (value) => controller.requiredValidator(value, 'Taluka'),
                  ),
                  DoctorTextField(
                    controller: controller.districtController,
                    label: 'District',
                    validator: (value) => controller.requiredValidator(value, 'District'),
                  ),
                ),
                const SizedBox(height: 14),
                DoctorTextField(
                  controller: controller.stateController,
                  label: 'State',
                  validator: (value) => controller.requiredValidator(value, 'State'),
                ),
                const SizedBox(height: 14),
                DoctorTextField(
                  controller: controller.pincodeController,
                  label: 'Pincode',
                  keyboardType: TextInputType.number,
                  validator: (value) => controller.requiredValidator(value, 'Pincode'),
                ),
                const SizedBox(height: 24),
                _sectionTitle('Required Documents'),
                const SizedBox(height: 12),
                Obx(
                  () => Column(
                    children: [
                      DocumentPickerTile(
                        title: 'Aadhar Attachment',
                        fileName: controller.files['adhar_document']?.name,
                        onTap: () => controller.pickFile('adhar_document'),
                      ),
                      const SizedBox(height: 12),
                      DocumentPickerTile(
                        title: 'PAN Attachment',
                        fileName: controller.files['pan_document']?.name,
                        onTap: () => controller.pickFile('pan_document'),
                      ),
                      const SizedBox(height: 12),
                      DocumentPickerTile(
                        title: 'MMC Attachment',
                        fileName: controller.files['mmc_document']?.name,
                        onTap: () => controller.pickFile('mmc_document'),
                      ),
                      const SizedBox(height: 12),
                      DocumentPickerTile(
                        title: 'Clinic Registration Attachment',
                        fileName: controller.files['clinic_registration_document']?.name,
                        onTap: () => controller.pickFile('clinic_registration_document'),
                      ),
                      const SizedBox(height: 12),
                      DocumentPickerTile(
                        title: 'Doctor photo',
                        fileName: controller.files['doctor_photo']?.name,
                        onTap: () => controller.pickFile('doctor_photo', imageOnly: true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _sectionTitle('Security'),
                const SizedBox(height: 14),
                _twoColumn(
                  DoctorTextField(
                    controller: controller.passwordController,
                    label: 'Password',
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Password is required';
                      if (value.trim().length < 8) return 'Password must be at least 8 characters';
                      return null;
                    },
                  ),
                  DoctorTextField(
                    controller: controller.repeatPasswordController,
                    label: 'Repeat Password',
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
}
