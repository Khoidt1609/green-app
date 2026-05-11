class AddressModel {
  final String district;
  final String city;

  const AddressModel({
    required this.district,
    required this.city,
  });

  // =========================================================
  // COPY WITH
  // =========================================================

  AddressModel copyWith({
    String? district,
    String? city,
  }) {
    return AddressModel(
      district: district ?? this.district,
      city: city ?? this.city,
    );
  }

  // =========================================================
  // TO MAP
  // =========================================================

  Map<String, dynamic> toMap() {
    return {
      'district': district.trim(),
      'city': city.trim(),
    };
  }

  // =========================================================
  // FROM MAP
  // =========================================================

  factory AddressModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return AddressModel.empty();
    }

    return AddressModel(
      district: (map['district'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
    );
  }

  // =========================================================
  // EMPTY
  // =========================================================

  factory AddressModel.empty() {
    return const AddressModel(
      district: '',
      city: '',
    );
  }

  // =========================================================
  // HELPERS
  // =========================================================

  bool get isEmpty =>
      district.trim().isEmpty && city.trim().isEmpty;

  bool get isNotEmpty => !isEmpty;

  String get fullAddress {
    if (district.trim().isEmpty && city.trim().isEmpty) {
      return '';
    }

    if (district.trim().isEmpty) {
      return city;
    }

    if (city.trim().isEmpty) {
      return district;
    }

    return '$district, $city';
  }

  @override
  String toString() {
    return 'AddressModel('
        'district: $district, '
        'city: $city'
        ')';
  }
}