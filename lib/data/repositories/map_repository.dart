// lib/data/repositories/map_repository.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/green_location_model.dart';

// ─────────────────────────────────────────────────────────────
// OVERPASS API
// ─────────────────────────────────────────────────────────────

const _kOverpassUrl = 'https://overpass-api.de/api/interpreter';

// bán kính 5km
const _kOsmRadiusMeters = 5000;

class MapRepository {
  MapRepository(this._firestore)
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 12),
            receiveTimeout: const Duration(seconds: 20),
          ),
        );

  final FirebaseFirestore _firestore;
  final Dio _dio;

  // ─────────────────────────────────────────────────────────────
  // FIREBASE
  // ─────────────────────────────────────────────────────────────

  Future<List<GreenLocation>> getFirebaseLocations() async {
    final snapshot =
        await _firestore.collection('green_locations').get();

    return snapshot.docs
        .map((doc) => GreenLocation.fromDoc(doc))
        .toList();
  }

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
[out:json][timeout:25];

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
        data: 'data=${Uri.encodeComponent(query)}',
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
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
          (data['elements'] as List<dynamic>?) ?? [];

      final locations = <GreenLocation>[];

      for (final item in elements) {
        final map = item as Map<String, dynamic>;

        final tags =
            map['tags'] as Map<String, dynamic>? ?? {};

        final loc = _osmElementToLocation(
          map,
          tags,
        );

        if (loc != null) {
          locations.add(loc);
        }
      }

      return locations;
    } on DioException {
      return [];
    } catch (_) {
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
    if (
        amenity == 'charging_station' ||
        tags.containsKey('socket:type2') ||
        tags.containsKey('socket:ccs')) {
      type = GreenLocationType.charging;
    }

    // =========================
    // TÁI CHẾ
    // =========================
    else if (
        amenity == 'recycling' ||
        tags.containsKey('recycling_type')) {
      type = GreenLocationType.recycling;
    }

    // =========================
    // CHỢ XANH
    // =========================
    else if (
        amenity == 'marketplace' ||
        shop == 'organic' ||
        shop == 'greengrocer' ||
        tags['organic'] == 'only') {
      type = GreenLocationType.greenMarket;
    }

    if (type == null) return null;

    double lat = 0;
    double lon = 0;

    // node
    if (element.containsKey('lat')) {
      lat = (element['lat'] as num).toDouble();
      lon = (element['lon'] as num).toDouble();
    }

    // way
    else if (element['center'] != null) {
      lat =
          (element['center']['lat'] as num).toDouble();

      lon =
          (element['center']['lon'] as num).toDouble();
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
  // MERGE FIREBASE + OSM
  // ─────────────────────────────────────────────────────────────

  Future<List<GreenLocation>> getAllLocations(
    LatLng? userPos,
  ) async {
    final firebaseFuture =
        getFirebaseLocations();

    final osmFuture = userPos != null
        ? getOsmLocations(userPos)
        : Future.value(<GreenLocation>[]);

    final results = await Future.wait([
      firebaseFuture,
      osmFuture,
    ]);

    final firebase =
        results[0] as List<GreenLocation>;

    final osm =
        results[1] as List<GreenLocation>;

    const distance = Distance();

    final deduped = <GreenLocation>[];

    for (final osmLoc in osm) {
      final duplicated = firebase.any(
        (fb) =>
            distance.distance(
              fb.position,
              osmLoc.position,
            ) <
            30,
      );

      if (!duplicated) {
        deduped.add(osmLoc);
      }
    }

    return [
      ...firebase,
      ...deduped,
    ];
  }

  // ─────────────────────────────────────────────────────────────
  // GPS
  // ─────────────────────────────────────────────────────────────

  Future<LatLng?> getCurrentLocation() async {
    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();

        if (permission ==
            LocationPermission.denied) {
          return null;
        }
      }

      if (permission ==
          LocationPermission.deniedForever) {
        return null;
      }

      final pos =
          await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(
        pos.latitude,
        pos.longitude,
      );
    } catch (_) {
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
  (ref) => MapRepository(
    FirebaseFirestore.instance,
  ),
);