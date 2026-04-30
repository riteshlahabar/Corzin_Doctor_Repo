import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class NotificationAlertService {
  static const MethodChannel _toneChannel = MethodChannel('doctor_corzin/alert_tone');
  static const String _doctorProfileStoreKey = 'doctor_profile';
  static Timer? _alertTimer;
  static DateTime? _lastTriggerAt;

  static bool isNewAppointmentRequest({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    final type = (data['type'] ?? '').toString().toLowerCase();
    final event = (data['event'] ?? '').toString().toLowerCase();
    final status = (data['status'] ?? '').toString().toLowerCase();
    final subject = '$title $body'.toLowerCase();

    // Ring only for fresh appointment request notifications.
    if (event == 'appointment_created') {
      return true;
    }

    if (type == 'doctor_appointment' && status == 'pending' && subject.contains('new appointment request')) {
      return true;
    }

    return false;
  }

  static Future<bool> shouldPlayForMessage({
    required String title,
    required String body,
    required Map<String, dynamic> data,
    int? currentDoctorId,
  }) async {
    if (!isNewAppointmentRequest(title: title, body: body, data: data)) {
      return false;
    }

    final payloadDoctorId = int.tryParse((data['doctor_id'] ?? '').toString().trim());
    if (payloadDoctorId == null || payloadDoctorId <= 0) {
      return true;
    }

    final activeDoctorId = currentDoctorId ?? await _readLoggedInDoctorId();
    if (activeDoctorId == null || activeDoctorId <= 0) {
      return false;
    }

    return payloadDoctorId == activeDoctorId;
  }

  static Future<int?> _readLoggedInDoctorId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_doctorProfileStoreKey);
      if (raw == null || raw.trim().isEmpty) {
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return int.tryParse(decoded['id']?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  static Future<void> playFor20Seconds() async {
    final now = DateTime.now();
    if (_lastTriggerAt != null &&
        now.difference(_lastTriggerAt!) < const Duration(seconds: 3)) {
      return;
    }
    _lastTriggerAt = now;

    stop();

    final startedUniqueTone = await _startUniqueTone();
    if (!startedUniqueTone) {
      // Fallback for background isolate / missing method-channel registration.
      FlutterRingtonePlayer().play(
        android: AndroidSounds.alarm,
        ios: IosSounds.glass,
        looping: true,
        volume: 1.0,
        asAlarm: true,
      );
    }

    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) {
      await Vibration.vibrate(
        pattern: const [0, 600, 320],
        repeat: 0,
      );
    }

    _alertTimer = Timer(const Duration(seconds: 20), stop);
  }

  static Future<bool> _startUniqueTone() async {
    try {
      final started = await _toneChannel.invokeMethod<bool>('startUniqueTone');
      return started == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _stopUniqueTone() async {
    try {
      await _toneChannel.invokeMethod('stopUniqueTone');
    } catch (_) {}
  }

  static void stop() {
    _alertTimer?.cancel();
    _alertTimer = null;
    unawaited(_stopUniqueTone());
    FlutterRingtonePlayer().stop();
    Vibration.cancel();
  }
}
