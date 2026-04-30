import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/widgets/bottom_navigation_bar.dart';
import '../../routes/app_pages.dart';
import '../appointments/appointments_tab.dart';
import '../dashboard/dashboard_tab.dart';
import '../profile/profile_tab.dart';
import '../visits/visits_tab.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.appReady.value) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final profile = controller.profile.value;
      if (profile == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.currentRoute == AppRoutes.home) {
            Get.offAllNamed(AppRoutes.login);
          }
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      final pages = <Widget>[
        DashboardTab(controller: controller),
        AppointmentsTab(controller: controller),
        VisitsTab(controller: controller),
        ProfileTab(controller: controller),
      ];

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          final handled = controller.handlePostLoginBackPress();
          if (!handled) {
            SystemNavigator.pop();
          }
        },
        child: Scaffold(
          body: IndexedStack(
            index: controller.selectedIndex.value,
            children: pages,
          ),
          bottomNavigationBar: DoctorBottomNavigationBar(
            currentIndex: controller.selectedIndex.value,
            onChanged: (tab) {
              switch (tab) {
                case BottomBarTab.home:
                  controller.selectedIndex.value = 0;
                  break;
                case BottomBarTab.appointment:
                  controller.selectedIndex.value = 1;
                  break;
                case BottomBarTab.visits:
                  controller.selectedIndex.value = 2;
                  break;
                case BottomBarTab.profile:
                  controller.selectedIndex.value = 3;
                  break;
              }
            },
          ),
        ),
      );
    });
  }
}
