import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app/app.dart';
import 'app/core/services/doctor_location_background_service.dart';
import 'app/core/services/firebase_messaging_service.dart';
import 'app/core/services/notification_alert_service.dart';
import 'app/core/services/session_service.dart';

@pragma('vm:entry-point')
Future<void> _doctorFirebaseBackgroundHandler(RemoteMessage message) async {
  ui.DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp();
  final title = message.notification?.title?.trim().isNotEmpty == true
      ? message.notification!.title!.trim()
      : (message.data['title']?.toString().trim().isNotEmpty == true
          ? message.data['title']!.toString().trim()
          : (message.data['event']?.toString().trim().isNotEmpty == true
              ? message.data['event']!.toString().trim()
              : ''));
  final body = message.notification?.body?.trim().isNotEmpty == true
      ? message.notification!.body!.trim()
      : (message.data['body']?.toString().trim().isNotEmpty == true
          ? message.data['body']!.toString().trim()
          : (message.data['message']?.toString().trim().isNotEmpty == true
              ? message.data['message']!.toString().trim()
              : ''));

  if (title.isNotEmpty || body.isNotEmpty) {
    await FirebaseMessagingService.persistGlobalNotification(
      title: title,
      body: body,
      type: message.data['type']?.toString() ?? '',
    );
  }

  if (NotificationAlertService.isAppointmentClosedByOtherDoctor(
    title: title,
    body: body,
    data: message.data,
  )) {
    await NotificationAlertService.stop();
    return;
  }

  final shouldPlayAlert = await NotificationAlertService.shouldPlayForMessage(
    title: title,
    body: body,
    data: message.data,
  );
  if (shouldPlayAlert) {
    await NotificationAlertService.playFor20Seconds();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_doctorFirebaseBackgroundHandler);
  await SessionService.init();
  await DoctorLocationBackgroundService.initialize();
  runApp(const CorzinDoctorApp());
}
