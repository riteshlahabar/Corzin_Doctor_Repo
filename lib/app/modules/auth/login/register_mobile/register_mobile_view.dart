import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/doctor_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import 'register_mobile_controller.dart';

class RegisterMobileView extends GetView<RegisterMobileController> {
  const RegisterMobileView({super.key});

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
          'Verify Mobile Number',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Doctor Registration',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please verify your mobile number before registration.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),

              DoctorTextField(
                controller: controller.mobileController,
                label: 'Mobile Number',
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),

              const SizedBox(height: 16),

              Obx(
                () => SizedBox(
                  height: 44,
                  child: PrimaryButton(
                    label: controller.otpSent.value ? 'Resend OTP' : 'Send OTP',
                    loading: controller.isSendingOtp.value,
                    onPressed: controller.sendOtp,
                  ),
                ),
              ),

              Obx(() {
                if (!controller.otpSent.value) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    const Text(
                      'Enter OTP',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    AutofillGroup(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return SizedBox(
                            width: 46,
                            height: 54,
                            child: TextField(
                              controller: controller.otpControllers[index],
                              focusNode: controller.otpFocusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: index == 0 ? 6 : 1,
                              autofillHints: index == 0 ? const [AutofillHints.oneTimeCode] : null,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(index == 0 ? 6 : 1),
                              ],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.zero,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.grey.withValues(alpha: 0.35),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                controller.onOtpChanged(value, index);
                              },
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Obx(
                      () => SizedBox(
                        height: 44,
                        child: PrimaryButton(
                          label: 'Verify OTP',
                          loading: controller.isVerifyingOtp.value,
                          onPressed: controller.verifyOtp,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
