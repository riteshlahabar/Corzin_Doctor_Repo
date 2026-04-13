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

  String get normalizedStatus => status.trim().toLowerCase();

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
        return 'Rescheduled';
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
        return 'Approved';
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
    return {'approved', 'farmer_approved', 'scheduled', 'in_progress', 'rescheduled', 'followup', 'follow_up'}
        .contains(normalizedStatus);
  }

  bool get canComplete {
    return {'in_progress'}.contains(normalizedStatus);
  }

  bool get needsOtpVerification {
    return {'approved', 'farmer_approved', 'scheduled', 'rescheduled'}.contains(normalizedStatus) && otpVerifiedAt == null;
  }

  bool get canStartTreatment {
    return {'approved', 'farmer_approved', 'scheduled', 'rescheduled'}.contains(normalizedStatus) && otpVerifiedAt != null;
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

    return DoctorAppointment(
      id: parseInt(json['id']),
      farmerName: (json['farmer_name'] ?? json['farmerName'] ?? '').toString(),
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
    );
  }
}
