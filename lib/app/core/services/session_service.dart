import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/doctor_profile.dart';

class SessionService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get isLoggedIn => _prefs.getString('doctor_profile') != null;

  static DoctorProfile? get profile {
    final raw = _prefs.getString('doctor_profile');
    if (raw == null) return null;
    return DoctorProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> saveProfile(DoctorProfile profile) async {
    await _prefs.setString('doctor_profile', jsonEncode(profile.toJson()));
  }

  static Future<void> logout() async {
    await _prefs.remove('doctor_profile');
  }
}
