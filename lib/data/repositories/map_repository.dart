// lib/data/repositories/map_repository.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/green_location_model.dart';

// ─── Overpass API endpoint (public, không cần key) ───────────────────────────
const _kOverpassUrl = 'https://overpass-api.de/api/interpreter';

// Bán kính fetch OSM (mét)
const _kOsmRadiusMeters = 5000;

class MapRepository {
  MapRepository(this._firestore) : _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  final FirebaseFirestore _firestore;
  final Dio _dio;

  // ── Firebase: điểm xanh do admin quản lý ─────────────────────────────────

  Future<List<GreenLocation>> getFirebaseLocations() async {
    final snapshot = await _firestore.collection('green_locations').get();
    return snapshot.docs.map(GreenLocation.fromDoc).toList();
  }

  // ── OpenStreetMap Overpass: tự động tìm quanh vị trí ─────────────────────
  //
  // Truy vấn các tag OSM phổ biến:
  //   Trạm sạc EV  → amenity=charging_station
  //   Điểm tái chế → amenity=recycling
  //   Trạm sạc VinFast → brand=VinFast + amenity=charging_station
  //   Trạm sạc khác    → amenity=charging_station
  //   Điểm tái chế     → amenity=recycling
  //   Chợ xanh         → amenity=marketplace
  //
  // Overpass QL: https://overpass-api.de/api/interpreter

  Future<List<GreenLocation>> getOsmLocations(LatLng center) async {
    final lat = center.latitude;
    final lon = center.longitude;
    final r   = _kOsmRadiusMeters;

    // Overpass QL — ưu tiên VinFast charging, sau đó các loại khác
    final query = '''
[out:json][timeout:20];
(
  node["amenity"="charging_station"]["brand"="VinFast"](around:$r,$lat,$lon);
  way["amenity"="charging_station"]["brand"="VinFast"](around:$r,$lat,$lon);
  node["amenity"="charging_station"]["operator"="VinFast"](around:$r,$lat,$lon);
  way["amenity"="charging_station"]["operator"="VinFast"](around:$r,$lat,$lon);
  node["amenity"="charging_station"](around:$r,$lat,$lon);
  way["amenity"="charging_station"](around:$r,$lat,$lon);
  node["amenity"="recycling"](around:$r,$lat,$lon);
  way["amenity"="recycling"](around:$r,$lat,$lon);
  node["amenity"="marketplace"](around:$r,$lat,$lon);
  way["amenity"="marketplace"](around:$r,$lat,$lon);
);
out center tags;
''';

    try {
      final response = await _dio.post(
        _kOverpassUrl,
        data: 'data=${Uri.encodeComponent(query)}',
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.statusCode != 200) return [];

      final data     = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      final elements = (data['elements'] as List<dynamic>?) ?? [];

      final result = <GreenLocation>[];
      for (final el in elements) {
        final map  = el as Map<String, dynamic>;
        final tags = map['tags'] as Map<String, dynamic>? ?? {};

        // Skip nếu lat/lon = 0 (dữ liệu lỗi)
        final loc = _osmElementToLocation(map, tags);
        if (loc != null) result.add(loc);
      }

      return result;
    } on DioException {
      // Trả về rỗng nếu timeout / network lỗi — không crash app
      return [];
    } catch (_) {
      return [];
    }
  }

  GreenLocation? _osmElementToLocation(
    Map<String, dynamic> element,
    Map<String, dynamic> tags,
  ) {
    // Xác định type từ tag
    GreenLocationType? type;
    final amenity = tags['amenity']?.toString() ?? '';

    if (amenity == 'charging_station') {
      type = GreenLocationType.charging;
    } else if (amenity == 'recycling') {
      type = GreenLocationType.recycling;
    } else if (amenity == 'marketplace') {
      type = GreenLocationType.greenMarket;
    }

    if (type == null) return null;

    // Lấy tọa độ
    double lat = 0, lon = 0;
    if (element.containsKey('lat') && element.containsKey('lon')) {
      lat = (element['lat'] as num).toDouble();
      lon = (element['lon'] as num).toDouble();
    } else if (element['center'] != null) {
      final center = element['center'] as Map<String, dynamic>;
      lat = (center['lat'] as num).toDouble();
      lon = (center['lon'] as num).toDouble();
    }

    // Bỏ qua nếu tọa độ không hợp lệ
    if (lat == 0 && lon == 0) return null;

    return GreenLocation.fromOsm(element, type);
  }

  // ── Gộp Firebase + OSM, loại bỏ trùng (theo khoảng cách < 30m) ──────────

  Future<List<GreenLocation>> getAllLocations(LatLng? userPos) async {
    // Firebase luôn fetch
    final firebaseLocsFuture = getFirebaseLocations();

    // OSM chỉ fetch nếu biết vị trí user
    final osmLocsFuture = userPos != null
        ? getOsmLocations(userPos)
        : Future.value(<GreenLocation>[]);

    final results = await Future.wait([firebaseLocsFuture, osmLocsFuture]);
    final firebase = results[0];
    final osm      = results[1];

    // Loại trùng: nếu điểm OSM cách điểm Firebase < 30m thì bỏ OSM
    final deduped = <GreenLocation>[];
    const distCalc = Distance();

    for (final osmLoc in osm) {
      final hasDuplicate = firebase.any((fb) =>
          distCalc.distance(fb.position, osmLoc.position) < 30);
      if (!hasDuplicate) deduped.add(osmLoc);
    }

    return [...firebase, ...deduped];
  }

  // ── GPS ──────────────────────────────────────────────────────────────────

  Future<LatLng?> getCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  // ── Khoảng cách (mét) ────────────────────────────────────────────────────

  double distanceBetween(LatLng from, LatLng to) =>
      const Distance().distance(from, to);
}

final mapRepositoryProvider = Provider<MapRepository>(
  (ref) => MapRepository(FirebaseFirestore.instance),
);