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
    this.charges,
    this.animalPhotoUrl = '',
    this.latitude,
    this.longitude,
    this.address = '',
    this.farmerPhone = '',
    this.notes = '',
  });

  final int id;
  final String farmerName;
  final String animalName;
  final String concern;
  final String status;
  final DateTime? requestedAt;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final double? charges;
  final String animalPhotoUrl;
  final double? latitude;
  final double? longitude;
  final String address;
  final String farmerPhone;
  final String notes;

  String get normalizedStatus => status.trim().toLowerCase();

  String get statusLabel {
    switch (normalizedStatus) {
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
    return {'approved', 'farmer_approved', 'scheduled', 'in_progress', 'rescheduled'}.contains(normalizedStatus);
  }

  bool get canComplete {
    return {'approved', 'farmer_approved', 'scheduled', 'in_progress'}.contains(normalizedStatus);
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
    double? charges,
    String? animalPhotoUrl,
    double? latitude,
    double? longitude,
    String? address,
    String? farmerPhone,
    String? notes,
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
      charges: charges ?? this.charges,
      animalPhotoUrl: animalPhotoUrl ?? this.animalPhotoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      farmerPhone: farmerPhone ?? this.farmerPhone,
      notes: notes ?? this.notes,
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

    return DoctorAppointment(
      id: parseInt(json['id']),
      farmerName: (json['farmer_name'] ?? json['farmerName'] ?? '').toString(),
      animalName: (json['animal_name'] ?? json['animalName'] ?? '').toString(),
      concern: (json['concern'] ?? json['reason'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      requestedAt: parseDate(json['requested_at'] ?? json['created_at']),
      scheduledAt: parseDate(json['scheduled_at'] ?? json['appointment_at']),
      completedAt: parseDate(json['completed_at']),
      charges: parseDouble(json['charges']),
      animalPhotoUrl: (json['animal_photo_url'] ?? json['animal_photo'] ?? json['animal_image'] ?? json['cow_photo'] ?? '').toString(),
      latitude: parseDouble(json['latitude'] ?? json['lat']),
      longitude: parseDouble(json['longitude'] ?? json['lng']),
      address: (json['address'] ?? '').toString(),
      farmerPhone: (json['farmer_phone'] ?? json['phone'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
    );
  }
}
