import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';

class NotificationAlertService {
  static const MethodChannel _toneChannel = MethodChannel('doctor_corzin/alert_tone');
  static Timer? _alertTimer;
  static DateTime? _lastTriggerAt;

  static bool isNewAppointmentRequest({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    final type = (data['type'] ?? '').toString().toLowerCase();
    final event = (data['event'] ?? '').toString().toLowerCase();
    final subject = '$title $body'.toLowerCase();

    if (type.contains('appointment') || event.contains('appointment')) {
      return true;
    }

    return subject.contains('appointment');
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
      await _toneChannel.invokeMethod('startUniqueTone');
      return true;
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
