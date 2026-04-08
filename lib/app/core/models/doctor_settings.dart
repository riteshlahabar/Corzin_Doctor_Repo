class DoctorBannerItem {
  DoctorBannerItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.imagePath,
    required this.sortOrder,
  });

  final int id;
  final String title;
  final String imageUrl;
  final String imagePath;
  final int sortOrder;

  factory DoctorBannerItem.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return DoctorBannerItem(
      id: parseInt(json['id']),
      title: (json['title'] ?? '').toString(),
      imageUrl: (json['image_url'] ?? '').toString(),
      imagePath: (json['image'] ?? '').toString(),
      sortOrder: parseInt(json['sort_order']),
    );
  }
}

class DoctorSettings {
  DoctorSettings({
    required this.termsAndConditions,
    required this.privacyPolicy,
    required this.banners,
  });

  final String termsAndConditions;
  final String privacyPolicy;
  final List<DoctorBannerItem> banners;

  factory DoctorSettings.fromJson(Map<String, dynamic> json) {
    final bannerList = (json['banners'] as List<dynamic>? ?? const [])
        .map((item) => DoctorBannerItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return DoctorSettings(
      termsAndConditions: (json['terms_and_conditions'] ?? json['terms_and_condition'] ?? '').toString(),
      privacyPolicy: (json['privacy_policy'] ?? '').toString(),
      banners: bannerList,
    );
  }
}

