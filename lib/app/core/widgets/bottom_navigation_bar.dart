import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum BottomBarTab {
  home,
  appointment,
  visits,
  profile,
}

class BottomMenuModel {
  const BottomMenuModel({
    required this.icon,
    required this.selectedIcon,
    required this.title,
    required this.type,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String title;
  final BottomBarTab type;
}

class DoctorBottomNavigationBar extends StatelessWidget {
  const DoctorBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<BottomBarTab> onChanged;

  final List<BottomMenuModel> bottomMenuList = const [
    BottomMenuModel(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      title: 'Home',
      type: BottomBarTab.home,
    ),
    BottomMenuModel(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month_rounded,
      title: 'Appointments',
      type: BottomBarTab.appointment,
    ),
    BottomMenuModel(
      icon: Icons.alt_route_rounded,
      selectedIcon: Icons.route_rounded,
      title: 'Visits',
      type: BottomBarTab.visits,
    ),
    BottomMenuModel(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      title: 'Profile',
      type: BottomBarTab.profile,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.09),
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        items: List.generate(bottomMenuList.length, (index) {
          final item = bottomMenuList[index];
          return BottomNavigationBarItem(
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  item.icon,
                  size: 22,
                  color: AppColors.black,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text(''),
                ),
              ],
            ),
            activeIcon: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  item.selectedIcon,
                  size: 22,
                  color: AppColors.primary,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    item.title,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            label: '',
          );
        }),
        onTap: (index) => onChanged(bottomMenuList[index].type),
      ),
    );
  }
}
