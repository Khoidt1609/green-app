// lib/data/repositories/map_repository.dart

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/green_location_model.dart';

// ─────────────────────────────────────────────────────────────
// OVERPASS API
// ─────────────────────────────────────────────────────────────

const _kOverpassUrl =
    'https://overpass-api.de/api/interpreter';

// bán kính 5km
const _kOsmRadiusMeters = 5000;

// Fallback khi GPS không khả dụng (Đà Nẵng)
const kFallbackLocation =
    LatLng(16.0544, 108.2022);

class MapRepository {
  MapRepository()
      : _dio = Dio(
          BaseOptions(
            // Tăng timeout để tránh lỗi trên Android mạng chậm
            connectTimeout:
                const Duration(seconds: 20),
            receiveTimeout:
                const Duration(seconds: 35),
          ),
        );

  final Dio _dio;

  // ─────────────────────────────────────────────────────────────
  // OPENSTREETMAP
  // ─────────────────────────────────────────────────────────────

  Future<List<GreenLocation>> getOsmLocations(
    LatLng center,
  ) async {
    final lat = center.latitude;
    final lon = center.longitude;
    final r = _kOsmRadiusMeters;

    final query = '''
[out:json][timeout:30];

(
  // =========================
  // TRẠM SẠC ĐIỆN
  // =========================
  node["amenity"="charging_station"](around:$r,$lat,$lon);
  way["amenity"="charging_station"](around:$r,$lat,$lon);

  node["socket:type2"](around:$r,$lat,$lon);
  way["socket:type2"](around:$r,$lat,$lon);

  node["socket:ccs"](around:$r,$lat,$lon);
  way["socket:ccs"](around:$r,$lat,$lon);

  // =========================
  // TÁI CHẾ
  // =========================
  node["amenity"="recycling"](around:$r,$lat,$lon);
  way["amenity"="recycling"](around:$r,$lat,$lon);

  node["recycling_type"](around:$r,$lat,$lon);
  way["recycling_type"](around:$r,$lat,$lon);

  // =========================
  // CHỢ XANH
  // =========================
  node["amenity"="marketplace"](around:$r,$lat,$lon);
  way["amenity"="marketplace"](around:$r,$lat,$lon);

  node["shop"="organic"](around:$r,$lat,$lon);
  way["shop"="organic"](around:$r,$lat,$lon);

  node["organic"="only"](around:$r,$lat,$lon);
  way["organic"="only"](around:$r,$lat,$lon);

  node["shop"="greengrocer"](around:$r,$lat,$lon);
  way["shop"="greengrocer"](around:$r,$lat,$lon);
);

out center tags;
''';

    try {
      final response = await _dio.post(
        _kOverpassUrl,
        data:
            'data=${Uri.encodeComponent(query)}',
        options: Options(
          contentType:
              'application/x-www-form-urlencoded',
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode != 200) {
        return [];
      }

      final data = response.data is String
          ? jsonDecode(response.data)
          : response.data;

      final elements =
          (data['elements']
                  as List<dynamic>?) ??
              [];

      final locations = <GreenLocation>[];

      for (final item in elements) {
        final map =
            item as Map<String, dynamic>;

        final tags =
            map['tags']
                    as Map<String, dynamic>? ??
                {};

        final loc = _osmElementToLocation(
          map,
          tags,
        );

        if (loc != null) {
          locations.add(loc);
        }
      }

      return locations;
    } on DioException catch (e) {
      print('OSM DIO ERROR: ${e.type} - ${e.message}');
      return [];
    } catch (e) {
      print('OSM UNKNOWN ERROR: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CONVERT OSM → MODEL
  // ─────────────────────────────────────────────────────────────

  GreenLocation? _osmElementToLocation(
    Map<String, dynamic> element,
    Map<String, dynamic> tags,
  ) {
    GreenLocationType? type;

    final amenity =
        tags['amenity']?.toString() ?? '';

    final shop =
        tags['shop']?.toString() ?? '';

    // =========================
    // SẠC ĐIỆN
    // =========================

    if (amenity == 'charging_station' ||
        tags.containsKey('socket:type2') ||
        tags.containsKey('socket:ccs')) {
      type = GreenLocationType.charging;
    }

    // =========================
    // TÁI CHẾ
    // =========================

    else if (amenity == 'recycling' ||
        tags.containsKey('recycling_type')) {
      type = GreenLocationType.recycling;
    }

    // =========================
    // CHỢ XANH
    // =========================

    else if (amenity == 'marketplace' ||
        shop == 'organic' ||
        shop == 'greengrocer' ||
        tags['organic'] == 'only') {
      type = GreenLocationType.greenMarket;
    }

    if (type == null) {
      return null;
    }

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

    // dữ liệu lỗi
    if (lat == 0 && lon == 0) {
      return null;
    }

    return GreenLocation.fromOsm(
      element,
      type,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // GPS
  // ─────────────────────────────────────────────────────────────

  Future<LatLng?> getCurrentLocation() async {
    try {
      // Kiểm tra GPS service có bật không
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      print('GPS SERVICE ENABLED: $serviceEnabled');

      if (!serviceEnabled) {
        print('GPS: Service disabled');
        return null;
      }

      // Kiểm tra và xin quyền
      LocationPermission permission =
          await Geolocator.checkPermission();

      print('GPS PERMISSION: $permission');

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();

        print(
          'GPS PERMISSION AFTER REQUEST: $permission',
        );

        if (permission ==
            LocationPermission.denied) {
          return null;
        }
      }

      if (permission ==
          LocationPermission.deniedForever) {
        print('GPS: Permission denied forever');
        return null;
      }

      // Lấy vị trí với timeout để tránh treo vô hạn
      final pos =
          await Geolocator.getCurrentPosition(
        // medium nhanh hơn high, phù hợp mobile
        desiredAccuracy:
            LocationAccuracy.medium,
        timeLimit:
            const Duration(seconds: 12),
      );

      print(
        'GPS OK: ${pos.latitude}, ${pos.longitude}',
      );

      return LatLng(
        pos.latitude,
        pos.longitude,
      );
    } on LocationServiceDisabledException {
      print('GPS ERROR: Location service disabled');
      return null;
    } on PermissionDeniedException catch (e) {
      print('GPS ERROR: Permission denied - $e');
      return null;
    } catch (e) {
      // Timeout hoặc lỗi khác → trả null, _init sẽ dùng fallback
      print('GPS ERROR: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // DISTANCE
  // ─────────────────────────────────────────────────────────────

  double distanceBetween(
    LatLng from,
    LatLng to,
  ) {
    return const Distance().distance(
      from,
      to,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────

final mapRepositoryProvider =
    Provider<MapRepository>(
  (ref) => MapRepository(),
);