import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/api_service.dart';
import '../../../../routes/app_pages.dart';


class RegisterMobileController extends GetxController {
  final mobileController = TextEditingController();

  final otpControllers = List.generate(6, (_) => TextEditingController());
  final otpFocusNodes = List.generate(6, (_) => FocusNode());

  final isSendingOtp = false.obs;
  final isVerifyingOtp = false.obs;
  final otpSent = false.obs;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService();

  String? _verificationId;
  String? _firebaseIdToken;
  bool _isNavigating = false;

  String get otpCode => otpControllers.map((e) => e.text.trim()).join();

  Future<void> sendOtp() async {
    final mobile = mobileController.text.trim();

    if (!RegExp(r'^\d{10}$').hasMatch(mobile)) {
      Get.snackbar('Invalid Mobile', 'Please enter valid 10 digit mobile number');
      return;
    }

    try {
      isSendingOtp.value = true;
      otpSent.value = false;
      clearOtp();
      _firebaseIdToken = null;

      await _apiService.checkDoctorMobileAvailability(mobileNumber: mobile);

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: '+91$mobile',
        timeout: const Duration(seconds: 60),

        // Auto OTP verification if Android detects SMS
        verificationCompleted: (PhoneAuthCredential credential) async {
          final smsCode = credential.smsCode;
          if (smsCode != null && smsCode.trim().isNotEmpty) {
            applyOtpCode(smsCode, verifyWhenComplete: false);
          }
          await _completeFirebaseVerification(credential, silent: true);
        },

        verificationFailed: (FirebaseAuthException error) {
          Get.snackbar(
            'OTP Failed',
            error.message ?? 'Firebase OTP verification failed',
          );
        },

        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          otpSent.value = true;
          Get.snackbar('OTP Sent', 'OTP sent successfully');

          Future.delayed(const Duration(milliseconds: 300), () {
            if (otpFocusNodes.isNotEmpty) {
              otpFocusNodes.first.requestFocus();
            }
          });
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (error) {
      Get.snackbar('OTP Failed', error.toString().replaceFirst('Exception: ', ''));
    } finally {
      isSendingOtp.value = false;
    }
  }

  void onOtpChanged(String value, int index) {
    final digits = value.replaceAll(RegExp(r'\D+'), '');
    if (digits.length > 1) {
      applyOtpCode(digits);
      return;
    }

    if (value.isNotEmpty && index < 5) {
      otpFocusNodes[index + 1].requestFocus();
    }

    if (value.isEmpty && index > 0) {
      otpFocusNodes[index - 1].requestFocus();
    }

    if (otpCode.length == 6) {
      verifyOtp();
    }
  }

  void applyOtpCode(String value, {bool verifyWhenComplete = true}) {
    final digits = value.replaceAll(RegExp(r'\D+'), '');
    if (digits.isEmpty) return;

    final code = digits.length > 6 ? digits.substring(0, 6) : digits;
    for (var i = 0; i < otpControllers.length; i++) {
      otpControllers[i].text = i < code.length ? code[i] : '';
    }

    if (code.length == 6) {
      for (final node in otpFocusNodes) {
        node.unfocus();
      }
      if (verifyWhenComplete) {
        verifyOtp();
      }
      return;
    }

    final focusIndex = code.length.clamp(0, otpFocusNodes.length - 1).toInt();
    otpFocusNodes[focusIndex].requestFocus();
  }

  Future<void> verifyOtp() async {
    final otp = otpCode;

    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      Get.snackbar('Invalid OTP', 'Please enter valid 6 digit OTP');
      return;
    }

    if (_verificationId == null || _verificationId!.isEmpty) {
      Get.snackbar('OTP Required', 'Please send OTP again');
      return;
    }

    try {
      isVerifyingOtp.value = true;

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await _completeFirebaseVerification(credential);
    } catch (error) {
      Get.snackbar('OTP Failed', 'Invalid OTP or verification failed');
    } finally {
      isVerifyingOtp.value = false;
    }
  }

  Future<void> _completeFirebaseVerification(
    PhoneAuthCredential credential, {
    bool silent = false,
  }) async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final token = await userCredential.user?.getIdToken(true);

      if (token == null || token.isEmpty) {
        throw Exception('Firebase verification token not received.');
      }

      _firebaseIdToken = token;

      if (!silent) {
        Get.snackbar('Verified', 'Mobile number verified successfully');
      }

      Get.offNamed(
        AppRoutes.register,
        arguments: {
          'verified_mobile': mobileController.text.trim(),
          'firebase_id_token': _firebaseIdToken,
        },
      );
    } catch (_) {
      _isNavigating = false;
      rethrow;
    }
  }

  void clearOtp() {
    for (final controller in otpControllers) {
      controller.clear();
    }
  }

  @override
  void onClose() {
    mobileController.dispose();

    for (final controller in otpControllers) {
      controller.dispose();
    }

    for (final node in otpFocusNodes) {
      node.dispose();
    }

    super.onClose();
  }
}
