import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
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

  @override
  void onInit() {
    super.onInit();
    refreshProfile();
    refreshAppointments();
    refreshSettings();
    _startRealtimeDoctorSync();
    initialiseNotifications();
  }

  @override
  void onClose() {
    _profileSyncTimer?.cancel();
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
  }) async {
    final current = profile.value;
    if (current == null) return;

    try {
      loading.value = true;
      final updated = await _apiService.updateDoctorProfile(
        doctorId: current.id,
        fields: fields,
      );
      profile.value = updated;
      await SessionService.saveProfile(updated);
      notifications.assignAll(_buildNotifications(updated));
      Get.snackbar('Profile Updated', 'Doctor information saved successfully.');
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
    }
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

  Future<void> openNavigation(DoctorAppointment appointment) async {
    Uri? uri;
    if (appointment.latitude != null && appointment.longitude != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${appointment.latitude},${appointment.longitude}',
      );
    } else if (appointment.address.trim().isNotEmpty) {
      final query = Uri.encodeComponent(appointment.address.trim());
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    }

    if (uri == null) {
      Get.snackbar('Location Missing', 'Farmer location is not available for navigation.');
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      Get.snackbar('Navigation Error', 'Unable to open Google Maps.');
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
    await SessionService.logout();
    Get.offAllNamed(AppRoutes.login);
  }
}
