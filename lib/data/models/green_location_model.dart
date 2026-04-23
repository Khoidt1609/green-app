import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';  

enum GreenLocationType {
  recycling,    // Điểm thu gom
  charging,     // Trạm sạc điện
  greenMarket;  // Chợ xanh

  String get label {
    switch (this) {
      case GreenLocationType.recycling:
        return 'Điểm Thu Gom';
      case GreenLocationType.charging:
        return 'Trạm Sạc Điện';
      case GreenLocationType.greenMarket:
        return 'Chợ Xanh';
    }
  }

  String get emoji {
    switch (this) {
      case GreenLocationType.recycling:
        return '♻️';
      case GreenLocationType.charging:
        return '⚡';
      case GreenLocationType.greenMarket:
        return '🌿';
    }
  }

  static GreenLocationType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'recycling':
      case 'thu gom':
        return GreenLocationType.recycling;
      case 'charging':
      case 'sac dien':
        return GreenLocationType.charging;
      case 'greenmarket':
      case 'choxanh':
      case 'green market':
        return GreenLocationType.greenMarket;
      default:
        return GreenLocationType.recycling;
    }
  }
}

class GreenLocation {
  final String id;
  final String name;
  final LatLng position;           // ← latlong2
  final GreenLocationType type;
  final String? address;
  final String? description;
  final List<String> openHours;
  final String? phone;
  final String? imageUrl;

  const GreenLocation({
    required this.id,
    required this.name,
    required this.position,
    required this.type,
    this.address,
    this.description,
    this.openHours = const [],
    this.phone,
    this.imageUrl,
  });

  /// Factory tạo từ Firestore Document
  factory GreenLocation.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return GreenLocation(
      id: doc.id,
      name: data['name']?.toString() ?? 'Không có tên',
      position: LatLng(
        (data['latitude'] as num?)?.toDouble() ?? 0.0,
        (data['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      type: GreenLocationType.fromString(data['type']?.toString() ?? ''),
      address: data['address']?.toString(),
      description: data['description']?.toString(),
      openHours: List<String>.from(data['openHours'] ?? []),
      phone: data['phone']?.toString(),
      imageUrl: data['imageUrl']?.toString(),
    );
  }

  /// CopyWith (nếu cần dùng sau này)
  GreenLocation copyWith({
    String? name,
    LatLng? position,
    GreenLocationType? type,
    String? address,
    String? description,
    List<String>? openHours,
    String? phone,
    String? imageUrl,
  }) {
    return GreenLocation(
      id: id,
      name: name ?? this.name,
      position: position ?? this.position,
      type: type ?? this.type,
      address: address ?? this.address,
      description: description ?? this.description,
      openHours: openHours ?? this.openHours,
      phone: phone ?? this.phone,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}