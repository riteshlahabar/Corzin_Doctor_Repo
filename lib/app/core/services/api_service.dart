import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/doctor_appointment.dart';
import '../models/doctor_profile.dart';
import '../models/doctor_settings.dart';

class ApiService {
  final http.Client _client = http.Client();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}/doctor/login'),
      headers: {'Accept': 'application/json'},
      body: {
        'email': email,
        'password': password,
      },
    );

    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}/doctor/forgot-password'),
      headers: {'Accept': 'application/json'},
      body: {
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> register({
    required Map<String, String> fields,
    required Map<String, PlatformFile> files,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/doctor/register'),
    );
    request.headers['Accept'] = 'application/json';
    request.fields.addAll(fields);

    for (final entry in files.entries) {
      final path = entry.value.path;
      if (path != null && path.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(entry.key, path));
        continue;
      }

      final bytes = entry.value.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Missing file data for ${entry.key}');
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          entry.key,
          bytes,
          filename: entry.value.name,
        ),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _parseResponse(response);
  }

  Future<void> updateFcmToken({
    required int doctorId,
    required String token,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}/doctor/fcm-token/$doctorId'),
      headers: {'Accept': 'application/json'},
      body: {'fcm_token': token},
    );

    _parseResponse(response);
  }

  Future<DoctorProfile> fetchProfile(int doctorId) async {
    final response = await _client.get(
      Uri.parse('${ApiConstants.baseUrl}/doctor/profile/$doctorId'),
      headers: {'Accept': 'application/json'},
    );
    final body = _parseResponse(response);
    return DoctorProfile.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<DoctorProfile> updateDoctorProfile({
    required int doctorId,
    required Map<String, String> fields,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}/doctor/profile/$doctorId/update'),
      headers: {'Accept': 'application/json'},
      body: fields,
    );
    final body = _parseResponse(response);
    return DoctorProfile.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<DoctorAppointment>> fetchDoctorAppointments({
    required int doctorId,
  }) async {
    final response = await _client.get(
      Uri.parse('${ApiConstants.baseUrl}/doctor/appointments/$doctorId'),
      headers: {'Accept': 'application/json'},
    );
    final body = _parseResponse(response);
    final rawList = (body['data'] as List<dynamic>? ?? const []);
    return rawList
        .map((item) => DoctorAppointment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<DoctorSettings> fetchDoctorSettings() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/doctor/settings').replace(
      queryParameters: {
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      },
    );
    final body = _parseResponse(response);
    return DoctorSettings.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> proposeAppointment({
    required int appointmentId,
    required DateTime scheduledAt,
    required double charges,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}/doctor/appointments/$appointmentId/propose'),
      headers: {'Accept': 'application/json'},
      body: {
        'scheduled_at': scheduledAt.toIso8601String(),
        'charges': charges.toStringAsFixed(2),
      },
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> completeAppointment({
    required int appointmentId,
    String? notes,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}/doctor/appointments/$appointmentId/complete'),
      headers: {'Accept': 'application/json'},
      body: {
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> doctorDecision({
    required int appointmentId,
    required String action,
    DateTime? scheduledAt,
    double? charges,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}/doctor/appointments/$appointmentId/doctor-decision'),
      headers: {'Accept': 'application/json'},
      body: {
        'action': action,
        if (scheduledAt != null) 'scheduled_at': scheduledAt.toIso8601String(),
        if (charges != null) 'charges': charges.toStringAsFixed(2),
      },
    );
    return _parseResponse(response);
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw Exception(body['message'] ?? 'Request failed');
  }
}
