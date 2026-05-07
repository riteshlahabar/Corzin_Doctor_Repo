import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/doctor_profile.dart';

class SessionService {
  static late SharedPreferences _prefs;
  static const String _doctorProfileKey = 'doctor_profile';
  static const String _lastLoginEmailKey = 'doctor_last_login_email';
  static const String _pendingReferralCodeKey = 'doctor_pending_referral_code';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get isLoggedIn => _prefs.getString(_doctorProfileKey) != null;

  static DoctorProfile? get profile {
    final raw = _prefs.getString(_doctorProfileKey);
    if (raw == null) return null;
    return DoctorProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static String get lastLoginEmail => _prefs.getString(_lastLoginEmailKey) ?? '';
  static String get pendingReferralCode => _prefs.getString(_pendingReferralCodeKey) ?? '';

  static Future<void> saveLastLoginEmail(String email) async {
    final value = email.trim();
    if (value.isEmpty) return;
    await _prefs.setString(_lastLoginEmailKey, value);
  }

  static Future<void> saveProfile(DoctorProfile profile) async {
    await _prefs.setString(_doctorProfileKey, jsonEncode(profile.toJson()));
    await saveLastLoginEmail(profile.email);
  }

  static Future<void> savePendingReferralCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return;
    await _prefs.setString(_pendingReferralCodeKey, normalized);
  }

  static Future<void> clearPendingReferralCode() async {
    await _prefs.remove(_pendingReferralCodeKey);
  }

  static Future<void> logout() async {
    await _prefs.remove(_doctorProfileKey);
  }
}
