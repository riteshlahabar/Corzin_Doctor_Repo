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
      final appointments = controller.appointments
          .where((item) => item.normalizedStatus != 'completed')
          .toList();
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
                  onVerifyOtp: () => _openOtpSheet(context, item),
                  onStartTreatment: () => controller.startAppointmentTreatment(appointment: item),
                  onAddTreatment: () => _openTreatmentSheet(context, item),
                  onComplete: () => controller.markAppointmentCompleted(item),
                ),
              ),
          ],
        ),
      );
    });
  }

  Future<void> _openOtpSheet(BuildContext context, DoctorAppointment appointment) async {
    debugPrint(
      '[OTP][UI] Verify OTP tapped for appointment=${appointment.id}, '
      'status=${appointment.status}, farmer=${appointment.farmerName}, phone=${appointment.farmerPhone}',
    );
    final otpController = TextEditingController();
    final sent = await controller.sendAppointmentOtp(
      appointment: appointment,
      showSuccess: false,
    );
    debugPrint('[OTP][UI] sendAppointmentOtp result for appointment=${appointment.id}: $sent');
    if (!context.mounted) return;
    if (sent) {
      Get.snackbar('OTP Sent', 'OTP sent to farmer mobile. Please enter it below.');
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verify Visit OTP',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ask farmer for OTP and enter here.',
                style: TextStyle(fontSize: 12.5, color: AppColors.grey),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    debugPrint('[OTP][UI] Resend OTP tapped for appointment=${appointment.id}');
                    await controller.sendAppointmentOtp(appointment: appointment);
                  },
                  icon: const Icon(Icons.sms_rounded, size: 18),
                  label: const Text('Resend OTP'),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'OTP',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final otp = otpController.text.trim();
                    debugPrint('[OTP][UI] Verify submit tapped for appointment=${appointment.id}, otp=$otp');
                    if (otp.length != 6) {
                      Get.snackbar('Invalid OTP', 'Please enter a valid 6-digit OTP.');
                      return;
                    }
                    Navigator.of(sheetContext).pop();
                    await controller.verifyAppointmentOtp(
                      appointment: appointment,
                      otp: otp,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Verify OTP'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openTreatmentSheet(BuildContext context, DoctorAppointment appointment) async {
    final onsiteTreatmentController = TextEditingController();
    final notesController = TextEditingController(text: appointment.notes);
    final medicines = <_MedicineInput>[_MedicineInput()];
    final pendingDispose = <_MedicineInput>[];
    bool followupRequired = appointment.followupRequired;
    DateTime? nextFollowupDate = appointment.nextFollowupDate?.toLocal();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            const doseColumnWidth = 32.0;
            const totalColumnWidth = 54.0;

            return SafeArea(
              top: false,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text(
                    'Add Treatment Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Medicine',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: doseColumnWidth,
                        child: const Center(child: Text('M', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: doseColumnWidth,
                        child: const Center(child: Text('A', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: doseColumnWidth,
                        child: const Center(child: Text('E', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: totalColumnWidth,
                        child: Text(
                          'Total',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...List.generate(medicines.length, (index) {
                    final row = medicines[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: row.nameController,
                              minLines: 1,
                              maxLines: 1,
                              decoration: const InputDecoration(
                                hintText: 'Medicine name',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: doseColumnWidth,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: row.morning,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                  onChanged: (value) => setState(() => row.morning = value ?? false),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: doseColumnWidth,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: row.afternoon,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                  onChanged: (value) => setState(() => row.afternoon = value ?? false),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: doseColumnWidth,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: row.evening,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                  onChanged: (value) => setState(() => row.evening = value ?? false),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: totalColumnWidth,
                            child: TextField(
                              controller: row.totalController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              minLines: 1,
                              maxLines: 1,
                              decoration: const InputDecoration(
                                hintText: 'Tabs',
                                isDense: true,
                                constraints: BoxConstraints(minHeight: 40, maxHeight: 40),
                                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (medicines.length > 1)
                            InkWell(
                              onTap: () {
                                setState(() {
                                  pendingDispose.add(medicines.removeAt(index));
                                });
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  for (final item in pendingDispose) {
                                    item.dispose();
                                  }
                                  pendingDispose.clear();
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                height: 26,
                                width: 26,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFBE9E9),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.remove_rounded, size: 16, color: Color(0xFFC0392B)),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () {
                        setState(() => medicines.add(_MedicineInput()));
                      },
                      icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
                      tooltip: 'Add medicine',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: onsiteTreatmentController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'On-Site-Treatment',
                      alignLabelWithHint: true,
                      constraints: BoxConstraints(minHeight: 64),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    minLines: 1,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                    ),
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: followupRequired,
                    title: const Text('Follow-up required'),
                    onChanged: (value) => setState(() {
                      followupRequired = value;
                      if (!followupRequired) {
                        nextFollowupDate = null;
                      }
                    }),
                  ),
                  if (followupRequired)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_available_rounded),
                      title: Text(
                        nextFollowupDate == null
                            ? 'Select next follow-up date'
                            : DateFormat('dd MMM yyyy').format(nextFollowupDate!),
                      ),
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: nextFollowupDate ?? now.add(const Duration(days: 1)),
                          firstDate: DateTime(now.year, now.month, now.day),
                          lastDate: now.add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            nextFollowupDate = DateTime(picked.year, picked.month, picked.day);
                          });
                        }
                      },
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final entries = <String>[];
                        for (var i = 0; i < medicines.length; i++) {
                          final row = medicines[i];
                          final medicine = row.nameController.text.trim();
                          if (medicine.isEmpty) continue;
                          final total = row.totalController.text.trim();
                          final schedule = [
                            if (row.morning) 'M',
                            if (row.afternoon) 'A',
                            if (row.evening) 'E',
                          ];
                          final scheduleLabel = schedule.isEmpty ? '-' : schedule.join('/');
                          entries.add(
                            '${i + 1}. $medicine | Time: $scheduleLabel | Total Tabs: ${total.isEmpty ? '-' : total}',
                          );
                        }

                        if (entries.isEmpty) {
                          Get.snackbar('Required', 'Please add at least one medicine.');
                          return;
                        }
                        if (followupRequired && nextFollowupDate == null) {
                          Get.snackbar('Required', 'Please select next follow-up date.');
                          return;
                        }

                        final treatment = [
                          if (onsiteTreatmentController.text.trim().isNotEmpty)
                            'On-Site-Treatment: ${onsiteTreatmentController.text.trim()}',
                          entries.join('\n'),
                        ].join('\n');
                        Navigator.of(sheetContext).pop();
                        await controller.saveAppointmentTreatment(
                          appointment: appointment,
                          treatmentDetails: treatment,
                          followupRequired: followupRequired,
                          nextFollowupDate: nextFollowupDate,
                          notes: notesController.text.trim(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Save Treatment'),
                    ),
                  ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // Dispose after sheet close animation completes to avoid "used after dispose"
    // while TextField widgets are still detaching from the tree.
    await Future<void>.delayed(const Duration(milliseconds: 260));
    for (final item in pendingDispose) {
      item.dispose();
    }
    for (final medicine in medicines) {
      medicine.dispose();
    }
    onsiteTreatmentController.dispose();
    notesController.dispose();
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
    required this.onVerifyOtp,
    required this.onStartTreatment,
    required this.onAddTreatment,
    required this.onComplete,
  });

  final DoctorAppointment appointment;
  final VoidCallback onApprove;
  final VoidCallback onDecline;
  final VoidCallback onReschedule;
  final VoidCallback onMap;
  final VoidCallback onVerifyOtp;
  final VoidCallback onStartTreatment;
  final VoidCallback onAddTreatment;
  final VoidCallback onComplete;

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
                    if (appointment.diseaseNames.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Disease: ${appointment.diseaseNames.join(', ')}',
                        style: const TextStyle(fontSize: 12, color: AppColors.grey),
                      ),
                    ],
                    if (appointment.diseaseDetails.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Details: ${appointment.diseaseDetails}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.grey),
                      ),
                    ],
                    if (appointment.treatmentDetails.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Treatment: ${appointment.treatmentDetails}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.grey),
                      ),
                    ],
                    if (appointment.followupRequired && appointment.nextFollowupDate != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Next Follow-up: ${DateFormat('dd MMM yyyy').format(appointment.nextFollowupDate!)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.grey),
                      ),
                    ],
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
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                if (appointment.needsOtpVerification)
                  _actionButton(
                    label: 'Verify OTP',
                    background: AppColors.primary,
                    foreground: AppColors.white,
                    onPressed: onVerifyOtp,
                  ),
                if (appointment.canStartTreatment)
                  _actionButton(
                    label: 'Start Treatment',
                    background: const Color(0xFF2E7D32),
                    foreground: AppColors.white,
                    onPressed: onStartTreatment,
                  ),
                if (appointment.normalizedStatus == 'in_progress')
                  _actionButton(
                    label: 'Add Treatment',
                    background: const Color(0xFFEAF5EA),
                    foreground: AppColors.primary,
                    onPressed: onAddTreatment,
                  ),
                if (appointment.canComplete)
                  _actionButton(
                    label: 'Complete',
                    background: const Color(0xFF2E7D32),
                    foreground: AppColors.white,
                    onPressed: onComplete,
                  ),
                if (canNavigate)
                  InkWell(
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
              ],
            ),
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

class _MedicineInput {
  _MedicineInput({
    String? name,
    String? total,
  })  : nameController = TextEditingController(text: name ?? ''),
        totalController = TextEditingController(text: total ?? '');

  final TextEditingController nameController;
  final TextEditingController totalController;
  bool morning = false;
  bool afternoon = false;
  bool evening = false;

  void dispose() {
    nameController.dispose();
    totalController.dispose();
  }
}
