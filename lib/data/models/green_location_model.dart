// lib/data/models/green_location_model.dart

import 'package:latlong2/latlong.dart';

// ─────────────────────────────────────────────────────────────
// TYPE ENUM
// ─────────────────────────────────────────────────────────────

enum GreenLocationType {
  recycling,
  charging,
  greenMarket;

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

  static GreenLocationType fromString(
    String value,
  ) {
    switch (
        value.toLowerCase().trim()) {
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

// ─────────────────────────────────────────────────────────────
// SOURCE ENUM
// ─────────────────────────────────────────────────────────────

enum LocationSource {
  osm,
}

// ─────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────

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

  final String id;

  final String name;

  final LatLng position;

  final GreenLocationType type;

  final LocationSource source;

  final String? address;

  final String? description;

  final List<String> openHours;

  final String? phone;

  final String? imageUrl;

  // ─────────────────────────────────────────────────────────────
  // FACTORY: OSM
  // ─────────────────────────────────────────────────────────────

  factory GreenLocation.fromOsm(
    Map<String, dynamic> element,
    GreenLocationType type,
  ) {
    final tags =
        element['tags']
                as Map<String, dynamic>? ??
            {};

    // lat lon

    double lat = 0;
    double lon = 0;

    // node

    if (element.containsKey('lat')) {
      lat =
          (element['lat'] as num).toDouble();

      lon =
          (element['lon'] as num).toDouble();
    }

    // way

    else if (element['center'] != null) {
      lat = (element['center']['lat']
              as num)
          .toDouble();

      lon = (element['center']['lon']
              as num)
          .toDouble();
    }

    // ─────────────────────────────────────────────────────────
    // NAME
    // ─────────────────────────────────────────────────────────

    final rawName =
        tags['name:vi'] ??
            tags['name'];

    final brand =
        tags['brand'] ??
            tags['operator'];

    final isVinFast =
        brand
                ?.toString()
                .toLowerCase()
                .contains('vinfast') ==
            true;

    String name;

    if (rawName != null &&
        rawName
            .toString()
            .trim()
            .isNotEmpty) {
      name = rawName.toString().trim();

      // thêm VinFast nếu chưa có

      if (isVinFast &&
          !name
              .toLowerCase()
              .contains('vinfast')) {
        name = 'VinFast – $name';
      }
    } else if (isVinFast) {
      name = 'Trạm Sạc VinFast';
    } else if (brand != null &&
        brand
            .toString()
            .trim()
            .isNotEmpty) {
      name = brand.toString().trim();
    } else {
      name = type.label;
    }

    // ─────────────────────────────────────────────────────────
    // ADDRESS
    // ─────────────────────────────────────────────────────────

    final addrParts = [
      tags['addr:housenumber'],
      tags['addr:street'],
      tags['addr:suburb'],
      tags['addr:city'],
    ]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();

    final address = addrParts.isNotEmpty
        ? addrParts.join(', ')
        : null;

    // ─────────────────────────────────────────────────────────
    // HOURS
    // ─────────────────────────────────────────────────────────

    final hours =
        tags['opening_hours'];

    // ─────────────────────────────────────────────────────────
    // PHONE
    // ─────────────────────────────────────────────────────────

    final phone =
        tags['phone'] ??
            tags['contact:phone'];

    // ─────────────────────────────────────────────────────────
    // DESCRIPTION
    // ─────────────────────────────────────────────────────────

    String? description;

    if (type ==
        GreenLocationType.charging) {
      final parts = <String>[];

      if (tags['capacity'] != null) {
        parts.add(
          '${tags['capacity']} chỗ',
        );
      }

      if (tags['socket:type2'] != null) {
        parts.add('Type 2');
      }

      if (tags['socket:chademo'] != null) {
        parts.add('CHAdeMO');
      }

      if (tags['socket:ccs'] != null) {
        parts.add('CCS');
      }

      if (tags['maxpower'] != null) {
        parts.add(
          '${tags['maxpower']}kW',
        );
      }

      if (isVinFast) {
        parts.add('VinFast');
      }

      if (parts.isNotEmpty) {
        description = parts.join(' · ');
      }
    }

    return GreenLocation(
      id:
          'osm_${element['type']}_${element['id']}',

      name: name,

      position: LatLng(
        lat,
        lon,
      ),

      type: type,

      source: LocationSource.osm,

      address: address,

      description:
          description ??
              tags['description'] ??
              tags['note'],

      openHours: hours != null
          ? [hours.toString()]
          : [],

      phone: phone?.toString(),

      imageUrl: null,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // COPY WITH
  // ─────────────────────────────────────────────────────────────

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

      position:
          position ?? this.position,

      type: type ?? this.type,

      source: source,

      address:
          address ?? this.address,

      description:
          description ??
              this.description,

      openHours:
          openHours ?? this.openHours,

      phone: phone ?? this.phone,

      imageUrl:
          imageUrl ?? this.imageUrl,
    );
  }
}