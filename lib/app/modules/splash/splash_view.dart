import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import 'splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Container(
        width: double.infinity,
        color: AppColors.white,
        child: SafeArea(
          child: Center(
            child: Image.asset(
              AppAssets.logo,
              height: 60,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
