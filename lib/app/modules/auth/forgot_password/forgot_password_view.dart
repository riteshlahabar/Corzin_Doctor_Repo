import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
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
                DoctorTextField(
                  controller: controller.emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) {
                    controller.accountFetched.value = false;
                    controller.mobileController.clear();
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Email is required';
                    if (!GetUtils.isEmail(value.trim())) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Obx(
                  () => DoctorTextField(
                    controller: controller.mobileController,
                    label: 'Mobile Number',
                    keyboardType: TextInputType.phone,
                    readOnly: true,
                    hint: controller.isFetchingAccount.value
                        ? 'Fetching from backend...'
                        : controller.accountFetched.value
                            ? 'Mobile number fetched'
                            : 'Will fetch from backend',
                  ),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => PrimaryButton(
                    label: controller.otpSent.value ? 'Resend OTP' : 'Send OTP',
                    loading: controller.isSendingOtp.value || controller.isFetchingAccount.value,
                    onPressed: controller.sendOtp,
                  ),
                ),
                Obx(
                  () => controller.otpSent.value
                      ? Column(
                          children: [
                            const SizedBox(height: 14),
                            DoctorTextField(
                              controller: controller.otpController,
                              label: 'OTP',
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                            ),
                            const SizedBox(height: 14),
                            PrimaryButton(
                              label: controller.otpVerified.value ? 'OTP Verified' : 'Verify OTP',
                              loading: controller.isVerifyingOtp.value,
                              onPressed: controller.otpVerified.value ? () {} : controller.verifyOtp,
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                Obx(
                  () => controller.otpVerified.value
                      ? Column(
                          children: [
                            const SizedBox(height: 14),
                            Obx(
                              () => DoctorTextField(
                                controller: controller.passwordController,
                                label: 'New Password',
                                obscureText: controller.hidePassword.value,
                                suffixIcon: IconButton(
                                  onPressed: () => controller.hidePassword.toggle(),
                                  icon: Icon(
                                    controller.hidePassword.value
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'New Password is required';
                                  }
                                  if (value.trim().length < 8) {
                                    return 'Password must be at least 8 characters';
                                  }
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
                                    controller.hideConfirmPassword.value
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Confirm Password is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            PrimaryButton(
                              label: 'Reset Password',
                              loading: controller.isSubmitting.value,
                              onPressed: controller.submit,
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
