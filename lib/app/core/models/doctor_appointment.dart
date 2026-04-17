class DoctorAppointment {
  DoctorAppointment({
    required this.id,
    required this.farmerName,
    required this.animalName,
    required this.concern,
    required this.status,
    this.requestedAt,
    this.scheduledAt,
    this.completedAt,
    this.otpVerifiedAt,
    this.treatmentStartedAt,
    this.doctorLiveUpdatedAt,
    this.charges,
    this.animalPhotoUrl = '',
    this.latitude,
    this.longitude,
    this.doctorLiveLatitude,
    this.doctorLiveLongitude,
    this.address = '',
    this.farmerPhone = '',
    this.notes = '',
    this.diseaseNames = const [],
    this.diseaseDetails = '',
    this.treatmentDetails = '',
    this.followupRequired = false,
    this.nextFollowupDate,
    this.visitOtp = '',
    this.appointmentCode = '',
    this.previousHistories = const [],
    this.recentMilkHistory = const [],
    this.recentFeedingHistory = const [],
    this.recentPregnancyHistory = const [],
  });

  final int id;
  final String farmerName;
  final String animalName;
  final String concern;
  final String status;
  final DateTime? requestedAt;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final DateTime? otpVerifiedAt;
  final DateTime? treatmentStartedAt;
  final DateTime? doctorLiveUpdatedAt;
  final double? charges;
  final String animalPhotoUrl;
  final double? latitude;
  final double? longitude;
  final double? doctorLiveLatitude;
  final double? doctorLiveLongitude;
  final String address;
  final String farmerPhone;
  final String notes;
  final List<String> diseaseNames;
  final String diseaseDetails;
  final String treatmentDetails;
  final bool followupRequired;
  final DateTime? nextFollowupDate;
  final String visitOtp;
  final String appointmentCode;
  final List<DoctorAppointmentHistory> previousHistories;
  final List<DoctorAppointmentMilkHistory> recentMilkHistory;
  final List<DoctorAppointmentFeedingHistory> recentFeedingHistory;
  final List<DoctorAppointmentPregnancyHistory> recentPregnancyHistory;

  String get normalizedStatus => status.trim().toLowerCase();

  String get displayAppointmentCode {
    final code = appointmentCode.trim();
    if (code.isNotEmpty) return code;
    return 'C/APP/${id.toString().padLeft(2, '0')}';
  }

  String get statusLabel {
    switch (normalizedStatus) {
      case 'followup':
      case 'follow_up':
        return 'Follow-up';
      case 'pending':
      case 'requested':
      case 'new':
        return 'Pending';
      case 'rescheduled':
        return 'Accept';
      case 'declined':
      case 'rejected':
        return 'Declined';
      case 'proposed':
      case 'awaiting_farmer_approval':
      case 'awaiting_approval':
        return 'Waiting For Farmer Approval';
      case 'approved':
      case 'farmer_approved':
      case 'scheduled':
        return 'Accept';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.isEmpty ? 'Pending' : status;
    }
  }

  bool get canFixAppointment {
    return {'pending', 'requested', 'new'}.contains(normalizedStatus);
  }

  bool get waitingForFarmerApproval {
    return {'proposed', 'awaiting_farmer_approval', 'awaiting_approval'}.contains(normalizedStatus);
  }

  bool get canNavigate {
    return {'approved', 'farmer_approved', 'scheduled', 'in_progress', 'followup', 'follow_up'}
        .contains(normalizedStatus);
  }

  bool get canComplete {
    return {'in_progress'}.contains(normalizedStatus);
  }

  bool get needsOtpVerification {
    return {'approved', 'farmer_approved', 'scheduled'}.contains(normalizedStatus) && otpVerifiedAt == null;
  }

  bool get canStartTreatment {
    return {'approved', 'farmer_approved', 'scheduled'}.contains(normalizedStatus) && otpVerifiedAt != null;
  }

  DoctorAppointment copyWith({
    int? id,
    String? farmerName,
    String? animalName,
    String? concern,
    String? status,
    DateTime? requestedAt,
    DateTime? scheduledAt,
    DateTime? completedAt,
    DateTime? otpVerifiedAt,
    DateTime? treatmentStartedAt,
    DateTime? doctorLiveUpdatedAt,
    double? charges,
    String? animalPhotoUrl,
    double? latitude,
    double? longitude,
    double? doctorLiveLatitude,
    double? doctorLiveLongitude,
    String? address,
    String? farmerPhone,
    String? notes,
    List<String>? diseaseNames,
    String? diseaseDetails,
    String? treatmentDetails,
    bool? followupRequired,
    DateTime? nextFollowupDate,
    String? visitOtp,
    String? appointmentCode,
    List<DoctorAppointmentHistory>? previousHistories,
    List<DoctorAppointmentMilkHistory>? recentMilkHistory,
    List<DoctorAppointmentFeedingHistory>? recentFeedingHistory,
    List<DoctorAppointmentPregnancyHistory>? recentPregnancyHistory,
  }) {
    return DoctorAppointment(
      id: id ?? this.id,
      farmerName: farmerName ?? this.farmerName,
      animalName: animalName ?? this.animalName,
      concern: concern ?? this.concern,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      completedAt: completedAt ?? this.completedAt,
      otpVerifiedAt: otpVerifiedAt ?? this.otpVerifiedAt,
      treatmentStartedAt: treatmentStartedAt ?? this.treatmentStartedAt,
      doctorLiveUpdatedAt: doctorLiveUpdatedAt ?? this.doctorLiveUpdatedAt,
      charges: charges ?? this.charges,
      animalPhotoUrl: animalPhotoUrl ?? this.animalPhotoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      doctorLiveLatitude: doctorLiveLatitude ?? this.doctorLiveLatitude,
      doctorLiveLongitude: doctorLiveLongitude ?? this.doctorLiveLongitude,
      address: address ?? this.address,
      farmerPhone: farmerPhone ?? this.farmerPhone,
      notes: notes ?? this.notes,
      diseaseNames: diseaseNames ?? this.diseaseNames,
      diseaseDetails: diseaseDetails ?? this.diseaseDetails,
      treatmentDetails: treatmentDetails ?? this.treatmentDetails,
      followupRequired: followupRequired ?? this.followupRequired,
      nextFollowupDate: nextFollowupDate ?? this.nextFollowupDate,
      visitOtp: visitOtp ?? this.visitOtp,
      appointmentCode: appointmentCode ?? this.appointmentCode,
      previousHistories: previousHistories ?? this.previousHistories,
      recentMilkHistory: recentMilkHistory ?? this.recentMilkHistory,
      recentFeedingHistory: recentFeedingHistory ?? this.recentFeedingHistory,
      recentPregnancyHistory: recentPregnancyHistory ?? this.recentPregnancyHistory,
    );
  }

  factory DoctorAppointment.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      final raw = value.toString().trim();
      if (raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    String parseFarmerFullName() {
      final farmerRaw = json['farmer'];
      final farmer = farmerRaw is Map
          ? farmerRaw.map((key, value) => MapEntry(key.toString(), value))
          : const <String, dynamic>{};

      final first = (json['farmer_first_name'] ??
              json['first_name'] ??
              farmer['first_name'] ??
              farmer['name_first'] ??
              '')
          .toString()
          .trim();
      final middle = (json['farmer_middle_name'] ??
              json['middle_name'] ??
              farmer['middle_name'] ??
              farmer['name_middle'] ??
              '')
          .toString()
          .trim();
      final last = (json['farmer_last_name'] ??
              json['last_name'] ??
              farmer['last_name'] ??
              farmer['name_last'] ??
              '')
          .toString()
          .trim();
      final combined = [first, middle, last].where((part) => part.isNotEmpty).join(' ').trim();
      if (combined.isNotEmpty) return combined;

      final full = (json['farmer_name'] ??
              json['farmerName'] ??
              json['full_name'] ??
              farmer['full_name'] ??
              farmer['name'] ??
              '')
          .toString()
          .trim();
      return full;
    }

    final diseaseNames = <String>[];
    final diseasesRaw = json['diseases'];
    if (diseasesRaw is List) {
      for (final row in diseasesRaw) {
        if (row is Map && row['name'] != null) {
          final name = row['name'].toString().trim();
          if (name.isNotEmpty) {
            diseaseNames.add(name);
          }
        }
      }
    }

    final previousHistories = <DoctorAppointmentHistory>[];
    final rawHistories = json['previous_histories'];
    if (rawHistories is List) {
      for (final row in rawHistories) {
        if (row is Map<String, dynamic>) {
          previousHistories.add(DoctorAppointmentHistory.fromJson(row));
        } else if (row is Map) {
          previousHistories.add(
            DoctorAppointmentHistory.fromJson(
              row.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        }
      }
    }

    final recentMilkHistory = <DoctorAppointmentMilkHistory>[];
    final rawMilk = json['recent_milk_history'];
    if (rawMilk is List) {
      for (final row in rawMilk) {
        if (row is Map<String, dynamic>) {
          recentMilkHistory.add(DoctorAppointmentMilkHistory.fromJson(row));
        } else if (row is Map) {
          recentMilkHistory.add(
            DoctorAppointmentMilkHistory.fromJson(
              row.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        }
      }
    }

    final recentFeedingHistory = <DoctorAppointmentFeedingHistory>[];
    final rawFeeding = json['recent_feeding_history'];
    if (rawFeeding is List) {
      for (final row in rawFeeding) {
        if (row is Map<String, dynamic>) {
          recentFeedingHistory.add(DoctorAppointmentFeedingHistory.fromJson(row));
        } else if (row is Map) {
          recentFeedingHistory.add(
            DoctorAppointmentFeedingHistory.fromJson(
              row.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        }
      }
    }

    final recentPregnancyHistory = <DoctorAppointmentPregnancyHistory>[];
    final rawPregnancy = json['recent_pregnancy_history'];
    if (rawPregnancy is List) {
      for (final row in rawPregnancy) {
        if (row is Map<String, dynamic>) {
          recentPregnancyHistory.add(DoctorAppointmentPregnancyHistory.fromJson(row));
        } else if (row is Map) {
          recentPregnancyHistory.add(
            DoctorAppointmentPregnancyHistory.fromJson(
              row.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        }
      }
    }

    return DoctorAppointment(
      id: parseInt(json['id']),
      farmerName: parseFarmerFullName(),
      animalName: (json['animal_name'] ?? json['animalName'] ?? '').toString(),
      concern: (json['concern'] ?? json['reason'] ?? '').toString(),
      status: (json['effective_status'] ?? json['status'] ?? 'pending').toString(),
      requestedAt: parseDate(json['requested_at'] ?? json['created_at']),
      scheduledAt: parseDate(json['scheduled_at'] ?? json['appointment_at']),
      completedAt: parseDate(json['completed_at']),
      otpVerifiedAt: parseDate(json['otp_verified_at']),
      treatmentStartedAt: parseDate(json['treatment_started_at']),
      doctorLiveUpdatedAt: parseDate(json['doctor_live_updated_at']),
      charges: parseDouble(json['charges']),
      animalPhotoUrl: (json['animal_photo_url'] ?? json['animal_photo'] ?? json['animal_image'] ?? json['cow_photo'] ?? '').toString(),
      latitude: parseDouble(json['latitude'] ?? json['lat']),
      longitude: parseDouble(json['longitude'] ?? json['lng']),
      doctorLiveLatitude: parseDouble(json['doctor_live_latitude']),
      doctorLiveLongitude: parseDouble(json['doctor_live_longitude']),
      address: (json['address'] ?? '').toString(),
      farmerPhone: (json['farmer_phone'] ?? json['phone'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
      diseaseNames: diseaseNames,
      diseaseDetails: (json['disease_details'] ?? '').toString(),
      treatmentDetails: (json['treatment_details'] ?? '').toString(),
      followupRequired: json['followup_required'] == true || json['followup_required'].toString() == '1',
      nextFollowupDate: parseDate(json['next_followup_date']),
      visitOtp: (json['visit_otp'] ?? '').toString(),
      appointmentCode: (json['appointment_code'] ?? '').toString(),
      previousHistories: previousHistories,
      recentMilkHistory: recentMilkHistory,
      recentFeedingHistory: recentFeedingHistory,
      recentPregnancyHistory: recentPregnancyHistory,
    );
  }
}

class DoctorAppointmentHistory {
  DoctorAppointmentHistory({
    required this.id,
    required this.concern,
    required this.treatmentDetails,
    required this.onsiteTreatment,
    required this.notes,
    this.completedAt,
  });

  final int id;
  final String concern;
  final String treatmentDetails;
  final String onsiteTreatment;
  final String notes;
  final DateTime? completedAt;

  factory DoctorAppointmentHistory.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      final raw = value.toString().trim();
      if (raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return DoctorAppointmentHistory(
      id: parseInt(json['id']),
      concern: (json['concern'] ?? '').toString(),
      treatmentDetails: (json['treatment_details'] ?? '').toString(),
      onsiteTreatment: (json['onsite_treatment'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
      completedAt: parseDate(json['completed_at']),
    );
  }
}

class DoctorAppointmentMilkHistory {
  DoctorAppointmentMilkHistory({
    required this.date,
    this.totalMilk,
    this.fat,
    this.snf,
  });

  final DateTime? date;
  final double? totalMilk;
  final double? fat;
  final double? snf;

  factory DoctorAppointmentMilkHistory.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      final raw = value.toString().trim();
      if (raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return DoctorAppointmentMilkHistory(
      date: parseDate(json['date']),
      totalMilk: parseDouble(json['total_milk']),
      fat: parseDouble(json['fat']),
      snf: parseDouble(json['snf']),
    );
  }
}

class DoctorAppointmentFeedingHistory {
  DoctorAppointmentFeedingHistory({
    required this.date,
    required this.feedingTime,
    required this.feedType,
    this.quantity,
    this.unit = '',
    this.notes = '',
  });

  final DateTime? date;
  final String feedingTime;
  final String feedType;
  final double? quantity;
  final String unit;
  final String notes;

  factory DoctorAppointmentFeedingHistory.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      final raw = value.toString().trim();
      if (raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return DoctorAppointmentFeedingHistory(
      date: parseDate(json['date']),
      feedingTime: (json['feeding_time'] ?? '').toString(),
      feedType: (json['feed_type'] ?? '').toString(),
      quantity: parseDouble(json['quantity']),
      unit: (json['unit'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
    );
  }
}

class DoctorAppointmentPregnancyHistory {
  DoctorAppointmentPregnancyHistory({
    this.aiDate,
    this.calvingDate,
    required this.pregnancyConfirmation,
    this.breedName = '',
    this.notes = '',
  });

  final DateTime? aiDate;
  final DateTime? calvingDate;
  final bool pregnancyConfirmation;
  final String breedName;
  final String notes;

  factory DoctorAppointmentPregnancyHistory.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      final raw = value.toString().trim();
      if (raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    return DoctorAppointmentPregnancyHistory(
      aiDate: parseDate(json['ai_date']),
      calvingDate: parseDate(json['calving_date']),
      pregnancyConfirmation: json['pregnancy_confirmation'] == true || json['pregnancy_confirmation'].toString() == '1',
      breedName: (json['breed_name'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
    );
  }
}
