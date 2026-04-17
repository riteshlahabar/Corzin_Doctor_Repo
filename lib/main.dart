import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app/app.dart';
import 'app/core/services/firebase_messaging_service.dart';
import 'app/core/services/session_service.dart';

@pragma('vm:entry-point')
Future<void> _doctorFirebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final title = message.notification?.title?.trim().isNotEmpty == true
      ? message.notification!.title!.trim()
      : (message.data['title']?.toString().trim().isNotEmpty == true
          ? message.data['title']!.toString().trim()
          : (message.data['event']?.toString().trim().isNotEmpty == true
              ? message.data['event']!.toString().trim()
              : 'Notification'));
  final body = message.notification?.body?.trim().isNotEmpty == true
      ? message.notification!.body!.trim()
      : (message.data['body']?.toString().trim().isNotEmpty == true
          ? message.data['body']!.toString().trim()
          : (message.data['message']?.toString().trim().isNotEmpty == true
              ? message.data['message']!.toString().trim()
              : 'You have a new update.'));

  await FirebaseMessagingService.persistGlobalNotification(
    title: title,
    body: body,
    type: message.data['type']?.toString() ?? '',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_doctorFirebaseBackgroundHandler);
  await SessionService.init();
  runApp(const CorzinDoctorApp());
}
