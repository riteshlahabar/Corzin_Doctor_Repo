import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/services/session_service.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_pages.dart';

class CorzinDoctorApp extends StatelessWidget {
  const CorzinDoctorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Corzin Doctor',
      theme: AppTheme.light(),
      initialRoute: SessionService.isLoggedIn ? AppRoutes.home : AppRoutes.login,
      getPages: AppPages.pages,
    );
  }
}
