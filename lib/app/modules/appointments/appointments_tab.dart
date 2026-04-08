import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/models/doctor_appointment.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_controller.dart';

class AppointmentsTab extends StatelessWidget {
  const AppointmentsTab({
    super.key,
    required this.controller,
  });

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final appointments = controller.appointments;
      return RefreshIndicator(
        onRefresh: controller.refreshAppointments,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 8, 18, 14),
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
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (appointments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: _EmptyCard(message: 'No appointments right now.'),
              )
            else
              ...appointments.map(
                (item) => _AppointmentCard(
                  appointment: item,
                  onApprove: () => controller.approveAppointment(item),
                  onDecline: () => controller.declineAppointment(item),
                  onReschedule: () => _openRescheduleSheet(context, item),
                  onMap: () => controller.openNavigation(item),
                ),
              ),
          ],
        ),
      );
    });
  }

  Future<void> _openRescheduleSheet(BuildContext context, DoctorAppointment appointment) async {
    DateTime selectedDate = appointment.scheduledAt?.toLocal() ?? DateTime.now().add(const Duration(hours: 2));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);
    final amountController = TextEditingController(text: (appointment.charges ?? 500).toStringAsFixed(0));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reschedule Appointment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_rounded),
                    title: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                        });
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time_rounded),
                    title: Text(selectedTime.format(context)),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setState(() {
                          selectedTime = picked;
                          selectedDate = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            picked.hour,
                            picked.minute,
                          );
                        });
                      }
                    },
                  ),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Charges',
                      prefixText: 'Rs ',
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final charge = double.tryParse(amountController.text.trim()) ?? 0;
                        if (charge <= 0) {
                          Get.snackbar('Invalid Amount', 'Enter a valid charge amount.');
                          return;
                        }
                        Navigator.of(sheetContext).pop();
                        await controller.rescheduleAppointment(
                          appointment: appointment,
                          scheduledAt: selectedDate,
                          charges: charge,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Save Reschedule'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.onApprove,
    required this.onDecline,
    required this.onReschedule,
    required this.onMap,
  });

  final DoctorAppointment appointment;
  final VoidCallback onApprove;
  final VoidCallback onDecline;
  final VoidCallback onReschedule;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    final when = appointment.scheduledAt ?? appointment.requestedAt;
    final status = appointment.statusLabel;
    final showActionButtons = appointment.canFixAppointment;
    final waitingApproval = appointment.waitingForFarmerApproval;
    final canNavigate = appointment.canNavigate;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EFE4)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _animalImage(appointment.animalPhotoUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.farmerName,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appointment.animalName,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appointment.concern,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
                    ),
                    if (appointment.charges != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Rs ${appointment.charges!.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (when != null)
                    Text(
                      DateFormat('dd-MM-yyyy').format(when.toLocal()),
                      style: const TextStyle(fontSize: 11.5, color: AppColors.grey),
                    ),
                  const SizedBox(height: 6),
                  _statusPill(status),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (showActionButtons)
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    label: 'Approve',
                    background: const Color(0xFF2E7D32),
                    foreground: AppColors.white,
                    onPressed: onApprove,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    label: 'Decline',
                    background: const Color(0xFFFBE9E9),
                    foreground: const Color(0xFFC0392B),
                    onPressed: onDecline,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    label: 'Reschedule',
                    background: const Color(0xFFEAF5EA),
                    foreground: AppColors.primary,
                    onPressed: onReschedule,
                  ),
                ),
              ],
            )
          else if (waitingApproval)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Waiting for farmer approval',
                style: TextStyle(fontSize: 12.5, color: AppColors.grey, fontWeight: FontWeight.w600),
              ),
            )
          else if (canNavigate)
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: onMap,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.navigation_rounded, size: 16, color: AppColors.primary),
                ),
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _animalImage(String source) {
    final image = source.trim().isEmpty ? 'assets/images/available_doctor_1st.png' : source.trim();
    final isNetwork = image.startsWith('http://') || image.startsWith('https://');

    if (isNetwork) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          image,
          height: 78,
          width: 78,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _imageFallback(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        image,
        height: 78,
        width: 78,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _imageFallback(),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      height: 78,
      width: 78,
      color: const Color(0xFFE4EFE4),
      child: const Icon(Icons.pets_rounded, color: AppColors.grey),
    );
  }

  Widget _statusPill(String label) {
    final lower = label.toLowerCase();
    Color border = AppColors.primary;
    Color text = AppColors.primary;
    if (lower.contains('declined') || lower.contains('cancelled')) {
      border = const Color(0xFFC0392B);
      text = const Color(0xFFC0392B);
    } else if (lower.contains('pending') || lower.contains('waiting')) {
      border = const Color(0xFFD68910);
      text = const Color(0xFFD68910);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: text),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          backgroundColor: background,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11.2, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4EFE4)),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 13, color: AppColors.grey),
      ),
    );
  }
}
