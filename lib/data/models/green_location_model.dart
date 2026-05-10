// lib/data/models/green_location_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

// ─── Type enum ────────────────────────────────────────────────────────────────

enum GreenLocationType {
  recycling,    // Điểm thu gom / tái chế
  charging,     // Trạm sạc điện
  greenMarket;  // Chợ xanh

  String get label {
    switch (this) {
      case GreenLocationType.recycling:   return 'Điểm Thu Gom';
      case GreenLocationType.charging:    return 'Trạm Sạc Điện';
      case GreenLocationType.greenMarket: return 'Chợ Xanh';
    }
  }

  String get emoji {
    switch (this) {
      case GreenLocationType.recycling:   return '♻️';
      case GreenLocationType.charging:    return '⚡';
      case GreenLocationType.greenMarket: return '🌿';
    }
  }

  static GreenLocationType fromString(String value) {
    switch (value.toLowerCase().trim()) {
      case 'recycling':
      case 'thu gom':
      case 'tai che':
        return GreenLocationType.recycling;
      case 'charging':
      case 'sac dien':
      case 'ev':
        return GreenLocationType.charging;
      case 'greenmarket':
      case 'choxanh':
      case 'green market':
      case 'cho xanh':
        return GreenLocationType.greenMarket;
      default:
        return GreenLocationType.recycling;
    }
  }
}

// ─── Source enum ─────────────────────────────────────────────────────────────
// Dùng để phân biệt marker Firebase (admin) vs OpenStreetMap (auto)

enum LocationSource { firebase, osm }

// ─── Model ────────────────────────────────────────────────────────────────────

class GreenLocation {
  const GreenLocation({
    required this.id,
    required this.name,
    required this.position,
    required this.type,
    required this.source,
    this.address,
    this.description,
    this.openHours = const [],
    this.phone,
    this.imageUrl,
  });

  final String            id;
  final String            name;
  final LatLng            position;
  final GreenLocationType type;
  final LocationSource    source;   // firebase | osm
  final String?           address;
  final String?           description;
  final List<String>      openHours;
  final String?           phone;
  final String?           imageUrl;

  // ── Factory: từ Firestore ──────────────────────────────────────────────────
  factory GreenLocation.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return GreenLocation(
      id:          doc.id,
      name:        d['name']?.toString() ?? 'Không có tên',
      position: LatLng(
        (d['latitude']  as num?)?.toDouble() ?? 0.0,
        (d['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      type:        GreenLocationType.fromString(d['type']?.toString() ?? ''),
      source:      LocationSource.firebase,
      address:     d['address']?.toString(),
      description: d['description']?.toString(),
      openHours:   List<String>.from(d['openHours'] ?? []),
      phone:       d['phone']?.toString(),
      imageUrl:    d['imageUrl']?.toString(),
    );
  }

  // ── Factory: từ Overpass API element ──────────────────────────────────────
  factory GreenLocation.fromOsm(Map<String, dynamic> element, GreenLocationType type) {
    final tags = element['tags'] as Map<String, dynamic>? ?? {};

    // Lấy lat/lon — node có lat/lon trực tiếp, way/relation có center
    double lat = 0, lon = 0;
    if (element.containsKey('lat')) {
      lat = (element['lat'] as num).toDouble();
      lon = (element['lon'] as num).toDouble();
    } else if (element['center'] != null) {
      lat = (element['center']['lat'] as num).toDouble();
      lon = (element['center']['lon'] as num).toDouble();
    }

    // Tên — ưu tiên: name:vi → name → brand/operator → fallback label
    final rawName  = tags['name:vi'] ?? tags['name'];
    final brand    = tags['brand'] ?? tags['operator'];
    final isVinFast = brand?.toString().toLowerCase().contains('vinfast') == true;

    String name;
    if (rawName != null && rawName.toString().trim().isNotEmpty) {
      name = rawName.toString().trim();
      // Gắn thêm "VinFast" vào tên nếu chưa có
      if (isVinFast && !name.toLowerCase().contains('vinfast')) {
        name = 'VinFast – $name';
      }
    } else if (isVinFast) {
      name = 'Trạm Sạc VinFast';
    } else if (brand != null && brand.toString().trim().isNotEmpty) {
      name = brand.toString().trim();
    } else {
      name = type.label;
    }

    // Địa chỉ ghép từ OSM tags
    final addrParts = [
      tags['addr:housenumber'],
      tags['addr:street'],
      tags['addr:suburb'],
      tags['addr:city'],
    ].whereType<String>().where((s) => s.isNotEmpty).toList();
    final address = addrParts.isNotEmpty ? addrParts.join(', ') : null;

    // Giờ mở cửa
    final hours = tags['opening_hours'];

    // Số điện thoại
    final phone = tags['phone'] ?? tags['contact:phone'];

    // Mô tả thêm cho trạm sạc: số socket, công suất
    String? description;
    if (type == GreenLocationType.charging) {
      final parts = <String>[];
      if (tags['capacity'] != null) parts.add('${tags['capacity']} chỗ');
      if (tags['socket:type2'] != null) parts.add('Type 2');
      if (tags['socket:chademo'] != null) parts.add('CHAdeMO');
      if (tags['socket:ccs'] != null) parts.add('CCS');
      if (tags['maxpower'] != null) parts.add('${tags['maxpower']}kW');
      if (isVinFast) parts.add('VinFast');
      if (parts.isNotEmpty) description = parts.join(' · ');
    }

    return GreenLocation(
      id:          'osm_${element['type']}_${element['id']}',
      name:        name,
      position:    LatLng(lat, lon),
      type:        type,
      source:      LocationSource.osm,
      address:     address,
      description: description ?? tags['description'] ?? tags['note'],
      openHours:   hours != null ? [hours.toString()] : [],
      phone:       phone?.toString(),
      imageUrl:    null,
    );
  }

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
      id:          id,
      name:        name ?? this.name,
      position:    position ?? this.position,
      type:        type ?? this.type,
      source:      source,
      address:     address ?? this.address,
      description: description ?? this.description,
      openHours:   openHours ?? this.openHours,
      phone:       phone ?? this.phone,
      imageUrl:    imageUrl ?? this.imageUrl,
    );
  }
}