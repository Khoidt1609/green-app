class AddressModel {
  final String district;
  final String city;

  AddressModel({
    required this.district,
    required this.city,
  });

  AddressModel copyWith({
    String? district,
    String? city,
  }) {
    return AddressModel(
      district: district ?? this.district,
      city: city ?? this.city,
    );
  }

  Map<String, dynamic> toMap() => {
    'district': district,
    'city': city,
  };

  factory AddressModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return AddressModel(district: '', city: '');
    return AddressModel(
      district: map['district'] ?? '',
      city: map['city'] ?? '',
    );
  }
}