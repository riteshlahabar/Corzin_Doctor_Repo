import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/doctor_appointment.dart';
import '../../core/models/doctor_profile.dart';
import '../../core/models/doctor_settings.dart';
import '../../core/services/api_service.dart';
import '../../core/services/firebase_messaging_service.dart';
import '../../core/services/notification_alert_service.dart';
import '../../core/services/session_service.dart';
import '../../routes/app_pages.dart';

class HomeController extends GetxController {
  static const String _globalNotificationStoreKey = 'doctor_notification_history_global';
  final selectedIndex = 0.obs;
  final profile = Rxn<DoctorProfile>(SessionService.profile);
  final loading = false.obs;
  final appointmentLoading = false.obs;
  final notifications = <String>[].obs;
  final notificationHistory = <DoctorNotificationItem>[].obs;
  final appointments = <DoctorAppointment>[].obs;
  final otpRequestedAppointmentIds = <int>{}.obs;
  final currentDoctorLatitude = Rxn<double>();
  final currentDoctorLongitude = Rxn<double>();
  final appointmentDistanceLabels = <int, String>{}.obs;
  final banners = <DoctorBannerItem>[].obs;
  final appSettings = Rxn<DoctorSettings>();
  final ApiService _apiService = ApiService();
  final FirebaseMessagingService _firebaseMessagingService = FirebaseMessagingService();

  Timer? _profileSyncTimer;
  StreamSubscription<Position>? _doctorLocationSubscription;
  _GeoPoint? _lastSyncedDoctorPoint;
  int? _loadedNotificationDoctorId;

  @override
  void onInit() {
    super.onInit();
    _loadNotificationHistory();
    refreshProfile();
    refreshAppointments();
    refreshSettings();
    _startRealtimeDoctorSync();
    _syncLiveTrackingForAvailability();
    initialiseNotifications();
  }

  @override
  void onClose() {
    _profileSyncTimer?.cancel();
    _doctorLocationSubscription?.cancel();
    NotificationAlertService.stop();
    super.onClose();
  }

