import 'package:get/get.dart';

import '../../core/services/session_service.dart';
import '../../routes/app_pages.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    Future.delayed(const Duration(seconds: 5), () {
      if (isClosed) return;
      Get.offAllNamed(
        SessionService.isLoggedIn ? AppRoutes.home : AppRoutes.login,
      );
    });
  }
}
