// lib/data/repositories/map_repository.dart

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/green_location_model.dart';

// Overpass servers (có fallback)
const _kOverpassUrls = [
  'https://overpass-api.de/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
];

const _kOsmRadiusMeters = 5000;
const kFallbackLocation = LatLng(16.0544, 108.2022);

class MapRepository {
  MapRepository()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 25),
            receiveTimeout: const Duration(seconds: 40),
            headers: {
              'User-Agent': 'GreenApp/1.0 (Flutter Android) - Da Nang Green Map',
              'Accept': 'application/json',
            },
          ),
        );

  final Dio _dio;

  // ─────────────────────────────────────────────────────────────
  // GET OSM LOCATIONS
  // ─────────────────────────────────────────────────────────────
  Future<List<GreenLocation>> getOsmLocations(LatLng center) async {
    final lat = center.latitude;
    final lon = center.longitude;
    final r = _kOsmRadiusMeters;

    final query = '''
[out:json][timeout:30];

(
  // Trạm sạc điện
  node["amenity"="charging_station"](around:$r,$lat,$lon);
  way["amenity"="charging_station"](around:$r,$lat,$lon);
  node["socket:type2"](around:$r,$lat,$lon);
  node["socket:ccs"](around:$r,$lat,$lon);

  // Điểm tái chế
  node["amenity"="recycling"](around:$r,$lat,$lon);
  way["amenity"="recycling"](around:$r,$lat,$lon);
  node["recycling_type"](around:$r,$lat,$lon);

  // Chợ xanh
  node["amenity"="marketplace"](around:$r,$lat,$lon);
  way["amenity"="marketplace"](around:$r,$lat,$lon);
  node["shop"="organic"](around:$r,$lat,$lon);
  node["shop"="greengrocer"](around:$r,$lat,$lon);
  node["organic"="only"](around:$r,$lat,$lon);
);

out center tags;
''';

    for (final url in _kOverpassUrls) {
      try {
        print('🌍 Đang thử Overpass: $url');

        final response = await _dio.post(
          url,
          data: 'data=${Uri.encodeComponent(query)}',
          options: Options(
            contentType: 'application/x-www-form-urlencoded',
          ),
        );

        if (response.statusCode == 200) {
          final data = response.data is String
              ? jsonDecode(response.data)
              : response.data;

          final elements = (data['elements'] as List<dynamic>?) ?? [];

          print('✅ OSM Thành công: ${elements.length} elements từ $url');

          final locations = <GreenLocation>[];

          for (final item in elements) {
            final map = item as Map<String, dynamic>;
            final tags = map['tags'] as Map<String, dynamic>? ?? {};

            final loc = _osmElementToLocation(map, tags);
            if (loc != null) {
              locations.add(loc);
            }
          }
          return locations;
        }
      } on DioException catch (e) {
        print('❌ OSM Dio Error ($url): ${e.response?.statusCode} - ${e.message}');
        continue;
      } catch (e) {
        print('❌ OSM Error ($url): $e');
        continue;
      }
    }

    print('⚠️ Tất cả server Overpass đều thất bại');
    return [];
  }

  GreenLocation? _osmElementToLocation(
    Map<String, dynamic> element,
    Map<String, dynamic> tags,
  ) {
    GreenLocationType? type;

    final amenity = tags['amenity']?.toString() ?? '';
    final shop = tags['shop']?.toString() ?? '';

    if (amenity == 'charging_station' ||
        tags.containsKey('socket:type2') ||
        tags.containsKey('socket:ccs')) {
      type = GreenLocationType.charging;
    } else if (amenity == 'recycling' || tags.containsKey('recycling_type')) {
      type = GreenLocationType.recycling;
    } else if (amenity == 'marketplace' ||
        shop == 'organic' ||
        shop == 'greengrocer' ||
        tags['organic'] == 'only') {
      type = GreenLocationType.greenMarket;
    }

    if (type == null) return null;

    double lat = 0, lon = 0;
    if (element.containsKey('lat')) {
      lat = (element['lat'] as num).toDouble();
      lon = (element['lon'] as num).toDouble();
    } else if (element['center'] != null) {
      lat = (element['center']['lat'] as num).toDouble();
      lon = (element['center']['lon'] as num).toDouble();
    }

    if (lat == 0 && lon == 0) return null;

    return GreenLocation.fromOsm(element, type);
  }

  // GPS
  Future<LatLng?> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );

      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      print('GPS ERROR: $e');
      return null;
    }
  }

  double distanceBetween(LatLng from, LatLng to) {
    return const Distance().distance(from, to);
  }
}

// PROVIDER
final mapRepositoryProvider = Provider<MapRepository>(
  (ref) => MapRepository(),
);