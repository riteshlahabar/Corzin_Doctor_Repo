import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/models/doctor_appointment.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_controller.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({
    super.key,
    required this.controller,
  });

  final HomeController controller;

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final PageController _bannerController = PageController(viewportFraction: 0.88);
  int _bannerIndex = 0;

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list = widget.controller.appointments.isEmpty ? _demoAppointments() : widget.controller.appointments.toList();
      final now = DateTime.now();

      bool sameDay(DateTime a, DateTime b) {
        return a.year == b.year && a.month == b.month && a.day == b.day;
      }

      final todayVisits = list.where((item) {
        final slot = (item.scheduledAt ?? item.requestedAt)?.toLocal();
        return slot != null && sameDay(slot, now);
      }).length;

      final completed = list.where((item) => item.normalizedStatus == 'completed').length;
      final pending = list.where((item) => item.canFixAppointment || item.waitingForFarmerApproval).length;
      final earnings = list.where((item) {
        final slot = item.scheduledAt?.toLocal();
        return slot != null && sameDay(slot, now) && item.normalizedStatus == 'completed';
      }).fold<double>(0, (sum, item) => sum + (item.charges ?? 0));

      final nextVisit = list
          .where((item) => item.canNavigate && item.scheduledAt != null)
          .toList()
        ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));

      final recentRequests = list.where((item) => item.canFixAppointment).take(3).toList();
      final backendBanners = widget.controller.banners;
      final bannerData = backendBanners.isEmpty
          ? const [
              _BannerData(
                image: 'assets/images/app_icon.jpg',
                isNetwork: false,
              ),
              _BannerData(
                image: 'assets/images/logo.png',
                isNetwork: false,
              ),
            ]
          : backendBanners
              .map(
                (item) => _BannerData(
                  image: item.imageUrl.isNotEmpty ? item.imageUrl : item.imagePath,
                  isNetwork: item.imageUrl.isNotEmpty || item.imagePath.startsWith('http'),
                ),
              )
              .toList();

      if (_bannerIndex >= bannerData.length && bannerData.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _bannerIndex = 0;
          });
        });
      }

      return RefreshIndicator(
        onRefresh: () async {
          await widget.controller.refreshProfile();
          await widget.controller.refreshAppointments();
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 18),
          children: [
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: EdgeInsets.fromLTRB(
                18,
                MediaQuery.of(context).padding.top + 10,
                18,
                12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Hi ${widget.controller.profile.value?.firstName.isNotEmpty == true ? widget.controller.profile.value!.firstName : 'Doctor'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => widget.controller.selectedIndex.value = 2,
                    child: Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.notifications_none_rounded, color: AppColors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.only(top: 14, bottom: 18),
              child: Column(
                children: [
                  SizedBox(
                    height: 138,
                    child: PageView.builder(
                      controller: _bannerController,
                      onPageChanged: (value) => setState(() => _bannerIndex = value),
                      itemCount: bannerData.length,
                      itemBuilder: (context, index) => _BannerCard(
                        image: bannerData[index].image,
                        isNetwork: bannerData[index].isNetwork,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(bannerData.length, (index) {
                      final selected = _bannerIndex == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: selected ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.black : AppColors.black.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            _SectionCard(
              title: 'Today Snapshot',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _SmallInfoCard(title: 'Today Visits', value: '$todayVisits')),
                      const SizedBox(width: 10),
                      Expanded(child: _SmallInfoCard(title: 'Pending', value: '$pending')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _SmallInfoCard(title: 'Completed', value: '$completed')),
                      const SizedBox(width: 10),
                      Expanded(child: _SmallInfoCard(title: 'Earnings', value: 'Rs ${earnings.toStringAsFixed(0)}')),
                    ],
                  ),
                ],
              ),
            ),
            _SectionCard(
              title: 'Next Visit',
              child: nextVisit.isEmpty
                  ? const Text(
                      'No approved visit scheduled.',
                      style: TextStyle(fontSize: 13, color: AppColors.grey),
                    )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4FAF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE4EFE4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${nextVisit.first.farmerName} - ${nextVisit.first.animalName}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM yyyy, hh:mm a').format(nextVisit.first.scheduledAt!.toLocal()),
                            style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nextVisit.first.address.isEmpty ? 'Farmer location will appear here.' : nextVisit.first.address,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => widget.controller.openNavigation(nextVisit.first),
                                  icon: const Icon(Icons.map_outlined, size: 16),
                                  label: const Text('Map'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => widget.controller.selectedIndex.value = 2,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.white,
                                  ),
                                  child: const Text('Open Visits'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
            _SectionCard(
              title: 'Recent Appointment Requests',
              child: recentRequests.isEmpty
                  ? const Text(
                      'No new request at this time.',
                      style: TextStyle(fontSize: 13, color: AppColors.grey),
                    )
                  : Column(
                      children: recentRequests
                          .map(
                            (item) => Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4FAF4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE4EFE4)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.farmerName,
                                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.concern,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12, color: AppColors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => widget.controller.selectedIndex.value = 1,
                                    child: const Text(
                                      'Fix Slot',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      );
    });
  }

  List<DoctorAppointment> _demoAppointments() {
    final now = DateTime.now();
    return [
      DoctorAppointment(
        id: 9001,
        farmerName: 'Ramesh Patil',
        animalName: 'Cow - Gauri',
        concern: 'High fever and low appetite',
        status: 'pending',
        animalPhotoUrl: 'assets/images/available_doctor_1st.png',
        requestedAt: now.subtract(const Duration(hours: 3)),
        address: 'Karad, Satara',
      ),
      DoctorAppointment(
        id: 9002,
        farmerName: 'Sunita Jadhav',
        animalName: 'Buffalo - Laxmi',
        concern: 'Post treatment check-up',
        status: 'approved',
        animalPhotoUrl: 'assets/images/available_doctor_2nd.png',
        requestedAt: now.subtract(const Duration(days: 1)),
        scheduledAt: now.add(const Duration(hours: 2)),
        charges: 650,
        latitude: 17.2890,
        longitude: 74.1818,
        address: 'Sangli, Maharashtra',
      ),
      DoctorAppointment(
        id: 9003,
        farmerName: 'Mahesh Shinde',
        animalName: 'Goat - Pari',
        concern: 'Deworming follow-up',
        status: 'completed',
        animalPhotoUrl: 'assets/images/available_doctor_1st.png',
        requestedAt: now.subtract(const Duration(days: 1, hours: 6)),
        scheduledAt: now.subtract(const Duration(hours: 2)),
        completedAt: now.subtract(const Duration(minutes: 40)),
        charges: 400,
        address: 'Tasgaon, Sangli',
      ),
    ];
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.image,
    required this.isNetwork,
  });

  final String image;
  final bool isNetwork;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFFEAF5EA),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: isNetwork
              ? Image.network(
                  image,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.expand(),
                )
              : Image.asset(
                  image,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.expand(),
                ),
        ),
      ),
    );
  }
}

class _BannerData {
  const _BannerData({
    required this.image,
    required this.isNetwork,
  });

  final String image;
  final bool isNetwork;
}

class _SmallInfoCard extends StatelessWidget {
  const _SmallInfoCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4EFE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