  void _startRealtimeDoctorSync() {
    _profileSyncTimer?.cancel();
    _profileSyncTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      await refreshProfile();
      await refreshSettings();
      await refreshAppointments(silent: true, refreshLocationAfter: false);
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
      _syncLiveTrackingForAvailability();
      await _ensureNotificationHistoryLoadedForDoctor(freshProfile.id);
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
      _syncLiveTrackingForAvailability();
      await _ensureNotificationHistoryLoadedForDoctor(updated.id);
      notifications.assignAll(_buildNotifications(updated));
      Get.snackbar('Profile Updated', successMessage);
    } finally {
      loading.value = false;
    }
  }

  Future<void> refreshAppointments({
    bool silent = false,
    bool refreshLocationAfter = true,
  }) async {
    final currentProfile = profile.value;
    if (currentProfile == null) return;

    try {
      if (!silent) {
        appointmentLoading.value = true;
      }
      final list = await _apiService.fetchDoctorAppointments(doctorId: currentProfile.id);
      appointments.assignAll(list);
      await _refreshAppointmentDistanceLabels();
      final liveIds = list.map((item) => item.id).toSet();
      otpRequestedAppointmentIds.removeWhere((id) => !liveIds.contains(id));
      for (final item in list) {
        if (item.otpVerifiedAt != null) {
          otpRequestedAppointmentIds.remove(item.id);
        }
      }
    } catch (_) {
      // Keep last real API state; never inject demo data.
    } finally {
      if (!silent) {
        appointmentLoading.value = false;
      }
      if (refreshLocationAfter && profile.value?.isActiveForAppointments == true) {
        _refreshCurrentLocation();
      }
    }
  }

  Future<void> _refreshCurrentLocation({bool syncBackend = false}) async {
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
      currentDoctorLatitude.value = pos.latitude;
      currentDoctorLongitude.value = pos.longitude;
      await _refreshAppointmentDistanceLabels();
      if (syncBackend && profile.value?.isActiveForAppointments == true) {
        _lastSyncedDoctorPoint = _GeoPoint(pos.latitude, pos.longitude);
        await _syncDoctorLiveLocation(pos.latitude, pos.longitude);
        await _pushLiveLocationForActiveAppointmentsFrom(
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
      }
    } catch (_) {}
  }

  Future<void> _refreshAppointmentDistanceLabels() async {
    final doctorLat = currentDoctorLatitude.value;
    final doctorLng = currentDoctorLongitude.value;
    if (doctorLat == null || doctorLng == null) return;

    final next = <int, String>{};
    for (final appointment in appointments) {
      next[appointment.id] = _distanceFromFarmerCoordinates(
        doctorLat: doctorLat,
        doctorLng: doctorLng,
        farmerLat: appointment.latitude,
        farmerLng: appointment.longitude,
      );
    }
    appointmentDistanceLabels.assignAll(next);
  }

  String _distanceFromFarmerCoordinates({
    required double doctorLat,
    required double doctorLng,
    required double? farmerLat,
    required double? farmerLng,
  }) {
    if (farmerLat == null || farmerLng == null) return '--';

    try {
      final meters = Geolocator.distanceBetween(
        doctorLat,
        doctorLng,
        farmerLat,
        farmerLng,
      );
      return _formatDistance(meters);
    } catch (_) {
      return '--';
    }
  }

  String _formatDistance(double meters) {
    final absMeters = meters.abs();
    if (absMeters < 0.01) {
      return '${(absMeters * 1000).toStringAsFixed(2)} mm';
    }
    if (absMeters < 1.0) {
      return '${(absMeters * 100).toStringAsFixed(2)} cm';
    }
    if (absMeters < 1000) {
      return '${absMeters.toStringAsFixed(2)} m';
    }
    return '${(absMeters / 1000).toStringAsFixed(2)} km';
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

      _firebaseMessagingService.foregroundMessageStream().listen(
        (message) => _handleRemoteMessage(message, triggerAppointmentAlert: true),
      );
      _firebaseMessagingService.messageOpenedAppStream().listen(
        (message) => _handleRemoteMessage(message),
      );

      final initialMessage = await _firebaseMessagingService.getInitialMessage();
      if (initialMessage != null) {
        _handleRemoteMessage(initialMessage);
      }
    } catch (_) {}
  }

  void _handleRemoteMessage(
    RemoteMessage message, {
    bool triggerAppointmentAlert = false,
  }) {
    final title = _resolveNotificationTitle(message);
    final body = _resolveNotificationBody(message);

    final finalTitle = title?.isNotEmpty == true
        ? title!
        : (message.data['event']?.toString().trim().isNotEmpty == true
            ? message.data['event']!.toString().trim()
            : 'Notification');
    final finalBody = body?.isNotEmpty == true ? body! : 'You have a new update.';

    notifications.insert(0, '$finalTitle: $finalBody');
    _addNotificationEntry(
      title: finalTitle,
      body: finalBody,
    );

    Get.snackbar(
      finalTitle,
      finalBody,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );

    if (triggerAppointmentAlert &&
        NotificationAlertService.isNewAppointmentRequest(
          title: finalTitle,
          body: finalBody,
          data: message.data,
        )) {
      unawaited(NotificationAlertService.playFor20Seconds());
    }

    refreshProfile();
    refreshAppointments();
  }

  String? _resolveNotificationTitle(RemoteMessage message) {
    final fromNotification = message.notification?.title?.trim();
    if (fromNotification != null && fromNotification.isNotEmpty) {
      return fromNotification;
    }

    final fromData = message.data['title']?.toString().trim();
    if (fromData != null && fromData.isNotEmpty) {
      return fromData;
    }

    final altFromData = message.data['notification_title']?.toString().trim();
    if (altFromData != null && altFromData.isNotEmpty) {
      return altFromData;
    }

    final fromMessage = message.data['message']?.toString().trim();
    if (fromMessage != null && fromMessage.isNotEmpty) {
      return 'Notification';
    }

    return null;
  }

  String? _resolveNotificationBody(RemoteMessage message) {
    var body = message.notification?.body?.trim();
    if (body == null || body.isEmpty) {
      final fromData = message.data['body']?.toString().trim();
      if (fromData != null && fromData.isNotEmpty) {
        body = fromData;
      }
    }

    if (body == null || body.isEmpty) {
      final altFromData = message.data['notification_body']?.toString().trim();
      if (altFromData != null && altFromData.isNotEmpty) {
        body = altFromData;
      }
    }

    if (body == null || body.isEmpty) {
      final fromMessage = message.data['message']?.toString().trim();
      if (fromMessage != null && fromMessage.isNotEmpty) {
        body = fromMessage;
      }
    }

    final otp = message.data['visit_otp']?.toString().trim().isNotEmpty == true
        ? message.data['visit_otp']!.toString().trim()
        : (message.data['otp']?.toString().trim().isNotEmpty == true
            ? message.data['otp']!.toString().trim()
            : '');
    if (otp.isNotEmpty) {
      final otpLine = 'Visit OTP: $otp';
      if (body == null || body.isEmpty) {
        body = otpLine;
      } else if (!body.contains(otp)) {
        body = '$body\n$otpLine';
      }
    }

    return body;
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
        sendOtp: false,
      );
      await refreshAppointments();
      Get.snackbar('Accepted', 'Appointment accepted successfully.');
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

  Future<bool> markAppointmentCompleted(
    DoctorAppointment appointment, {
    double? fees,
    double? onSiteMedicineCharges,
  }) async {
    final resolvedFees = fees ?? appointment.fees ?? 0;
    final resolvedOnsite = onSiteMedicineCharges ?? appointment.onSiteMedicineCharges ?? 0;
    final total = resolvedFees + resolvedOnsite;
    try {
      await _apiService.completeAppointment(
        appointmentId: appointment.id,
        charges: total,
        fees: resolvedFees,
        onSiteMedicineCharges: resolvedOnsite,
      );
      _upsertAppointment(
        appointment.copyWith(
          status: 'completed',
          charges: total,
          fees: resolvedFees,
          onSiteMedicineCharges: resolvedOnsite,
        ),
      );
      Get.snackbar('Visit Completed', 'Appointment marked as completed.');
      return true;
    } catch (_) {
      _upsertAppointment(
        appointment.copyWith(
          status: 'completed',
          charges: total,
          fees: resolvedFees,
          onSiteMedicineCharges: resolvedOnsite,
        ),
      );
      Get.snackbar('Saved In App', 'Marked as completed in app preview.');
      return false;
    }
  }

  Future<List<FarmerAnimalOption>> fetchContinuationAnimals({
    required int appointmentId,
  }) async {
    try {
      return await _apiService.fetchContinuationAnimals(appointmentId: appointmentId);
    } catch (e) {
      Get.snackbar('Load Failed', e.toString());
      return const [];
    }
  }

  Future<DoctorAppointment?> continueAppointmentWithAnimal({
    required int appointmentId,
    required int animalId,
  }) async {
    try {
      final response = await _apiService.continueAppointmentWithAnimal(
        appointmentId: appointmentId,
        animalId: animalId,
      );
      final map = response['data'];
      if (map is Map<String, dynamic>) {
        final appointment = DoctorAppointment.fromJson(map);
        _upsertAppointment(appointment);
        Get.snackbar('Ready', response['message']?.toString() ?? 'Next animal appointment created.');
        return appointment;
      }
      Get.snackbar('Ready', response['message']?.toString() ?? 'Next animal appointment created.');
      await refreshAppointments();
      return null;
    } catch (e) {
      Get.snackbar('Continue Failed', e.toString());
      return null;
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
      otpRequestedAppointmentIds.remove(appointment.id);

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
        sendOtp: true,
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
      otpRequestedAppointmentIds.add(appointment.id);

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
    String? notes,
  }) async {
    try {
      final response = await _apiService.saveTreatment(
        appointmentId: appointment.id,
        treatmentDetails: treatmentDetails,
        notes: notes,
      );

      final map = response['data'];
      if (map is Map<String, dynamic>) {
        _upsertAppointment(DoctorAppointment.fromJson(map));
      } else {
        _upsertAppointment(
          appointment.copyWith(
            treatmentDetails: treatmentDetails,
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
    _refreshAppointmentDistanceLabels();
  }

  Future<void> clearNotificationHistory() async {
    notificationHistory.clear();
    await _saveNotificationHistory();
  }

  Future<void> _ensureNotificationHistoryLoadedForDoctor(int doctorId) async {
    if (_loadedNotificationDoctorId == doctorId) return;
    await _loadNotificationHistory(doctorId: doctorId);
  }

  Future<void> _loadNotificationHistory({int? doctorId}) async {
    final resolvedDoctorId = doctorId ?? profile.value?.id ?? SessionService.profile?.id ?? 0;

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<DoctorNotificationItem> fromStore = [];

      void parseRaw(String? raw) {
        if (raw == null || raw.trim().isEmpty) return;
        final decoded = jsonDecode(raw);
        if (decoded is! List) return;
        fromStore.addAll(
          decoded
              .whereType<Map>()
              .map((row) => row.map((k, v) => MapEntry(k.toString(), v)))
              .map(DoctorNotificationItem.fromJson),
        );
      }

      if (resolvedDoctorId > 0) {
        parseRaw(prefs.getString(_notificationStoreKey(resolvedDoctorId)));
      }
      parseRaw(prefs.getString(_globalNotificationStoreKey));

      fromStore.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notificationHistory.assignAll(fromStore.take(100).toList());
      _loadedNotificationDoctorId = resolvedDoctorId > 0 ? resolvedDoctorId : null;
    } catch (_) {
      notificationHistory.clear();
      _loadedNotificationDoctorId = resolvedDoctorId > 0 ? resolvedDoctorId : null;
    }
  }

  Future<void> _saveNotificationHistory() async {
    final resolvedDoctorId = profile.value?.id ?? SessionService.profile?.id ?? _loadedNotificationDoctorId ?? 0;

    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = notificationHistory.map((item) => item.toJson()).toList();
      final encoded = jsonEncode(payload);
      if (resolvedDoctorId > 0) {
        await prefs.setString(_notificationStoreKey(resolvedDoctorId), encoded);
        _loadedNotificationDoctorId = resolvedDoctorId;
      }
      await prefs.setString(_globalNotificationStoreKey, encoded);
    } catch (_) {}
  }

  Future<void> confirmAndToggleAvailability() async {
    final current = profile.value;
    if (current == null) return;

    final nextActive = !current.isActiveForAppointments;
    final title = nextActive ? 'Set Active' : 'Set Inactive';
    final message = nextActive
        ? 'Are you want to active for appointments?'
        : 'Are you want to inactive for appointments?';

    final confirmed = await Get.dialog<bool>(
          AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                child: Text(nextActive ? 'Active' : 'Inactive'),
              ),
            ],
          ),
          barrierDismissible: true,
        ) ??
        false;

    if (!confirmed) return;

    try {
      final updated = await _apiService.updateDoctorAvailability(
        doctorId: current.id,
        isActive: nextActive,
      );
      profile.value = updated;
      await SessionService.saveProfile(updated);
      notifications.assignAll(_buildNotifications(updated));
      _syncLiveTrackingForAvailability();
      if (nextActive) {
        await _refreshCurrentLocation(syncBackend: true);
      }
      Get.snackbar(
        'Status Updated',
        nextActive ? 'You are active for appointments.' : 'You are inactive for appointments.',
      );
    } catch (e) {
      Get.snackbar('Update Failed', e.toString());
    }
  }

  void _syncLiveTrackingForAvailability() {
    final active = profile.value?.isActiveForAppointments == true;
    if (!active) {
      _doctorLocationSubscription?.cancel();
      _doctorLocationSubscription = null;
      _lastSyncedDoctorPoint = null;
      return;
    }

    if (_doctorLocationSubscription != null) return;

    _doctorLocationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      ),
    ).listen((position) {
      _handleDoctorPosition(position);
    });

    _refreshCurrentLocation(syncBackend: true);
  }

  Future<void> _handleDoctorPosition(Position position) async {
    currentDoctorLatitude.value = position.latitude;
    currentDoctorLongitude.value = position.longitude;
    await _refreshAppointmentDistanceLabels();

    final currentPoint = _GeoPoint(position.latitude, position.longitude);
    if (_lastSyncedDoctorPoint != null) {
      final moved = Geolocator.distanceBetween(
        _lastSyncedDoctorPoint!.latitude,
        _lastSyncedDoctorPoint!.longitude,
        currentPoint.latitude,
        currentPoint.longitude,
      );
      if (moved < 95) {
        return;
      }
    }

    _lastSyncedDoctorPoint = currentPoint;
    await _syncDoctorLiveLocation(position.latitude, position.longitude);
    await _pushLiveLocationForActiveAppointmentsFrom(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<void> _syncDoctorLiveLocation(double latitude, double longitude) async {
    final current = profile.value;
    if (current == null || !current.isActiveForAppointments) return;

    try {
      final updated = await _apiService.updateDoctorLiveLocation(
        doctorId: current.id,
        latitude: latitude,
        longitude: longitude,
      );
      profile.value = updated;
      await SessionService.saveProfile(updated);
    } catch (_) {}
  }

  Future<void> _pushLiveLocationForActiveAppointmentsFrom({
    required double latitude,
    required double longitude,
  }) async {
    if (profile.value?.isActiveForAppointments != true) return;
    final active = appointments.where((a) => a.canNavigate).toList();
    if (active.isEmpty) return;

    for (final appointment in active) {
      await updateAppointmentLiveLocation(
        appointment: appointment,
        latitude: latitude,
        longitude: longitude,
      );
    }
  }

  void _addNotificationEntry({
    required String title,
    required String body,
  }) {
    final cleanTitle = title.trim().isEmpty ? 'Notification' : title.trim();
    final cleanBody = body.trim().isEmpty ? 'You have a new update.' : body.trim();

    notificationHistory.insert(
      0,
      DoctorNotificationItem(
        title: cleanTitle,
        body: cleanBody,
        createdAt: DateTime.now(),
      ),
    );

    if (notificationHistory.length > 100) {
      notificationHistory.removeRange(100, notificationHistory.length);
    }

    _saveNotificationHistory();
  }

  String _notificationStoreKey(int doctorId) => 'doctor_notification_history_$doctorId';

  Future<void> logout() async {
    _profileSyncTimer?.cancel();
    _doctorLocationSubscription?.cancel();
    await SessionService.logout();
    Get.offAllNamed(AppRoutes.login);
  }
}

class _GeoPoint {
  const _GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

class DoctorNotificationItem {
  DoctorNotificationItem({
    required this.title,
    required this.body,
    required this.createdAt,
  });

  final String title;
  final String body;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DoctorNotificationItem.fromJson(Map<String, dynamic> json) {
    final rawTime = (json['created_at'] ?? '').toString().trim();
    final parsedTime = DateTime.tryParse(rawTime) ?? DateTime.now();

    return DoctorNotificationItem(
      title: (json['title'] ?? 'Notification').toString(),
      body: (json['body'] ?? '').toString(),
      createdAt: parsedTime,
    );
  }
}

