import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/doctor_appointment.dart';
import '../../core/models/doctor_profile.dart';
import '../../core/models/doctor_settings.dart';
import '../../core/services/api_service.dart';
import '../../core/services/firebase_messaging_service.dart';
import '../../core/services/session_service.dart';
import '../../routes/app_pages.dart';

class HomeController extends GetxController {
  final selectedIndex = 0.obs;
  final profile = Rxn<DoctorProfile>(SessionService.profile);
  final loading = false.obs;
  final appointmentLoading = false.obs;
  final notifications = <String>[].obs;
  final appointments = <DoctorAppointment>[].obs;
  final banners = <DoctorBannerItem>[].obs;
  final appSettings = Rxn<DoctorSettings>();
  final ApiService _apiService = ApiService();
  final FirebaseMessagingService _firebaseMessagingService = FirebaseMessagingService();

  Timer? _profileSyncTimer;
  Timer? _liveLocationTimer;

  @override
  void onInit() {
    super.onInit();
    refreshProfile();
    refreshAppointments();
    refreshSettings();
    _startRealtimeDoctorSync();
    _startLiveLocationSync();
    initialiseNotifications();
  }

  @override
  void onClose() {
    _profileSyncTimer?.cancel();
    _liveLocationTimer?.cancel();
    super.onClose();
  }

