export 'home_shell_view.dart';

/*
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/api_constants.dart';
import '../../core/models/doctor_appointment.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/bottom_navigation_bar.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.profile.value == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.currentRoute == '/home') {
            Get.offAllNamed('/login');
          }
        });
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final pages = [
        _DashboardTab(controller: controller),
        _AppointmentsTab(controller: controller),
        _VisitsTab(controller: controller),
        _ProfileTab(controller: controller),
      ];

      return Scaffold(
        body: pages[controller.selectedIndex.value],
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
      );
    });
  }
}
*/

/*
class _DashboardTab extends StatefulWidget {
  const _DashboardTab({required this.controller});

  final HomeController controller;

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _pageIndex = 0;

  final List<_BannerData> _banners = const [
    _BannerData(
      title: 'Book your consultation with trusted specialists.',
      image: AppAssets.appIcon,
    ),
    _BannerData(
      title: 'Regular checkups keep your clinic day stress-free.',
      image: AppAssets.logo,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveAppointments = widget.controller.appointments;
    final appointments = liveAppointments.isEmpty ? _demoAppointments : liveAppointments;
    final now = DateTime.now();

    bool isSameDay(DateTime first, DateTime second) {
      return first.year == second.year && first.month == second.month && first.day == second.day;
    }

    final todayVisits = appointments.where((item) {
      final at = (item.scheduledAt ?? item.requestedAt)?.toLocal();
      return at != null && isSameDay(at, now);
    }).length;
    final pendingApprovals = appointments.where((item) => item.waitingForFarmerApproval).length;
    final completed = appointments.where((item) => item.normalizedStatus == 'completed').length;
    final todayEarnings = appointments.where((item) {
      final at = item.scheduledAt?.toLocal();
      return item.normalizedStatus == 'completed' && item.charges != null && at != null && isSameDay(at, now);
    }).fold<double>(0, (sum, item) => sum + (item.charges ?? 0));

    final upcoming = appointments.where((item) => item.canNavigate && item.scheduledAt != null).toList()
      ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
    final nextVisit = upcoming.isNotEmpty ? upcoming.first : null;
    final recentRequests = appointments.where((item) => item.canFixAppointment).take(3).toList();

    final overduePending = appointments.where((item) {
      if (!item.canFixAppointment || item.requestedAt == null) return false;
      return now.difference(item.requestedAt!.toLocal()).inHours >= 4;
    }).length;
    final urgentAlerts = <String>[
      if (overduePending > 0) '$overduePending appointment request(s) are waiting more than 4 hours.',
      if (pendingApprovals > 0) '$pendingApprovals appointment(s) waiting for farmer approval.',
    ];
    if (urgentAlerts.isEmpty) {
      urgentAlerts.add('No urgent alerts right now.');
    }

    return RefreshIndicator(
      onRefresh: () async {
        await widget.controller.refreshProfile();
        await widget.controller.refreshAppointments();
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 10,
              20,
              12,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              border: Border(
                bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.75)),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Hi ${widget.controller.profile.value?.firstName.isNotEmpty == true ? widget.controller.profile.value!.firstName : 'Doctor'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.white,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => widget.controller.selectedIndex.value = 2,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 19,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _BannerSection(
            controller: widget.controller,
            pageController: _pageController,
            banners: _banners,
            pageIndex: _pageIndex,
            onPageChanged: (index) {
              setState(() {
                _pageIndex = index;
              });
            },
          ),
          const SizedBox(height: 8),
          _SectionCard(
            title: 'Today Snapshot',
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _InfoCard(title: 'Today Visits', value: '$todayVisits')),
                      const SizedBox(width: 12),
                      Expanded(child: _InfoCard(title: 'Pending Approvals', value: '$pendingApprovals')),
                    ],
                  ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _InfoCard(title: 'Completed', value: '$completed')),
                        const SizedBox(width: 12),
                        Expanded(child: _InfoCard(title: 'Today Earnings', value: '₹ ${todayEarnings.toStringAsFixed(0)}')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          _SectionCard(
            title: 'Next Visit',
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: nextVisit == null
                    ? const Text(
                        'No approved visit scheduled yet.',
                        style: TextStyle(fontSize: 13, color: AppColors.grey),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${nextVisit.farmerName} • ${nextVisit.animalName}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM yyyy, hh:mm a').format(nextVisit.scheduledAt!.toLocal()),
                            style: const TextStyle(fontSize: 13, color: AppColors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nextVisit.address.isEmpty ? 'Location will be shared by farmer.' : nextVisit.address,
                            style: const TextStyle(fontSize: 13, color: AppColors.grey),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => widget.controller.openNavigation(nextVisit),
                                  icon: const Icon(Icons.navigation_rounded, size: 18),
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
          ),
          _SectionCard(
            title: 'Urgent Alerts',
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                children: urgentAlerts
                    .map(
                      (alert) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5EA),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFFE4C2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.priority_high_rounded, color: Color(0xFFE08A00), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                alert,
                                style: const TextStyle(fontSize: 12.8, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          _SectionCard(
            title: 'Recent Appointment Requests',
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: recentRequests.isEmpty
                  ? const Text(
                      'No new requests right now.',
                      style: TextStyle(fontSize: 13, color: AppColors.grey),
                    )
                  : Column(
                      children: recentRequests
                          .map(
                            (item) => Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.line),
                              ),
                               child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.farmerName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.concern,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () => widget.controller.selectedIndex.value = 1,
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(0, 32),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    child: const Text(
                                      'Fix Slot',
                                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<DoctorAppointment> get _demoAppointments {
    final now = DateTime.now();
    return [
      DoctorAppointment(
        id: 1001,
        farmerName: 'Ramesh Patil',
        animalName: 'Cow - Gauri',
        concern: 'High fever and low appetite',
        status: 'pending',
        animalPhotoUrl: 'assets/images/available_doctor_1st.png',
        requestedAt: now.subtract(const Duration(hours: 5)),
        address: 'Karad, Satara',
      ),
      DoctorAppointment(
        id: 1002,
        farmerName: 'Sunita Jadhav',
        animalName: 'Buffalo - Laxmi',
        concern: 'Routine follow-up check',
        status: 'awaiting_farmer_approval',
        animalPhotoUrl: 'assets/images/available_doctor_2nd.png',
        requestedAt: now.subtract(const Duration(hours: 2)),
        scheduledAt: now.add(const Duration(hours: 4)),
        charges: 650,
        address: 'Sangli, Maharashtra',
      ),
      DoctorAppointment(
        id: 1003,
        farmerName: 'Akash More',
        animalName: 'Calf - Chintu',
        concern: 'Vaccination visit',
        status: 'approved',
        animalPhotoUrl: 'assets/images/available_doctor_1st.png',
        requestedAt: now.subtract(const Duration(days: 1)),
        scheduledAt: now.add(const Duration(hours: 1)),
        charges: 500,
        latitude: 17.2890,
        longitude: 74.1818,
        address: 'Kolhapur Road, Karad',
      ),
      DoctorAppointment(
        id: 1004,
        farmerName: 'Mahesh Shinde',
        animalName: 'Cow - Nandini',
        concern: 'Post treatment observation',
        status: 'in_progress',
        animalPhotoUrl: 'assets/images/available_doctor_2nd.png',
        requestedAt: now.subtract(const Duration(hours: 10)),
        scheduledAt: now.subtract(const Duration(minutes: 45)),
        charges: 700,
        address: 'Islampur, Sangli',
      ),
      DoctorAppointment(
        id: 1005,
        farmerName: 'Priya Chavan',
        animalName: 'Goat - Pari',
        concern: 'Deworming completed',
        status: 'completed',
        animalPhotoUrl: 'assets/images/available_doctor_1st.png',
        requestedAt: now.subtract(const Duration(days: 1, hours: 4)),
        scheduledAt: now.subtract(const Duration(hours: 2)),
        charges: 450,
        address: 'Tasgaon, Sangli',
      ),
    ];
  }

}

class _AppointmentsTab extends StatelessWidget {
  const _AppointmentsTab({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
        children: [
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 8,
              20,
              14,
            ),
            child: const Text(
              'My Appointments',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (controller.appointmentLoading.value)
            const Center(child: CircularProgressIndicator())
          else if (controller.appointments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _EmptyCard(message: 'No appointments available yet.'),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: controller.appointments
                    .map(
                      (appointment) => _MyAppointmentCard(
                        appointment: appointment,
                        onReschedule: () => _openFixAppointmentSheet(context, appointment),
                        onApprove: () => controller.approveAppointment(appointment),
                        onDecline: () => controller.declineAppointment(appointment),
                        onNavigate: () => controller.openNavigation(appointment),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      );
    });
  }

  Future<void> _openFixAppointmentSheet(BuildContext context, DoctorAppointment appointment) async {
    final chargesController = TextEditingController(
      text: appointment.charges != null ? appointment.charges!.toStringAsFixed(0) : '',
    );
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay.now();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + MediaQuery.of(context).viewInsets.bottom),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fix Appointment',
                    style: TextStyle(fontFamily: 'SF Pro Display', fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${appointment.farmerName} • ${appointment.animalName}',
                    style: const TextStyle(color: AppColors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                              initialDate: selectedDate,
                            );
                            if (picked != null) {
                              setModalState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_month_rounded),
                          label: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (picked != null) {
                              setModalState(() {
                                selectedTime = picked;
                              });
                            }
                          },
                          icon: const Icon(Icons.access_time_rounded),
                          label: Text(selectedTime.format(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: chargesController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Visit Charges',
                      prefixText: '₹ ',
                      hintText: 'Enter charges',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final charges = double.tryParse(chargesController.text.trim());
                        if (charges == null || charges <= 0) {
                          Get.snackbar('Invalid Charges', 'Please enter valid visit charges.');
                          return;
                        }

                        final scheduledAt = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );

                        Navigator.of(context).pop();
                        await controller.rescheduleAppointment(
                          appointment: appointment,
                          scheduledAt: scheduledAt,
                          charges: charges,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Reschedule'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _VisitsTab extends StatelessWidget {
  const _VisitsTab({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final visitList = controller.appointments
          .where((appointment) => appointment.canNavigate || appointment.normalizedStatus == 'completed')
          .toList();

      return ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
        children: [
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 8,
              20,
              14,
            ),
            child: const Text(
              'Visits',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (visitList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _EmptyCard(message: 'No visits available right now.'),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                  children: visitList
                      .map(
                        (appointment) => _VisitCard(
                          appointment: appointment,
                          onComplete: appointment.canComplete ? () => controller.markAppointmentCompleted(appointment) : null,
                        ),
                      )
                      .toList(),
              ),
            ),
        ],
      );
    });
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MyAppointmentCard extends StatelessWidget {
  const _MyAppointmentCard({
    required this.appointment,
    required this.onReschedule,
    required this.onApprove,
    required this.onDecline,
    required this.onNavigate,
  });

  final DoctorAppointment appointment;
  final VoidCallback onReschedule;
  final VoidCallback onApprove;
  final VoidCallback onDecline;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final date = appointment.scheduledAt ?? appointment.requestedAt;
    final dateLabel = date == null ? '--' : DateFormat('dd-MM-yyyy').format(date.toLocal());
    final title = appointment.farmerName.isEmpty ? 'Farmer Appointment' : appointment.farmerName;
    final subTitle = appointment.animalName.isEmpty ? appointment.concern : appointment.animalName;
    final amountLabel = appointment.charges == null ? 'Rs. --' : 'Rs. ${appointment.charges!.toStringAsFixed(0)}';
    final actionLabel = _actionText();
    final actionColor = _statusColor(appointment);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4EFE4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _appointmentPhoto(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      dateLabel,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subTitle.isEmpty ? '-' : subTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.black),
                ),
                const SizedBox(height: 4),
                Text(
                  amountLabel,
                  style: const TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (appointment.canFixAppointment)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onApprove,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size(0, 26),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            textStyle: const TextStyle(fontSize: 10.8, fontWeight: FontWeight.w700),
                          ),
                          child: const Text('Approved'),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onDecline,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFC0392B),
                            side: const BorderSide(color: Color(0xFFC0392B)),
                            minimumSize: const Size(0, 26),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            textStyle: const TextStyle(fontSize: 10.8, fontWeight: FontWeight.w700),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onReschedule,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFCA8A04),
                            side: const BorderSide(color: Color(0xFFCA8A04)),
                            minimumSize: const Size(0, 26),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            textStyle: const TextStyle(fontSize: 10.8, fontWeight: FontWeight.w700),
                          ),
                          child: const Text('Reschedule'),
                        ),
                      ),
                    ],
                  )
                else if (appointment.canNavigate)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: onNavigate,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.white,
                        side: const BorderSide(color: AppColors.primary, width: 1.2),
                      ),
                      icon: const Icon(Icons.navigation_rounded, color: AppColors.primary, size: 20),
                      tooltip: 'Open in Google Maps',
                    ),
                  )
                else
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: actionColor, width: 1.2),
                      ),
                      child: Text(
                        actionLabel,
                        style: TextStyle(
                          fontSize: 11.8,
                          fontWeight: FontWeight.w700,
                          color: actionColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _appointmentPhoto() {
    final photo = appointment.animalPhotoUrl.trim();
    if (photo.isNotEmpty) {
      if (photo.startsWith('http://') || photo.startsWith('https://')) {
        return Image.network(
          photo,
          height: 88,
          width: 88,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackPhoto(),
        );
      }
      if (photo.startsWith('assets/')) {
        return Image.asset(
          photo,
          height: 88,
          width: 88,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackPhoto(),
        );
      }

      final networkPath = '${ApiConstants.publicBaseUrl}/${photo.replaceFirst(RegExp(r'^/+'), '')}';
      return Image.network(
        networkPath,
        height: 88,
        width: 88,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackPhoto(),
      );
    }

    return _fallbackPhoto();
  }

  Widget _fallbackPhoto() {
    return Image.asset(
      'assets/images/available_doctor_1st.png',
      height: 88,
      width: 88,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: 88,
        width: 88,
        color: const Color(0xFFE5E7EB),
        child: const Icon(Icons.pets_rounded, color: AppColors.grey, size: 30),
      ),
    );
  }

  String _actionText() {
    if (appointment.normalizedStatus == 'declined' || appointment.normalizedStatus == 'rejected') return 'Declined';
    if (appointment.waitingForFarmerApproval) return 'Pending';
    if (appointment.normalizedStatus == 'rescheduled') return 'Rescheduled';
    if (appointment.canNavigate) return 'Approved';
    if (appointment.normalizedStatus == 'completed') return 'Completed';
    if (appointment.normalizedStatus == 'cancelled') return 'Cancelled';
    return appointment.statusLabel;
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.onFixAppointment,
    required this.onNavigate,
    required this.onComplete,
  });

  final DoctorAppointment appointment;
  final VoidCallback onFixAppointment;
  final VoidCallback onNavigate;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  appointment.farmerName.isEmpty ? 'Farmer Name' : appointment.farmerName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(appointment).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  appointment.statusLabel,
                  style: TextStyle(
                    color: _statusColor(appointment),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Animal: ${appointment.animalName.isEmpty ? '-' : appointment.animalName}',
            style: const TextStyle(fontSize: 13, color: AppColors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            'Concern: ${appointment.concern.isEmpty ? '-' : appointment.concern}',
            style: const TextStyle(fontSize: 13, color: AppColors.grey),
          ),
          if (appointment.scheduledAt != null) ...[
            const SizedBox(height: 2),
            Text(
              'Visit: ${DateFormat('dd MMM yyyy, hh:mm a').format(appointment.scheduledAt!.toLocal())}',
              style: const TextStyle(fontSize: 13, color: AppColors.grey),
            ),
          ],
          if (appointment.charges != null) ...[
            const SizedBox(height: 2),
            Text(
              'Charges: ₹ ${appointment.charges!.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 13, color: AppColors.grey),
            ),
          ],
          const SizedBox(height: 12),
          if (appointment.canFixAppointment)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onFixAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                ),
                child: const Text('Fix Appointment & Charges'),
              ),
            )
          else if (appointment.waitingForFarmerApproval)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F7F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: const Text(
                'Waiting for farmer approval',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.grey),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: appointment.canNavigate ? onNavigate : null,
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    label: const Text('Navigate'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: appointment.canComplete ? onComplete : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    child: const Text('Complete'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.appointment,
    this.onComplete,
  });

  final DoctorAppointment appointment;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final completedDate = appointment.completedAt ?? appointment.scheduledAt ?? appointment.requestedAt;
    final completedLabel = completedDate == null
        ? '--'
        : DateFormat('dd MMM yyyy, hh:mm a').format(completedDate.toLocal());
    final isCompleted = appointment.normalizedStatus == 'completed';
    final dateTitle = isCompleted ? 'Completed' : 'Visit';
    final statusLabelForVisitCard = isCompleted
        ? 'Done'
        : (appointment.normalizedStatus == 'approved' ? 'Visit' : appointment.statusLabel);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4EFE4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipOval(
            child: _visitPhoto(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.farmerName.isEmpty ? 'Farmer Name' : appointment.farmerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'SF Pro Display', fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  appointment.animalName.isEmpty ? appointment.concern : appointment.animalName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  appointment.address.isEmpty ? 'Location not available' : appointment.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFFE8F6EC) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabelForVisitCard,
                  style: TextStyle(
                    fontSize: 10.8,
                    fontWeight: FontWeight.w700,
                    color: isCompleted ? const Color(0xFF2E7D32) : AppColors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$dateTitle: $completedLabel',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 11.8, color: AppColors.grey),
              ),
              if (appointment.canComplete) ...[
                const SizedBox(height: 6),
                SizedBox(
                  height: 24,
                  child: ElevatedButton(
                    onPressed: onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(fontSize: 10.8, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Complete'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _visitPhoto() {
    final photo = appointment.animalPhotoUrl.trim();
    if (photo.isNotEmpty) {
      if (photo.startsWith('http://') || photo.startsWith('https://')) {
        return Image.network(
          photo,
          height: 56,
          width: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _visitFallbackPhoto(),
        );
      }
      if (photo.startsWith('assets/')) {
        return Image.asset(
          photo,
          height: 56,
          width: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _visitFallbackPhoto(),
        );
      }

      final networkPath = '${ApiConstants.publicBaseUrl}/${photo.replaceFirst(RegExp(r'^/+'), '')}';
      return Image.network(
        networkPath,
        height: 56,
        width: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _visitFallbackPhoto(),
      );
    }

    return _visitFallbackPhoto();
  }

  Widget _visitFallbackPhoto() {
    return Image.asset(
      'assets/images/available_doctor_1st.png',
      height: 56,
      width: 56,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: 56,
        width: 56,
        color: const Color(0xFFE5E7EB),
        child: const Icon(Icons.pets_rounded, color: AppColors.grey, size: 20),
      ),
    );
  }
}

Color _statusColor(DoctorAppointment appointment) {
  if (appointment.normalizedStatus == 'declined' || appointment.normalizedStatus == 'rejected') {
    return const Color(0xFFC0392B);
  }
  if (appointment.normalizedStatus == 'rescheduled') {
    return const Color(0xFFCA8A04);
  }
  if (appointment.waitingForFarmerApproval) return const Color(0xFFE09F00);
  if (appointment.canFixAppointment) return const Color(0xFFD35400);
  if (appointment.canNavigate) return AppColors.primary;
  if (appointment.statusLabel.toLowerCase().contains('completed')) return const Color(0xFF2E7D32);
  return AppColors.grey;
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab({required this.controller});

  final HomeController controller;

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  bool _showDoctorDetails = false;
  bool _isEditing = false;
  bool _isSaving = false;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _clinicNameController = TextEditingController();
  final TextEditingController _degreeController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _aadharNumberController = TextEditingController();
  final TextEditingController _panNumberController = TextEditingController();
  final TextEditingController _mmcRegNumberController = TextEditingController();
  final TextEditingController _clinicRegNumberController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _talukaController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _clinicAddressController = TextEditingController();

  @override
  void dispose() {
    for (final controller in [
      _firstNameController,
      _lastNameController,
      _clinicNameController,
      _degreeController,
      _contactNumberController,
      _emailController,
      _aadharNumberController,
      _panNumberController,
      _mmcRegNumberController,
      _clinicRegNumberController,
      _villageController,
      _cityController,
      _talukaController,
      _districtController,
      _stateController,
      _pincodeController,
      _clinicAddressController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncControllers(DoctorProfile profile) {
    _firstNameController.text = profile.firstName;
    _lastNameController.text = profile.lastName;
    _clinicNameController.text = profile.clinicName;
    _degreeController.text = profile.degree;
    _contactNumberController.text = profile.contactNumber;
    _emailController.text = profile.email;
    _aadharNumberController.text = profile.adharNumber;
    _panNumberController.text = profile.panNumber;
    _mmcRegNumberController.text = profile.mmcRegistrationNumber;
    _clinicRegNumberController.text = profile.clinicRegistrationNumber;
    _villageController.text = profile.village;
    _cityController.text = profile.city;
    _talukaController.text = profile.taluka;
    _districtController.text = profile.district;
    _stateController.text = profile.state;
    _pincodeController.text = profile.pincode;
    _clinicAddressController.text = profile.clinicAddress;
  }

  Map<String, String> _buildPayload() {
    return {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'clinic_name': _clinicNameController.text.trim(),
      'degree': _degreeController.text.trim(),
      'contact_number': _contactNumberController.text.trim(),
      'email': _emailController.text.trim(),
      'adhar_number': _aadharNumberController.text.trim(),
      'pan_number': _panNumberController.text.trim(),
      'mmc_registration_number': _mmcRegNumberController.text.trim(),
      'clinic_registration_number': _clinicRegNumberController.text.trim(),
      'clinic_address': _clinicAddressController.text.trim(),
      'village': _villageController.text.trim(),
      'city': _cityController.text.trim(),
      'taluka': _talukaController.text.trim(),
      'district': _districtController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _pincodeController.text.trim(),
    };
  }

  Future<void> _saveDoctorInfo(DoctorProfile profile) async {
    if (_isSaving) return;
    final payload = _buildPayload();
    final hasEmptyRequired = payload.values.any((value) => value.isEmpty);
    if (hasEmptyRequired) {
      Get.snackbar('Required', 'Please fill all fields before saving.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.controller.updateDoctorProfile(fields: payload);
      if (!mounted) return;
      final updated = widget.controller.profile.value ?? profile;
      _syncControllers(updated);
      setState(() {
        _isEditing = false;
      });
    } catch (error) {
      if (!mounted) return;
      Get.snackbar('Update Failed', error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.controller.profile.value;
    if (profile == null) return const SizedBox.shrink();

    if (!_isEditing) {
      _syncControllers(profile);
    }

    final location = [
      profile.village,
      profile.city,
      profile.taluka,
      profile.district,
      profile.state,
      profile.pincode,
    ].where((part) => part.trim().isNotEmpty).join(', ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      children: [
        Container(
          width: double.infinity,
          color: AppColors.primary,
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + 8,
            20,
            12,
          ),
          child: const Text(
            'Profile',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4FAF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE4EFE4)),
                ),
                child: Column(
                  children: [
                    ClipOval(
                      child: profile.photoUrl.isNotEmpty
                          ? Image.network(
                              profile.photoUrl,
                              height: 90,
                              width: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                AppAssets.appIcon,
                                height: 90,
                                width: 90,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              AppAssets.appIcon,
                              height: 90,
                              width: 90,
                              fit: BoxFit.cover,
                            ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      profile.fullName.isEmpty ? 'Doctor' : profile.fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'SF Pro Display', fontSize: 19, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _menuTile(
                icon: Icons.person_outline_rounded,
                title: 'Profile',
                subtitle: _showDoctorDetails ? 'Hide doctor information' : 'Show doctor information',
                onTap: () {
                  setState(() {
                    _showDoctorDetails = !_showDoctorDetails;
                    if (!_showDoctorDetails) {
                      _isEditing = false;
                    }
                  });
                },
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4FAF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE4EFE4)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _sectionTitle('Doctor Information')),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = !_isEditing;
                              });
                            },
                            tooltip: _isEditing ? 'Cancel Edit' : 'Edit',
                            icon: Icon(
                              _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      _editableDetailTile(label: 'First Name', controller: _firstNameController, enabled: _isEditing),
                      _editableDetailTile(label: 'Last Name', controller: _lastNameController, enabled: _isEditing),
                      _editableDetailTile(label: 'Clinic Name', controller: _clinicNameController, enabled: _isEditing),
                      _editableDetailTile(label: 'Degree', controller: _degreeController, enabled: _isEditing),
                      _editableDetailTile(
                        label: 'Contact Number',
                        controller: _contactNumberController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                      ),
                      _editableDetailTile(
                        label: 'Email',
                        controller: _emailController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _editableDetailTile(
                        label: 'Aadhar Number',
                        controller: _aadharNumberController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.number,
                      ),
                      _editableDetailTile(label: 'PAN Number', controller: _panNumberController, enabled: _isEditing),
                      _editableDetailTile(label: 'MMC Reg No', controller: _mmcRegNumberController, enabled: _isEditing),
                      _editableDetailTile(
                        label: 'Clinic Reg No',
                        controller: _clinicRegNumberController,
                        enabled: _isEditing,
                      ),
                      _detailTile(label: 'Location', value: location),
                      _editableDetailTile(label: 'Village', controller: _villageController, enabled: _isEditing),
                      _editableDetailTile(label: 'City', controller: _cityController, enabled: _isEditing),
                      _editableDetailTile(label: 'Taluka', controller: _talukaController, enabled: _isEditing),
                      _editableDetailTile(label: 'District', controller: _districtController, enabled: _isEditing),
                      _editableDetailTile(label: 'State', controller: _stateController, enabled: _isEditing),
                      _editableDetailTile(
                        label: 'Pincode',
                        controller: _pincodeController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.number,
                      ),
                      _editableDetailTile(
                        label: 'Clinic Address',
                        controller: _clinicAddressController,
                        enabled: _isEditing,
                        maxLines: 3,
                      ),
                      _detailTile(label: 'Status', value: profile.status.toUpperCase()),
                      if (_isEditing) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isSaving
                                    ? null
                                    : () {
                                        setState(() {
                                          _isEditing = false;
                                          _syncControllers(profile);
                                        });
                                      },
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : () => _saveDoctorInfo(profile),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                ),
                                child: Text(_isSaving ? 'Saving...' : 'Save'),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      _sectionTitle('Documents'),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (profile.photoUrl.isNotEmpty) _documentCard('Doctor Photo', profile.photoUrl),
                          ...profile.documents.entries.map(
                            (entry) => _documentCard(
                              entry.key.replaceAll('_', ' ').toUpperCase(),
                              entry.value,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                crossFadeState: _showDoctorDetails ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
              ),
              _menuTile(
                icon: Icons.credit_card_outlined,
                title: 'My cards',
                subtitle: 'UPI, Debit Card, Credit Card, Net Banking, Cash',
              ),
              _menuTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notification',
                subtitle: 'Manage app notifications',
              ),
              _menuTile(
                icon: Icons.shield_outlined,
                title: 'Privacy policy',
                subtitle: 'View terms and data policy',
              ),
              _menuTile(
                icon: Icons.logout_rounded,
                title: 'Log out',
                subtitle: 'Sign out from your account',
                onTap: widget.controller.logout,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
      ),
    );
  }

  Widget _detailTile({
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4EFE4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 7,
            width: 7,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontFamily: 'SF Pro Display', fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                if (value.trim().isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    value,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.2, color: AppColors.grey),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editableDetailTile({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4EFE4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            height: 7,
            width: 7,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontFamily: 'SF Pro Display', fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                if (enabled)
                  TextFormField(
                    controller: controller,
                    keyboardType: keyboardType,
                    maxLines: maxLines,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE4EFE4)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE4EFE4)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  )
                else
                  Text(
                    controller.text.trim().isEmpty ? '-' : controller.text.trim(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.2, color: AppColors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentCard(String title, String source) {
    final cleanSource = source.trim();
    final resolved = cleanSource.startsWith('http://') || cleanSource.startsWith('https://')
        ? cleanSource
        : cleanSource.isEmpty
            ? ''
            : '${ApiConstants.publicBaseUrl}/${cleanSource.replaceFirst(RegExp(r'^/+'), '')}';
    final lower = resolved.toLowerCase();
    final isImage = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');

    Widget preview;
    if (isImage && resolved.isNotEmpty) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          resolved,
          height: 52,
          width: 92,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 52,
            width: 92,
            color: const Color(0xFFE8F0E8),
            child: const Icon(Icons.image_not_supported_outlined, size: 18, color: AppColors.grey),
          ),
        ),
      );
    } else {
      preview = Container(
        height: 52,
        width: 92,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F0E8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFC0392B), size: 20),
        ),
      );
    }

    return Container(
      width: 110,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4EFE4)),
      ),
      child: Column(
        children: [
          preview,
          const SizedBox(height: 5),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10.4, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    final child = Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4EFE4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.black),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.grey),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.black),
        ],
      ),
    );

    if (onTap == null) return child;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: child,
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
      decoration: const BoxDecoration(
        color: AppColors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'SF Pro Display', fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}

class _BannerSection extends StatelessWidget {
  const _BannerSection({
    required this.controller,
    required this.pageController,
    required this.banners,
    required this.pageIndex,
    required this.onPageChanged,
  });

  final HomeController controller;
  final PageController pageController;
  final List<_BannerData> banners;
  final int pageIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.only(top: 18, bottom: 24),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: PageView.builder(
              controller: pageController,
              itemCount: banners.length,
              onPageChanged: onPageChanged,
              itemBuilder: (context, index) {
                final banner = banners[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GestureDetector(
                    onTap: () => controller.selectedIndex.value = 1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEAF5EA), Color(0xFFD5E8D6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: 8,
                            bottom: 0,
                            top: 0,
                            child: Opacity(
                              opacity: 0.23,
                              child: Image.asset(
                                banner.image,
                                width: 128,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 108, 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  banner.title,
                                  style: const TextStyle(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.black,
                                  ),
                                ),
                                const Row(
                                  children: [
                                    Text(
                                      'Book Now',
                                      style: TextStyle(fontFamily: 'Avenir', fontSize: 15, fontWeight: FontWeight.w700),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, size: 20),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (index) {
              final selected = index == pageIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: selected ? 18 : 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3.5),
                  color: selected ? AppColors.black : AppColors.black.withValues(alpha: 0.10),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _BannerData {
  const _BannerData({
    required this.title,
    required this.image,
  });

  final String title;
  final String image;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _backgroundColorByTitle(title);
    final borderColor = _borderColorByTitle(title);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11.5, color: AppColors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Color _backgroundColorByTitle(String title) {
    switch (title) {
      case 'Today Visits':
        return const Color(0xFFEFF6FF);
      case 'Pending Approvals':
        return const Color(0xFFFFF7E8);
      case 'Completed':
        return const Color(0xFFEDF9F1);
      case 'Today Earnings':
        return const Color(0xFFEFFAF7);
      default:
        return const Color(0xFFF5F9F5);
    }
  }

  Color _borderColorByTitle(String title) {
    switch (title) {
      case 'Today Visits':
        return const Color(0xFFD5E7FF);
      case 'Pending Approvals':
        return const Color(0xFFF7DFB4);
      case 'Completed':
        return const Color(0xFFCFECD8);
      case 'Today Earnings':
        return const Color(0xFFD2EFE7);
      default:
        return const Color(0xFFE1EDE1);
    }
  }
}
*/
