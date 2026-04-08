class DoctorProfile {
  DoctorProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.clinicName,
    required this.degree,
    required this.contactNumber,
    required this.email,
    required this.adharNumber,
    required this.panNumber,
    required this.mmcRegistrationNumber,
    required this.clinicRegistrationNumber,
    required this.clinicAddress,
    required this.village,
    required this.city,
    required this.taluka,
    required this.district,
    required this.state,
    required this.pincode,
    required this.status,
    required this.termsText,
    required this.photoUrl,
    required this.documents,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String clinicName;
  final String degree;
  final String contactNumber;
  final String email;
  final String adharNumber;
  final String panNumber;
  final String mmcRegistrationNumber;
  final String clinicRegistrationNumber;
  final String clinicAddress;
  final String village;
  final String city;
  final String taluka;
  final String district;
  final String state;
  final String pincode;
  final String status;
  final String termsText;
  final String photoUrl;
  final Map<String, String> documents;

  String get fullName => [firstName, lastName]
      .where((part) => part.trim().isNotEmpty)
      .join(' ');

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    return DoctorProfile(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      clinicName: json['clinic_name'] ?? '',
      degree: json['degree'] ?? '',
      contactNumber: json['contact_number'] ?? '',
      email: json['email'] ?? '',
      adharNumber: json['adhar_number'] ?? '',
      panNumber: json['pan_number'] ?? '',
      mmcRegistrationNumber: json['mmc_registration_number'] ?? '',
      clinicRegistrationNumber: json['clinic_registration_number'] ?? '',
      clinicAddress: json['clinic_address'] ?? '',
      village: json['village'] ?? '',
      city: json['city'] ?? '',
      taluka: json['taluka'] ?? '',
      district: json['district'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      status: json['status'] ?? 'pending',
      termsText: json['terms_text'] ?? '',
      photoUrl: json['doctor_photo_url'] ?? '',
      documents: Map<String, String>.from(json['documents'] ?? const {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'clinic_name': clinicName,
      'degree': degree,
      'contact_number': contactNumber,
      'email': email,
      'adhar_number': adharNumber,
      'pan_number': panNumber,
      'mmc_registration_number': mmcRegistrationNumber,
      'clinic_registration_number': clinicRegistrationNumber,
      'clinic_address': clinicAddress,
      'village': village,
      'city': city,
      'taluka': taluka,
      'district': district,
      'state': state,
      'pincode': pincode,
      'status': status,
      'terms_text': termsText,
      'doctor_photo_url': photoUrl,
      'documents': documents,
    };
  }
}