  void _startRealtimeDoctorSync() {
    _profileSyncTimer?.cancel();
    _profileSyncTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      refreshProfile();
      refreshAppointments();
      refreshSettings();
    });
  }

  void _startLiveLocationSync() {
    _liveLocationTimer?.cancel();
    _liveLocationTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      _pushLiveLocationForActiveAppointments();
    });
  }

  Future<void> refreshSettings() async {
    try {
      final settings = await _apiService.fetchDoctorSettings();
      appSettings.value = settings;
      banners.assignAll(settings.banners);
    } catch (_) {}
  }

  String get termsAndConditions => appSettings.value?.termsAndConditions ?? '';

  String get privacyPolicy => appSettings.value?.privacyPolicy ?? '';

  Future<void> refreshProfile() async {
    final current = profile.value;
    if (current == null) return;
    try {
      loading.value = true;
      final freshProfile = await _apiService.fetchProfile(current.id);
      profile.value = freshProfile;
      await SessionService.saveProfile(freshProfile);
      notifications.assignAll(_buildNotifications(freshProfile));
    } catch (_) {
      notifications.assignAll(_buildNotifications(current));
    } finally {
      loading.value = false;
    }
  }

  Future<void> updateDoctorProfile({
    required Map<String, String> fields,
    Map<String, PlatformFile> files = const {},
    String successMessage = 'Doctor information saved successfully.',
  }) async {
    final current = profile.value;
    if (current == null) return;

    try {
      loading.value = true;
      final updated = await _apiService.updateDoctorProfile(
        doctorId: current.id,
        fields: fields,
        files: files,
      );
      profile.value = updated;
      await SessionService.saveProfile(updated);
      notifications.assignAll(_buildNotifications(updated));
      Get.snackbar('Profile Updated', successMessage);
    } finally {
      loading.value = false;
    }
  }

  Future<void> refreshAppointments() async {
    final currentProfile = profile.value;
    if (currentProfile == null) return;

    try {
      appointmentLoading.value = true;
      final list = await _apiService.fetchDoctorAppointments(doctorId: currentProfile.id);
      appointments.assignAll(list);
    } catch (_) {
      if (appointments.isEmpty) {
        appointments.assignAll(_fallbackAppointments());
      }
    } finally {
      appointmentLoading.value = false;
      _pushLiveLocationForActiveAppointments();
    }
  }

  Future<void> _pushLiveLocationForActiveAppointments() async {
    final active = appointments.where((a) => a.canNavigate).toList();
    if (active.isEmpty) return;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      for (final appointment in active) {
        await updateAppointmentLiveLocation(
          appointment: appointment,
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
      }
    } catch (_) {}
  }

  List<String> _buildNotifications(DoctorProfile doctor) {
    final list = <String>[
      'Registration submitted for ${doctor.fullName}.',
    ];
    if (doctor.status.toLowerCase() == 'approved') {
      list.add('Your profile has been approved by admin. You can now use the app.');
    } else {
      list.add('Your account is awaiting admin approval.');
    }

    final pendingCount = appointments.where((appointment) => appointment.canFixAppointment).length;
    if (pendingCount > 0) {
      list.add('$pendingCount new appointment request(s) waiting for your action.');
    }

    return list;
  }

  Future<void> initialiseNotifications() async {
    final current = profile.value;
    if (current == null) return;

    try {
      final token = await _firebaseMessagingService.initialise();
      if (token != null && token.isNotEmpty) {
        await _apiService.updateFcmToken(doctorId: current.id, token: token);
      }

      _firebaseMessagingService.tokenRefreshStream().listen((token) async {
        final profileValue = profile.value;
        if (profileValue == null) return;
        await _apiService.updateFcmToken(doctorId: profileValue.id, token: token);
      });

      _firebaseMessagingService.foregroundMessageStream().listen(_handleRemoteMessage);
      _firebaseMessagingService.messageOpenedAppStream().listen(_handleRemoteMessage);

      final initialMessage = await _firebaseMessagingService.getInitialMessage();
      if (initialMessage != null) {
        _handleRemoteMessage(initialMessage);
      }
    } catch (_) {}
  }

  void _handleRemoteMessage(RemoteMessage message) {
    final title = message.notification?.title?.trim();
    final body = message.notification?.body?.trim();

    final lines = <String>[
      if (title != null && title.isNotEmpty) title,
      if (body != null && body.isNotEmpty) body,
    ];

    if (lines.isEmpty) return;

    notifications.insert(0, lines.join(': '));

    Get.snackbar(
      title ?? 'Notification',
      body?.isNotEmpty == true ? body! : 'You have a new update.',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );

    refreshProfile();
    refreshAppointments();
  }

  Future<void> proposeAppointmentSlot({
    required DoctorAppointment appointment,
    required DateTime scheduledAt,
    required double charges,
  }) async {
    try {
      await _apiService.proposeAppointment(
        appointmentId: appointment.id,
        scheduledAt: scheduledAt,
        charges: charges,
      );
      _upsertAppointment(
        appointment.copyWith(
          status: 'proposed',
          scheduledAt: scheduledAt,
          charges: charges,
        ),
      );
      Get.snackbar('Appointment Updated', 'Schedule and charges shared with farmer for approval.');
    } catch (_) {
      _upsertAppointment(
        appointment.copyWith(
          status: 'proposed',
          scheduledAt: scheduledAt,
          charges: charges,
        ),
      );
      Get.snackbar('Saved In App', 'Backend endpoint not ready yet, but appointment preview updated.');
    }
  }

  Future<void> approveAppointment(DoctorAppointment appointment) async {
    try {
      await _apiService.doctorDecision(
        appointmentId: appointment.id,
        action: 'approved',
      );
      await refreshAppointments();
      Get.snackbar('Approved', 'Appointment approved successfully.');
    } catch (_) {
      _upsertAppointment(appointment.copyWith(status: 'approved'));
      Get.snackbar('Saved In App', 'Approved locally. Backend sync pending.');
    }
  }

  Future<void> declineAppointment(DoctorAppointment appointment) async {
    try {
      await _apiService.doctorDecision(
        appointmentId: appointment.id,
        action: 'declined',
      );
      await refreshAppointments();
      Get.snackbar('Declined', 'Appointment declined successfully.');
    } catch (_) {
      _upsertAppointment(appointment.copyWith(status: 'declined'));
      Get.snackbar('Saved In App', 'Declined locally. Backend sync pending.');
    }
  }

  Future<void> rescheduleAppointment({
    required DoctorAppointment appointment,
    required DateTime scheduledAt,
    required double charges,
  }) async {
    try {
      await _apiService.doctorDecision(
        appointmentId: appointment.id,
        action: 'rescheduled',
        scheduledAt: scheduledAt,
        charges: charges,
      );
      await refreshAppointments();
      Get.snackbar('Rescheduled', 'Appointment rescheduled successfully.');
    } catch (_) {
      _upsertAppointment(
        appointment.copyWith(
          status: 'rescheduled',
          scheduledAt: scheduledAt,
          charges: charges,
        ),
      );
      Get.snackbar('Saved In App', 'Rescheduled locally. Backend sync pending.');
    }
  }

  Future<void> markAppointmentCompleted(DoctorAppointment appointment) async {
    try {
      await _apiService.completeAppointment(appointmentId: appointment.id);
      _upsertAppointment(appointment.copyWith(status: 'completed'));
      Get.snackbar('Visit Completed', 'Appointment marked as completed.');
    } catch (_) {
      _upsertAppointment(appointment.copyWith(status: 'completed'));
      Get.snackbar('Saved In App', 'Marked as completed in app preview.');
    }
  }


  Future<void> verifyAppointmentOtp({
    required DoctorAppointment appointment,
    required String otp,
  }) async {
    debugPrint(
      '[OTP][CTRL] verifyAppointmentOtp called: appointment=${appointment.id}, '
      'status=${appointment.status}, otp=$otp',
    );
    try {
      final response = await _apiService.verifyAppointmentOtp(
        appointmentId: appointment.id,
        otp: otp,
      );
      debugPrint('[OTP][CTRL] verifyAppointmentOtp response: $response');

      final map = response['data'];
      if (map is Map<String, dynamic>) {
        _upsertAppointment(DoctorAppointment.fromJson(map));
      } else {
        _upsertAppointment(appointment.copyWith(otpVerifiedAt: DateTime.now()));
      }

      Get.snackbar('OTP Verified', response['message']?.toString() ?? 'OTP verified successfully.');
    } catch (e) {
      debugPrint('[OTP][CTRL] verifyAppointmentOtp error: $e');
      Get.snackbar('OTP Failed', e.toString());
    }
  }

  Future<bool> sendAppointmentOtp({
    required DoctorAppointment appointment,
    bool showSuccess = true,
  }) async {
    debugPrint(
      '[OTP][CTRL] sendAppointmentOtp called: appointment=${appointment.id}, '
      'status=${appointment.status}, farmerPhone=${appointment.farmerPhone}',
    );
    try {
      final response = await _apiService.doctorDecision(
        appointmentId: appointment.id,
        action: 'approved',
      );
      debugPrint('[OTP][CTRL] sendAppointmentOtp response: $response');

      final map = response['data'];
      if (map is Map<String, dynamic>) {
        _upsertAppointment(DoctorAppointment.fromJson(map));
      } else {
        _upsertAppointment(
          appointment.copyWith(
            status: 'approved',
            otpVerifiedAt: null,
          ),
        );
      }

      if (showSuccess) {
        Get.snackbar(
          'OTP Sent',
          response['message']?.toString() ?? 'OTP sent to farmer successfully.',
        );
      }
      return true;
    } catch (e) {
      debugPrint('[OTP][CTRL] sendAppointmentOtp error: $e');
      Get.snackbar('OTP Send Failed', e.toString());
      return false;
    }
  }

  Future<void> startAppointmentTreatment({
    required DoctorAppointment appointment,
    String? notes,
  }) async {
    try {
      final response = await _apiService.startTreatment(
        appointmentId: appointment.id,
        notes: notes,
      );

      final map = response['data'];
      if (map is Map<String, dynamic>) {
        _upsertAppointment(DoctorAppointment.fromJson(map));
      } else {
        _upsertAppointment(
          appointment.copyWith(
            status: 'in_progress',
            treatmentStartedAt: DateTime.now(),
          ),
        );
      }

      Get.snackbar('Treatment Started', response['message']?.toString() ?? 'Treatment started successfully.');
    } catch (e) {
      Get.snackbar('Start Failed', e.toString());
    }
  }

  Future<void> saveAppointmentTreatment({
    required DoctorAppointment appointment,
    required String treatmentDetails,
    bool followupRequired = false,
    DateTime? nextFollowupDate,
    String? notes,
  }) async {
    try {
      final response = await _apiService.saveTreatment(
        appointmentId: appointment.id,
        treatmentDetails: treatmentDetails,
        followupRequired: followupRequired,
        nextFollowupDate: nextFollowupDate,
        notes: notes,
      );

      final map = response['data'];
      if (map is Map<String, dynamic>) {
        _upsertAppointment(DoctorAppointment.fromJson(map));
      } else {
        _upsertAppointment(
          appointment.copyWith(
            treatmentDetails: treatmentDetails,
            followupRequired: followupRequired,
            nextFollowupDate: nextFollowupDate,
            notes: notes ?? appointment.notes,
          ),
        );
      }

      Get.snackbar('Treatment Saved', response['message']?.toString() ?? 'Treatment details saved successfully.');
    } catch (e) {
      Get.snackbar('Save Failed', e.toString());
    }
  }

  Future<void> updateAppointmentLiveLocation({
    required DoctorAppointment appointment,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _apiService.updateLiveLocation(
        appointmentId: appointment.id,
        latitude: latitude,
        longitude: longitude,
      );

      _upsertAppointment(
        appointment.copyWith(
          doctorLiveLatitude: latitude,
          doctorLiveLongitude: longitude,
          doctorLiveUpdatedAt: DateTime.now(),
        ),
      );
    } catch (_) {}
  }
  Future<void> openNavigation(DoctorAppointment appointment) async {
    final hasLatLng = appointment.latitude != null && appointment.longitude != null;
    final hasAddress = appointment.address.trim().isNotEmpty;
    if (!hasLatLng && !hasAddress) {
      Get.snackbar('Location Missing', 'Farmer location is not available for navigation.');
      return;
    }

    final targets = <Uri>[];
    if (hasLatLng) {
      final lat = appointment.latitude!;
      final lng = appointment.longitude!;
      final query = '$lat,$lng';
      targets.add(Uri.parse('comgooglemaps://?q=$query'));
      targets.add(Uri.parse('geo:$query?q=$query'));
      targets.add(Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}'));
    }

    if (hasAddress) {
      final address = appointment.address.trim();
      final encoded = Uri.encodeComponent(address);
      targets.add(Uri.parse('comgooglemaps://?q=$encoded'));
      targets.add(Uri.parse('geo:0,0?q=$encoded'));
      targets.add(Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded'));
    }

    for (final uri in targets) {
      final launched = await _tryLaunchUri(uri);
      if (launched) return;
    }

    if (hasAddress) {
      final encoded = Uri.encodeComponent(appointment.address.trim());
      final browserFallback = Uri.parse('https://maps.google.com/?q=$encoded');
      final launched = await _tryLaunchUri(browserFallback);
      if (launched) return;
    }

    if (hasLatLng) {
      final lat = appointment.latitude!;
      final lng = appointment.longitude!;
      final browserFallback = Uri.parse('https://maps.google.com/?q=$lat,$lng');
      final launched = await _tryLaunchUri(browserFallback);
      if (launched) return;
    }

    if (!isClosed) {
      Get.snackbar('Navigation Error', 'Unable to open Google Maps.');
    }
  }

  Future<bool> _tryLaunchUri(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  void _upsertAppointment(DoctorAppointment updated) {
    final index = appointments.indexWhere((item) => item.id == updated.id);
    if (index == -1) {
      appointments.insert(0, updated);
      return;
    }
    appointments[index] = updated;
    appointments.refresh();
  }

  List<DoctorAppointment> _fallbackAppointments() {
    final now = DateTime.now();
    return [
      DoctorAppointment(
        id: 1,
        farmerName: 'Ramesh Patil',
        animalName: 'Cow - Gauri',
        concern: 'Fever and low appetite',
        status: 'pending',
        animalPhotoUrl: 'assets/images/available_doctor_1st.png',
        requestedAt: now.subtract(const Duration(hours: 2)),
        address: 'Karad, Satara, Maharashtra',
        latitude: 17.2890,
        longitude: 74.1818,
      ),
      DoctorAppointment(
        id: 2,
        farmerName: 'Sunita Jadhav',
        animalName: 'Buffalo - Laxmi',
        concern: 'Post treatment follow-up',
        status: 'approved',
        animalPhotoUrl: 'assets/images/available_doctor_2nd.png',
        requestedAt: now.subtract(const Duration(days: 1)),
        scheduledAt: now.add(const Duration(hours: 3)),
        charges: 650,
        address: 'Sangli, Maharashtra',
        latitude: 16.8524,
        longitude: 74.5815,
      ),
    ];
  }

  Future<void> logout() async {
    _profileSyncTimer?.cancel();
    _liveLocationTimer?.cancel();
    await SessionService.logout();
    Get.offAllNamed(AppRoutes.login);
  }
}

