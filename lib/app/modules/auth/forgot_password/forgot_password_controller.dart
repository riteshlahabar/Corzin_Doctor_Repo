import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/session_service.dart';
import '../../../routes/app_pages.dart';

class ForgotPasswordController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final hidePassword = true.obs;
  final hideConfirmPassword = true.obs;
  final isSendingOtp = false.obs;
  final isFetchingAccount = false.obs;
  final isVerifyingOtp = false.obs;
  final isSubmitting = false.obs;
  final accountFetched = false.obs;
  final otpSent = false.obs;
  final otpVerified = false.obs;

  final ApiService _apiService = ApiService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  String? _verificationId;
  String? _firebaseIdToken;
  String? _firebasePhoneNumber;
  String? _fetchedEmail;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    String initialEmail = '';
    if (args is Map && args['email'] != null) {
      initialEmail = args['email'].toString().trim();
    }
    if (initialEmail.isEmpty) {
      initialEmail = SessionService.lastLoginEmail.trim();
    }
    if (initialEmail.isEmpty) {
      initialEmail = (SessionService.profile?.email ?? '').trim();
    }
    if (initialEmail.isNotEmpty) {
      emailController.text = initialEmail;
      final profile = SessionService.profile;
      if (profile != null && profile.email.trim().toLowerCase() == initialEmail.toLowerCase()) {
        mobileController.text = profile.contactNumber.trim();
      }
    }

    if (emailController.text.trim().isNotEmpty) {
      Future.microtask(fetchAccountDetails);
    }
  }

  Future<void> fetchAccountDetails() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      Get.snackbar('Email required', 'Please enter email address');
      return;
    }
    if (!GetUtils.isEmail(email)) {
      Get.snackbar('Invalid email', 'Please enter a valid email address');
      return;
    }

    try {
      isFetchingAccount.value = true;
      final response = await _apiService.lookupForgotPasswordDoctor(email: email);
      final data = response['data'];
      final firebasePhoneNumber = data is Map
          ? (data['firebase_phone_number'] ?? '').toString().trim()
          : '';

      if (data is Map) {
        mobileController.text = (data['mobile_number'] ?? '').toString();
        final responseEmail = (data['email'] ?? '').toString().trim();
        if (responseEmail.isNotEmpty) {
          emailController.text = responseEmail;
        }
      }

      if (firebasePhoneNumber.isEmpty) {
        throw Exception('Mobile number is not available for this doctor account.');
      }

      _fetchedEmail = emailController.text.trim();
      _firebasePhoneNumber = firebasePhoneNumber;
      accountFetched.value = true;
    } catch (error) {
      accountFetched.value = false;
      _firebasePhoneNumber = null;
      Get.snackbar('Account lookup failed', error.toString().replaceFirst('Exception: ', ''));
    } finally {
      isFetchingAccount.value = false;
    }
  }

  Future<void> sendOtp() async {
    final email = emailController.text.trim();
    if (!accountFetched.value || _fetchedEmail != email || _firebasePhoneNumber == null) {
      await fetchAccountDetails();
    }
    if (!accountFetched.value || _firebasePhoneNumber == null) {
      return;
    }

    try {
      isSendingOtp.value = true;
      otpVerified.value = false;
      _firebaseIdToken = null;

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: _firebasePhoneNumber!,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          await _completeFirebaseVerification(credential, silent: true);
        },
        verificationFailed: (error) {
          Get.snackbar('OTP failed', error.message ?? 'Firebase OTP verification failed');
        },
        codeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          otpController.clear();
          otpSent.value = true;
          Get.snackbar('OTP Sent', 'OTP sent successfully');
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (error) {
      Get.snackbar('OTP failed', error.toString().replaceFirst('Exception: ', ''));
    } finally {
      isSendingOtp.value = false;
    }
  }

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();
    if (otp.length != 6) {
      Get.snackbar('Invalid OTP', 'Please enter valid 6 digit OTP');
      return;
    }
    final verificationId = _verificationId;
    if (verificationId == null || verificationId.isEmpty) {
      Get.snackbar('OTP required', 'Please send OTP again');
      return;
    }

    try {
      isVerifyingOtp.value = true;
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      await _completeFirebaseVerification(credential);
    } catch (error) {
      Get.snackbar('OTP failed', error.toString().replaceFirst('Exception: ', ''));
    } finally {
      isVerifyingOtp.value = false;
    }
  }

  Future<void> submit() async {
    if (!otpVerified.value || _firebaseIdToken == null) {
      Get.snackbar('OTP required', 'Please verify OTP first');
      return;
    }
    if (!formKey.currentState!.validate()) return;

    if (passwordController.text.trim() != confirmPasswordController.text.trim()) {
      Get.snackbar('Password mismatch', 'Password and confirm password must match');
      return;
    }

    try {
      isSubmitting.value = true;
      final response = await _apiService.resetForgotPassword(
        email: emailController.text.trim(),
        firebaseIdToken: _firebaseIdToken!,
        password: passwordController.text.trim(),
        passwordConfirmation: confirmPasswordController.text.trim(),
      );
      Get.snackbar('Success', response['message']?.toString() ?? 'Password reset successful');
      await _firebaseAuth.signOut();
      Get.offAllNamed(AppRoutes.login);
    } catch (error) {
      Get.snackbar('Reset failed', error.toString().replaceFirst('Exception: ', ''));
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> _completeFirebaseVerification(
    PhoneAuthCredential credential, {
    bool silent = false,
  }) async {
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final token = await userCredential.user?.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw Exception('Firebase verification token not received.');
    }

    _firebaseIdToken = token;
    otpVerified.value = true;
    if (!silent) {
      Get.snackbar('OTP Verified', 'OTP verified successfully');
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    mobileController.dispose();
    otpController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
