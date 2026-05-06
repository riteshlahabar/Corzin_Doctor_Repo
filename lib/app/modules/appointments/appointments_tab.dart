import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/models/doctor_appointment.dart';
import '../../core/theme/app_colors.dart';
import '../../routes/app_pages.dart';
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
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      controller.selectedIndex.value = 0;
                      if (Get.currentRoute != AppRoutes.home) {
                        Get.offAllNamed(AppRoutes.home);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
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
                  const SizedBox(width: 30),
                ],
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
                  otpAlreadySent: controller.otpRequestedAppointmentIds.contains(item.id),
                  onApprove: () => controller.approveAppointment(item),
                  onDecline: () => controller.declineAppointment(item),
                  onCall: () {
                    controller.callFarmer(item);
                  },
                  onMap: () => controller.openNavigation(item),
                  onVerifyOtp: () => _openOtpSheet(
                    context,
                    item,
                    otpAlreadySent: controller.otpRequestedAppointmentIds.contains(item.id),
                  ),
                  onStartTreatment: () => controller.startAppointmentTreatment(appointment: item),
                  onViewHistory: () => _openHistorySheet(context, item),
                  onViewMore: () => _openAppointmentDetails(
                    context,
                    item,
                    controller.appointmentDistanceLabels[item.id] ?? '--',
                  ),
                  onAddTreatment: () => _openTreatmentSheet(context, item),
                  onComplete: () => _openCompleteWithChargesSheet(context, item),
                  distanceLabel: controller.appointmentDistanceLabels[item.id] ?? '--',
                ),
              ),
          ],
        ),
      );
    });
  }

  Future<void> _openOtpSheet(
    BuildContext context,
    DoctorAppointment appointment, {
    required bool otpAlreadySent,
  }) async {
    debugPrint(
      '[OTP][UI] OTP action tapped for appointment=${appointment.id}, '
      'status=${appointment.status}, farmer=${appointment.farmerName}, phone=${appointment.farmerPhone}',
    );
    final otpController = TextEditingController();
    if (!otpAlreadySent) {
      final sent = await controller.sendAppointmentOtp(
        appointment: appointment,
        showSuccess: false,
      );
      debugPrint('[OTP][UI] sendAppointmentOtp result for appointment=${appointment.id}: $sent');
      if (!context.mounted) return;
      if (!sent) {
        return;
      }
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

  Future<void> _openCompleteWithChargesSheet(
    BuildContext context,
    DoctorAppointment appointment,
  ) async {
    final feesController = TextEditingController(
      text: appointment.fees != null
          ? appointment.fees!.toStringAsFixed(0)
          : ((appointment.charges ?? 0) > 0 ? appointment.charges!.toStringAsFixed(0) : ''),
    );
    final onSiteMedicineChargesController = TextEditingController(
      text: appointment.onSiteMedicineCharges != null
          ? appointment.onSiteMedicineCharges!.toStringAsFixed(0)
          : '',
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final parsedFees = double.tryParse(feesController.text.trim());
            final parsedOnSiteMedicineCharges =
                double.tryParse(onSiteMedicineChargesController.text.trim()) ?? 0;
            final canSubmit = parsedFees != null && parsedFees > 0;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Complete Appointment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter final charges to complete this appointment.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.grey),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: feesController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 12.2),
                    decoration: const InputDecoration(
                      labelText: 'Fees',
                      prefixText: 'Rs ',
                      hintText: 'Enter visit fees',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      labelStyle: TextStyle(fontSize: 12),
                      hintStyle: TextStyle(fontSize: 11.5),
                      floatingLabelStyle: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: onSiteMedicineChargesController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 12.2),
                    decoration: const InputDecoration(
                      labelText: 'On Site Medicine Charges',
                      prefixText: 'Rs ',
                      hintText: 'Enter on site medicine charges',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      labelStyle: TextStyle(fontSize: 12),
                      hintStyle: TextStyle(fontSize: 11.5),
                      floatingLabelStyle: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: Rs ${(canSubmit ? (parsedFees + parsedOnSiteMedicineCharges) : 0).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: canSubmit
                              ? () async {
                                  Navigator.of(sheetContext).pop();
                                  await controller.markAppointmentCompleted(
                                    appointment,
                                    fees: parsedFees,
                                    onSiteMedicineCharges: parsedOnSiteMedicineCharges,
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                          ),
                          child: const Text('Submit'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: canSubmit
                              ? () async {
                                  Navigator.of(sheetContext).pop();
                                  final completed = await controller.markAppointmentCompleted(
                                    appointment,
                                    fees: parsedFees,
                                    onSiteMedicineCharges: parsedOnSiteMedicineCharges,
                                  );
                                  if (!completed) return;
                                  await _openContinueAnimalsSheet(appointment);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            foregroundColor: AppColors.white,
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Save & Continue',
                              maxLines: 1,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    // Let bottom-sheet close animation complete before disposing controllers.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    feesController.dispose();
    onSiteMedicineChargesController.dispose();
  }

  Future<void> _openContinueAnimalsSheet(DoctorAppointment appointment) async {
    final animals = await controller.fetchContinuationAnimals(appointmentId: appointment.id);
    if (animals.isEmpty) {
      Get.snackbar('No Animals', 'No animals available for this farmer.');
      return;
    }

    final hostContext = Get.context;
    if (hostContext == null) return;
    if (!hostContext.mounted) return;

    await showModalBottomSheet<void>(
      context: hostContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Animal For Next Treatment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.55),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: animals.length,
                    itemBuilder: (context, index) {
                      final animal = animals[index];
                      final image = animal.imageUrl.trim();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4FAF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE4EFE4)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: image.startsWith('http://') || image.startsWith('https://')
                                  ? Image.network(
                                      image,
                                      height: 50,
                                      width: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        height: 50,
                                        width: 50,
                                        color: const Color(0xFFE4EFE4),
                                        child: const Icon(Icons.pets_rounded, color: AppColors.grey),
                                      ),
                                    )
                                  : Container(
                                      height: 50,
                                      width: 50,
                                      color: const Color(0xFFE4EFE4),
                                      child: const Icon(Icons.pets_rounded, color: AppColors.grey),
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    animal.name,
                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    animal.tagNumber.trim().isEmpty ? 'Tag: -' : 'Tag: ${animal.tagNumber}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.of(sheetContext).pop();
                                final created = await controller.continueAppointmentWithAnimal(
                                  appointmentId: appointment.id,
                                  animalId: animal.id,
                                );
                                if (created != null) {
                                  await controller.refreshAppointments();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                minimumSize: const Size(88, 32),
                              ),
                              child: const Text('Continue'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openTreatmentSheet(BuildContext context, DoctorAppointment appointment) async {
    final parsedTreatment = _parseTreatmentForEditing(appointment.treatmentDetails);
    final onsiteTreatments = parsedTreatment.onsiteTreatments.isEmpty
        ? <TextEditingController>[TextEditingController()]
        : parsedTreatment.onsiteTreatments.map((item) => TextEditingController(text: item)).toList();
    final pendingOnsiteDispose = <TextEditingController>[];
    final notesController = TextEditingController(text: appointment.notes);
    final medicines = parsedTreatment.medicines.isEmpty
        ? <_MedicineInput>[_MedicineInput()]
        : parsedTreatment.medicines
            .map(
              (item) => _MedicineInput(
                name: item.name,
                total: item.total,
                morning: item.morning,
                afternoon: item.afternoon,
                evening: item.evening,
              ),
            )
            .toList();
    final pendingDispose = <_MedicineInput>[];

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
                  const Text(
                    'On-Site-Treatment',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey),
                  ),
                  const SizedBox(height: 4),
                  ...List.generate(onsiteTreatments.length, (index) {
                    final rowController = onsiteTreatments[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: rowController,
                              minLines: 1,
                              maxLines: 1,
                              decoration: const InputDecoration(
                                hintText: 'On-site treatment',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (onsiteTreatments.length > 1)
                            InkWell(
                              onTap: () {
                                setState(() {
                                  pendingOnsiteDispose.add(onsiteTreatments.removeAt(index));
                                });
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  for (final item in pendingOnsiteDispose) {
                                    item.dispose();
                                  }
                                  pendingOnsiteDispose.clear();
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
                      onPressed: () => setState(() => onsiteTreatments.add(TextEditingController())),
                      icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
                      tooltip: 'Add on-site treatment',
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
                        final onsiteEntries = onsiteTreatments
                            .map((item) => item.text.trim())
                            .where((item) => item.isNotEmpty)
                            .toList();

                        final onsiteBlock = onsiteEntries.isEmpty
                            ? null
                            : 'On-Site-Treatment: ${onsiteEntries.join(', ')}';

                        final treatment = [
                          onsiteBlock,
                          entries.join('\n'),
                        ].whereType<String>().join('\n');
                        Navigator.of(sheetContext).pop();
                        await controller.saveAppointmentTreatment(
                          appointment: appointment,
                          treatmentDetails: treatment,
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
    for (final item in pendingOnsiteDispose) {
      item.dispose();
    }
    for (final medicine in medicines) {
      medicine.dispose();
    }
    for (final item in onsiteTreatments) {
      item.dispose();
    }
    notesController.dispose();
  }

  _ParsedTreatmentData _parseTreatmentForEditing(String rawTreatment) {
    final treatment = rawTreatment.trim();
    if (treatment.isEmpty) {
      return const _ParsedTreatmentData();
    }

    final onsiteEntries = <String>[];
    final medicineEntries = <_ParsedMedicineData>[];

    final lines = treatment.split('\n').map((item) => item.trim()).where((item) => item.isNotEmpty);
    for (final line in lines) {
      final onsiteMatch = RegExp(r'^on-site-treatment\s*:\s*(.*)$', caseSensitive: false).firstMatch(line);
      if (onsiteMatch != null) {
        final onsiteValue = (onsiteMatch.group(1) ?? '').trim();
        if (onsiteValue.isNotEmpty) {
          onsiteEntries.addAll(
            onsiteValue
                .split(',')
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty),
          );
        }
        continue;
      }

      final cleaned = line.replaceFirst(RegExp(r'^\d+\.\s*'), '');
      final parts = cleaned.split('|').map((item) => item.trim()).toList();
      if (parts.isEmpty || parts.first.isEmpty) {
        continue;
      }

      final medicineName = parts.first;
      String totalTabs = '';
      String schedule = '';

      for (final part in parts.skip(1)) {
        if (part.toLowerCase().startsWith('time:')) {
          schedule = part.substring(5).trim().toUpperCase();
        } else if (part.toLowerCase().startsWith('total tabs:')) {
          totalTabs = part.substring(11).trim();
        }
      }

      medicineEntries.add(
        _ParsedMedicineData(
          name: medicineName,
          total: totalTabs == '-' ? '' : totalTabs,
          morning: RegExp(r'(^|[^A-Z])M([^A-Z]|$)').hasMatch(schedule),
          afternoon: RegExp(r'(^|[^A-Z])A([^A-Z]|$)').hasMatch(schedule),
          evening: RegExp(r'(^|[^A-Z])E([^A-Z]|$)').hasMatch(schedule),
        ),
      );
    }

    if (medicineEntries.isEmpty && onsiteEntries.isEmpty && treatment.isNotEmpty) {
      onsiteEntries.add(treatment);
    }

    return _ParsedTreatmentData(
      onsiteTreatments: onsiteEntries,
      medicines: medicineEntries,
    );
  }

  Future<void> _openHistorySheet(BuildContext context, DoctorAppointment appointment) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.68,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Animal Past History',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${appointment.farmerName} • ${appointment.animalName}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4E5A4E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (appointment.previousHistories.isNotEmpty) ...[
                            const Text(
                              'Past Clinic Visits',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                            const SizedBox(height: 6),
                            ...appointment.previousHistories.map((history) {
                              final when = history.completedAt != null
                                  ? DateFormat('dd MMM yyyy, hh:mm a').format(history.completedAt!.toLocal())
                                  : 'Visit';
                              final details = history.treatmentDetails.trim().isNotEmpty
                                  ? history.treatmentDetails.trim()
                                  : history.concern.trim();
                              final onsite = history.onsiteTreatment.trim();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      when,
                                      style: const TextStyle(
                                        fontSize: 12.2,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF111A11),
                                      ),
                                    ),
                                    if (onsite.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'On-Site Treatment: $onsite',
                                        style: const TextStyle(
                                          fontSize: 12.2,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF4E5A4E),
                                        ),
                                      ),
                                    ],
                                    if (details.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        details,
                                        style: const TextStyle(
                                          fontSize: 12.2,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF4E5A4E),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                          ],
                          if (appointment.recentMilkHistory.isNotEmpty) ...[
                            const Text(
                              'Milk / Fat / SNF (Last 10 Days)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                            const SizedBox(height: 6),
                            ...appointment.recentMilkHistory.take(10).map((row) {
                              final date = row.date != null ? DateFormat('dd MMM').format(row.date!.toLocal()) : 'Date';
                              final milk = row.totalMilk?.toStringAsFixed(1) ?? '-';
                              final fat = row.fat?.toStringAsFixed(1) ?? '-';
                              final snf = row.snf?.toStringAsFixed(1) ?? '-';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '$date: Milk $milk L, Fat $fat, SNF $snf',
                                  style: const TextStyle(
                                    fontSize: 12.2,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4E5A4E),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                          ],
                          if (appointment.recentFeedingHistory.isNotEmpty) ...[
                            const Text(
                              'Feeding Data (Last 10 Days)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                            const SizedBox(height: 6),
                            ...appointment.recentFeedingHistory.take(20).map((row) {
                              final date = row.date != null ? DateFormat('dd MMM').format(row.date!.toLocal()) : 'Date';
                              final feed = row.feedType.trim().isEmpty ? 'Feed' : row.feedType;
                              final quantity = row.quantity != null ? row.quantity!.toStringAsFixed(1) : '-';
                              final unit = row.unit.trim().isEmpty ? '' : ' ${row.unit}';
                              final time = row.feedingTime.trim().isEmpty ? '' : ' (${row.feedingTime})';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '$date$time: $feed $quantity$unit',
                                  style: const TextStyle(
                                    fontSize: 12.2,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4E5A4E),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                          ],
                          if (appointment.recentPregnancyHistory.isNotEmpty) ...[
                            const Text(
                              'Pregnancy Data (Within 6 Months)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                            const SizedBox(height: 6),
                            ...appointment.recentPregnancyHistory.take(6).map((row) {
                              final ai = row.aiDate != null ? DateFormat('dd MMM yyyy').format(row.aiDate!.toLocal()) : '-';
                              final calving = row.calvingDate != null ? DateFormat('dd MMM yyyy').format(row.calvingDate!.toLocal()) : '-';
                              final confirmed = row.pregnancyConfirmation ? 'Confirmed' : 'Not confirmed';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  'AI: $ai, Calving: $calving, Pregnancy: $confirmed',
                                  style: const TextStyle(
                                    fontSize: 12.2,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4E5A4E),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                          ],
                          if (appointment.previousHistories.isEmpty &&
                              appointment.recentMilkHistory.isEmpty &&
                              appointment.recentFeedingHistory.isEmpty &&
                              appointment.recentPregnancyHistory.isEmpty)
                            const Text(
                              'No history available yet.',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4E5A4E),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAppointmentDetails(
    BuildContext context,
    DoctorAppointment appointment,
    String distanceLabel,
  ) async {
    final when = appointment.scheduledAt ?? appointment.requestedAt;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appointment Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  _detailRow('Farmer', appointment.farmerName),
                  _detailRow('Animal', appointment.animalName),
                  _detailRow('Appointment ID', appointment.displayAppointmentCode),
                  _detailRow('Status', appointment.statusLabel),
                  _detailRow(
                    'Address',
                    appointment.address.trim().isEmpty ? '-' : appointment.address.trim(),
                  ),
                  if (when != null) _detailRow('Date & Time', DateFormat('dd MMM yyyy, hh:mm a').format(when.toLocal())),
                  if (appointment.diseaseNames.isNotEmpty) _detailRow('Disease', appointment.diseaseNames.join(', ')),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF7CB342).withValues(alpha: 0.6)),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Distance: $distanceLabel',
                        style: const TextStyle(
                          fontSize: 11.8,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ),
                  if (appointment.diseaseDetails.trim().isNotEmpty) _detailRow('Details', appointment.diseaseDetails),
                  if (appointment.treatmentDetails.trim().isNotEmpty)
                    _detailRow('Treatment', appointment.treatmentDetails),
                  if (appointment.followupRequired && appointment.nextFollowupDate != null)
                    _detailRow(
                      'Next Follow-up',
                      DateFormat('dd MMM yyyy').format(appointment.nextFollowupDate!.toLocal()),
                    ),
                  if (appointment.fees != null)
                    _detailRow('Fees', 'Rs ${appointment.fees!.toStringAsFixed(0)}'),
                  if (appointment.onSiteMedicineCharges != null)
                    _detailRow(
                      'On Site Medicine Charges',
                      'Rs ${appointment.onSiteMedicineCharges!.toStringAsFixed(0)}',
                    ),
                  if (appointment.charges != null)
                    _detailRow('Total', 'Rs ${appointment.charges!.toStringAsFixed(0)}'),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label: $value',
        softWrap: true,
        style: const TextStyle(
          fontSize: 12.2,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4E5A4E),
        ),
      ),
    );
  }

}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.otpAlreadySent,
    required this.onApprove,
    required this.onDecline,
    required this.onCall,
    required this.onMap,
    required this.onVerifyOtp,
    required this.onStartTreatment,
    required this.onViewHistory,
    required this.onViewMore,
    required this.onAddTreatment,
    required this.onComplete,
    required this.distanceLabel,
  });

  final DoctorAppointment appointment;
  final bool otpAlreadySent;
  final VoidCallback onApprove;
  final VoidCallback onDecline;
  final VoidCallback onCall;
  final VoidCallback onMap;
  final VoidCallback onVerifyOtp;
  final VoidCallback onStartTreatment;
  final VoidCallback onViewHistory;
  final VoidCallback onViewMore;
  final VoidCallback onAddTreatment;
  final VoidCallback onComplete;
  final String distanceLabel;

  @override
  Widget build(BuildContext context) {
    final when = appointment.scheduledAt ?? appointment.requestedAt;
    final status = appointment.statusLabel;
    final showActionButtons = appointment.canFixAppointment;
    final waitingApproval = appointment.waitingForFarmerApproval;
    final canNavigate = appointment.canNavigate;
    final hasTreatmentDetails = appointment.treatmentDetails.trim().isNotEmpty;
    final isInProgress = appointment.normalizedStatus == 'in_progress';
    final otpVerified = appointment.otpVerifiedAt != null;
    final showCornerDialer =
        appointment.needsOtpVerification &&
        !otpVerified &&
        !isInProgress &&
        appointment.farmerPhone.trim().isNotEmpty;
    final hasHistoryData = appointment.previousHistories.isNotEmpty ||
        appointment.recentMilkHistory.isNotEmpty ||
        appointment.recentFeedingHistory.isNotEmpty ||
        appointment.recentPregnancyHistory.isNotEmpty;
    final actionButtons = <Widget>[];
    Widget? fullWidthCompleteButton;
    if (otpVerified && !isInProgress && appointment.normalizedStatus != 'completed') {
      if (appointment.canStartTreatment) {
        actionButtons.add(
          _actionButton(
            label: 'Start Treatment',
            background: const Color(0xFF2E7D32),
            foreground: AppColors.white,
            onPressed: onStartTreatment,
          ),
        );
      }
      actionButtons.add(
        _actionButton(
          label: 'View History',
          background: const Color(0xFFEAF5EA),
          foreground: AppColors.primary,
          onPressed: onViewHistory,
        ),
      );
      actionButtons.add(
        _actionButton(
          label: 'View More',
          background: const Color(0xFFEAF5EA),
          foreground: AppColors.primary,
          onPressed: onViewMore,
        ),
      );
    } else {
      if (appointment.needsOtpVerification) {
        actionButtons.add(
          _actionButton(
            label: otpAlreadySent ? 'Verify OTP' : 'Send OTP',
            background: AppColors.primary,
            foreground: AppColors.white,
            onPressed: onVerifyOtp,
          ),
        );
      }
      if (!otpVerified && canNavigate) {
        actionButtons.add(
          _actionButton(
            label: 'View Map',
            background: const Color(0xFFEAF5EA),
            foreground: AppColors.primary,
            onPressed: onMap,
          ),
        );
      }
      if (isInProgress) {
        actionButtons.add(
          _actionButton(
            label: hasTreatmentDetails ? 'Edit Treatment' : 'Add Treatment',
            background: const Color(0xFFEAF5EA),
            foreground: AppColors.primary,
            onPressed: onAddTreatment,
          ),
        );
        actionButtons.add(
          _actionButton(
            label: 'View History',
            background: const Color(0xFFEAF5EA),
            foreground: AppColors.primary,
            onPressed: onViewHistory,
          ),
        );
        actionButtons.add(
          _actionButton(
            label: 'View More',
            background: const Color(0xFFEAF5EA),
            foreground: AppColors.primary,
            onPressed: onViewMore,
          ),
        );
      } else {
        actionButtons.add(
          _actionButton(
            label: 'View More',
            background: const Color(0xFFEAF5EA),
            foreground: AppColors.primary,
            onPressed: onViewMore,
          ),
        );
        if (otpVerified && appointment.normalizedStatus != 'completed' && hasHistoryData) {
          actionButtons.add(
            _actionButton(
              label: 'View History',
              background: const Color(0xFFEAF5EA),
              foreground: AppColors.primary,
              onPressed: onViewHistory,
            ),
          );
        }
      }
      if (isInProgress && hasTreatmentDetails) {
        final animalName = appointment.animalName.trim().isEmpty
            ? 'Animal'
            : appointment.animalName.trim();
        fullWidthCompleteButton = _actionButton(
          label: 'Complete $animalName Treatment',
          background: const Color(0xFF2E7D32),
          foreground: AppColors.white,
          onPressed: onComplete,
        );
      }
    }

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
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _animalImage(appointment.animalPhotoUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text(
                        'ID: ${appointment.displayAppointmentCode}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appointment.farmerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appointment.animalName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4E5A4E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appointment.address.trim().isEmpty ? '-' : appointment.address.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4E5A4E),
                        ),
                      ),
                      if (appointment.diseaseNames.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Disease: ${appointment.diseaseNames.join(', ')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4E5A4E),
                          ),
                        ),
                      ],
                      if (when != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${DateFormat('dd-MM-yyyy').format(when.toLocal())}  ${DateFormat('hh:mm a').format(when.toLocal())}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2F3A2F),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF7CB342).withValues(alpha: 0.6)),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Distance: $distanceLabel',
                            style: const TextStyle(
                              fontSize: 11.8,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _statusPill(status),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (showActionButtons)
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    label: 'Accept',
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
                    label: 'View More',
                    background: const Color(0xFFEAF5EA),
                    foreground: AppColors.primary,
                    onPressed: onViewMore,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showCornerDialer)
                  _buildActionRowWithCornerDialer(
                    actions: actionButtons,
                    dialerButton: _iconActionButton(
                      icon: Icons.phone,
                      background: const Color(0xFFEAF5EA),
                      foreground: AppColors.primary,
                      onPressed: onCall,
                      width: 34,
                    ),
                  )
                else
                  _buildActionGrid(actionButtons, columns: 3),
                if (fullWidthCompleteButton != null) ...[
                  const SizedBox(height: 8),
                  fullWidthCompleteButton,
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(List<Widget> actions, {int columns = 3}) {
    if (actions.isEmpty) return const SizedBox.shrink();
    final safeColumns = columns < 1 ? 1 : columns;
    final rows = <Widget>[];

    for (var start = 0; start < actions.length; start += safeColumns) {
      final end = (start + safeColumns) > actions.length ? actions.length : (start + safeColumns);
      final slice = actions.sublist(start, end);

      rows.add(
        Row(
          children: List.generate(safeColumns * 2 - 1, (index) {
            if (index.isOdd) return const SizedBox(width: 8);
            final columnIndex = index ~/ 2;
            if (columnIndex < slice.length) {
              return Expanded(child: slice[columnIndex]);
            }
            return const Expanded(child: SizedBox.shrink());
          }),
        ),
      );

      if (end < actions.length) {
        rows.add(const SizedBox(height: 8));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _buildActionRowWithCornerDialer({
    required List<Widget> actions,
    required Widget dialerButton,
  }) {
    final primaryActions = actions.take(3).toList();
    if (primaryActions.isEmpty) {
      return Align(alignment: Alignment.centerRight, child: dialerButton);
    }

    return Row(
      children: [
        for (var index = 0; index < primaryActions.length; index++) ...[
          Expanded(child: primaryActions[index]),
          if (index != primaryActions.length - 1) const SizedBox(width: 8),
        ],
        const SizedBox(width: 8),
        dialerButton,
      ],
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

  Widget _iconActionButton({
    required IconData icon,
    required Color background,
    required Color foreground,
    required VoidCallback onPressed,
    double width = 40,
  }) {
    return SizedBox(
      width: width,
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
        child: Icon(icon, size: 15),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10.6, fontWeight: FontWeight.w700),
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
    this.morning = false,
    this.afternoon = false,
    this.evening = false,
  })  : nameController = TextEditingController(text: name ?? ''),
        totalController = TextEditingController(text: total ?? '');

  final TextEditingController nameController;
  final TextEditingController totalController;
  bool morning;
  bool afternoon;
  bool evening;

  void dispose() {
    nameController.dispose();
    totalController.dispose();
  }
}

class _ParsedTreatmentData {
  const _ParsedTreatmentData({
    this.onsiteTreatments = const [],
    this.medicines = const [],
  });

  final List<String> onsiteTreatments;
  final List<_ParsedMedicineData> medicines;
}

class _ParsedMedicineData {
  const _ParsedMedicineData({
    required this.name,
    required this.total,
    required this.morning,
    required this.afternoon,
    required this.evening,
  });

  final String name;
  final String total;
  final bool morning;
  final bool afternoon;
  final bool evening;
}
