import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/api_constants.dart';
import '../models/doctor_profile.dart';

class DoctorLocationBackgroundService {
  static const MethodChannel _channel = MethodChannel('doctor_corzin/live_location_service');

  static Future<void> initialize() async {}

  static Future<void> syncWithDoctorState(DoctorProfile? profile) async {
    if (profile?.isActiveForAppointments == true) {
      final canRunInBackground = await _hasBackgroundLocationAccess();
      if (!canRunInBackground) {
        await stop();
        return;
      }
      await start(profile!);
      return;
    }

    await stop();
  }

  static Future<void> start(DoctorProfile profile) async {
    try {
      await _channel.invokeMethod<bool>('start', {
        'doctorId': profile.id,
        'baseUrl': ApiConstants.baseUrl,
      });
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod<bool>('stop');
    } catch (_) {}
  }

  static Future<bool> _hasBackgroundLocationAccess() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }
}
