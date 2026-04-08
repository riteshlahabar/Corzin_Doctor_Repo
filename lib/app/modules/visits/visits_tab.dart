import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../home/home_controller.dart';

class VisitsTab extends StatelessWidget {
  const VisitsTab({
    super.key,
    required this.controller,
  });

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final completedVisits = controller.appointments
          .where((item) => item.normalizedStatus == 'completed')
          .toList()
        ..sort((a, b) {
          final first = a.completedAt ?? a.scheduledAt ?? a.requestedAt ?? DateTime(1970);
          final second = b.completedAt ?? b.scheduledAt ?? b.requestedAt ?? DateTime(1970);
          return second.compareTo(first);
        });

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
            if (controller.appointmentLoading.value)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (completedVisits.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _EmptyVisitCard(),
              )
            else
              ...completedVisits.map(
                (item) {
                  final completedAt = item.completedAt ?? item.scheduledAt ?? item.requestedAt;
                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4FAF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE4EFE4)),
                    ),
                    child: Row(
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
                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.animalName,
                                style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.concern,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                completedAt == null
                                    ? 'Completed'
                                    : 'Completed: ${DateFormat('dd MMM yyyy, hh:mm a').format(completedAt.toLocal())}',
                                style: const TextStyle(
                                  fontSize: 11.8,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      );
    });
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
