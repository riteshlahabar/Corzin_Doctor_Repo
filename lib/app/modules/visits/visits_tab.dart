import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/models/doctor_appointment.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_controller.dart';

enum _VisitFilter { all, today, yesterday, date }

class VisitsTab extends StatefulWidget {
  const VisitsTab({
    super.key,
    required this.controller,
  });

  final HomeController controller;

  @override
  State<VisitsTab> createState() => _VisitsTabState();
}

class _VisitsTabState extends State<VisitsTab> {
  _VisitFilter _activeFilter = _VisitFilter.today;
  DateTime? _selectedDate;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final completedVisits = widget.controller.appointments
          .where((item) => item.normalizedStatus == 'completed')
          .toList()
        ..sort((a, b) {
          final first = a.completedAt ?? a.scheduledAt ?? a.requestedAt ?? DateTime(1970);
          final second = b.completedAt ?? b.scheduledAt ?? b.requestedAt ?? DateTime(1970);
          return second.compareTo(first);
        });

      final filteredVisits = _applyFilters(completedVisits);

      return RefreshIndicator(
        onRefresh: widget.controller.refreshAppointments,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 8, 18, 14),
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
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search by farmer, animal, or appointment ID',
                  hintStyle: TextStyle(fontSize: 11.5),
                  prefixIcon: Icon(Icons.search_rounded),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  constraints: BoxConstraints(minHeight: 38, maxHeight: 38),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _filterPill(
                    label: 'Today',
                    selected: _activeFilter == _VisitFilter.today,
                    onTap: () => setState(() {
                      _activeFilter = _VisitFilter.today;
                      _selectedDate = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _filterPill(
                    label: 'Yesterday',
                    selected: _activeFilter == _VisitFilter.yesterday,
                    onTap: () => setState(() {
                      _activeFilter = _VisitFilter.yesterday;
                      _selectedDate = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _filterPill(
                    label: 'All',
                    selected: _activeFilter == _VisitFilter.all,
                    onTap: () => setState(() {
                      _activeFilter = _VisitFilter.all;
                      _selectedDate = null;
                    }),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _pickDateFilter,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 34,
                      width: 34,
                      decoration: BoxDecoration(
                        color: _activeFilter == _VisitFilter.date ? AppColors.primary : const Color(0xFFEAF3EA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _activeFilter == _VisitFilter.date ? AppColors.primary : const Color(0xFFD8E7D8),
                        ),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        size: 18,
                        color: _activeFilter == _VisitFilter.date ? AppColors.white : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_activeFilter == _VisitFilter.date && _selectedDate != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Text(
                  'Date: ${DateFormat('dd MMM yyyy').format(_selectedDate!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            if (widget.controller.appointmentLoading.value)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filteredVisits.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _EmptyVisitCard(),
              )
            else
              ...filteredVisits.map((item) {
                final completedAt = item.completedAt ?? item.scheduledAt ?? item.requestedAt;
                final treatmentOnly = _extractTreatmentOnly(item.treatmentDetails);

                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4FAF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE4EFE4)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _visitImage(item.animalPhotoUrl),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.farmerName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.animalName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Appointment ID: ${item.displayAppointmentCode}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.concern,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
                                  ),
                                  if (treatmentOnly.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Treatment: $treatmentOnly',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: AppColors.grey),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                completedAt == null
                                    ? 'Completed'
                                    : 'Completed: ${DateFormat('dd MMM yyyy, hh:mm a').format(completedAt.toLocal())}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.8,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => _openVisitDetails(context, item, completedAt),
                              child: const Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Text(
                                  'View more',
                                  style: TextStyle(
                                    fontSize: 12.2,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              }),
          ],
        ),
      );
    });
  }

  List<DoctorAppointment> _applyFilters(List<DoctorAppointment> visits) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    return visits.where((item) {
      final when = (item.completedAt ?? item.scheduledAt ?? item.requestedAt)?.toLocal();
      if (when == null) return false;
      final date = DateTime(when.year, when.month, when.day);
      final searchTarget =
          '${item.farmerName} ${item.animalName} ${item.displayAppointmentCode} ${item.concern}'.toLowerCase();

      if (_searchQuery.isNotEmpty && !searchTarget.contains(_searchQuery)) {
        return false;
      }

      if (_activeFilter == _VisitFilter.today) {
        return date == today;
      }
      if (_activeFilter == _VisitFilter.yesterday) {
        return date == yesterday;
      }
      if (_activeFilter == _VisitFilter.date && _selectedDate != null) {
        final selected = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
        return date == selected;
      }
      if (_activeFilter == _VisitFilter.all) {
        return true;
      }
      return false;
    }).toList();
  }

  Future<void> _pickDateFilter() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
        _activeFilter = _VisitFilter.date;
      });
    }
  }

  Widget _filterPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFEAF3EA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : const Color(0xFFD8E7D8)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }

  String _extractOnsiteTreatment(String raw) {
    final lines = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    for (final line in lines) {
      if (line.toLowerCase().startsWith('on-site-treatment:')) {
        return line.split(':').skip(1).join(':').trim();
      }
    }
    return '';
  }

  String _extractTreatmentOnly(String raw) {
    final lines = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .where((e) => !e.toLowerCase().startsWith('on-site-treatment:'))
        .toList();
    return lines.join(' | ');
  }

  Widget _visitImage(String source) {
    final image = source.trim().isEmpty ? 'assets/images/available_doctor_2nd.png' : source.trim();
    final isNetwork = image.startsWith('http://') || image.startsWith('https://');
    if (isNetwork) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          image,
          height: 72,
          width: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        image,
        height: 72,
        width: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      height: 72,
      width: 72,
      color: const Color(0xFFE4EFE4),
      child: const Icon(Icons.pets_rounded, color: AppColors.grey),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label: $value',
        softWrap: true,
        style: const TextStyle(fontSize: 12, color: AppColors.grey),
      ),
    );
  }

  Future<void> _openVisitDetails(
    BuildContext context,
    DoctorAppointment item,
    DateTime? completedAt,
  ) async {
    final onsiteTreatment = _extractOnsiteTreatment(item.treatmentDetails);
    final treatmentOnly = _extractTreatmentOnly(item.treatmentDetails);

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
                    'Visit Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  _detailRow('Farmer', item.farmerName),
                  _detailRow('Animal', item.animalName),
                  _detailRow('Appointment ID', item.displayAppointmentCode),
                  if (item.diseaseNames.isNotEmpty) _detailRow('Disease', item.diseaseNames.join(', ')),
                  if (treatmentOnly.isNotEmpty) _detailRow('Treatment', treatmentOnly),
                  if (onsiteTreatment.isNotEmpty) _detailRow('On-Site-Treatment', onsiteTreatment),
                  if (item.notes.trim().isNotEmpty) _detailRow('Notes', item.notes),
                  if (item.nextFollowupDate != null)
                    _detailRow('Next Follow-up', DateFormat('dd MMM yyyy').format(item.nextFollowupDate!.toLocal())),
                  if (item.charges != null) _detailRow('Charges', 'Rs ${item.charges!.toStringAsFixed(0)}'),
                  _detailRow(
                    'Completed At',
                    completedAt == null
                        ? '-'
                        : DateFormat('dd MMM yyyy, hh:mm a').format(completedAt.toLocal()),
                  ),
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
}

class _EmptyVisitCard extends StatelessWidget {
  const _EmptyVisitCard();

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
      child: const Text(
        'No completed visits yet.',
        style: TextStyle(fontSize: 13, color: AppColors.grey),
      ),
    );
  }
}
