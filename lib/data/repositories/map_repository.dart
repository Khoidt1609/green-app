import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';                   
import '../models/green_location_model.dart';

class MapRepository {
  final FirebaseFirestore _firestore;

  MapRepository(this._firestore);

  /// Lấy tất cả địa điểm xanh từ Firestore
  Future<List<GreenLocation>> getGreenLocations() async {
    try {
      final snapshot = await _firestore.collection('green_locations').get();
      return snapshot.docs
          .map((doc) => GreenLocation.fromDoc(doc))
          .toList();
    } catch (e) {
      print('Error loading green locations: $e');
      return [];
    }
  }

  /// Lấy vị trí hiện tại của người dùng
  Future<LatLng?> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(position.latitude, position.longitude);   // ← latlong2
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Tính khoảng cách giữa 2 điểm (đơn vị: mét)
  double distanceBetween(LatLng from, LatLng to) {
    return Distance().distance(from, to);     // ← Dùng Distance() của latlong2
  }
}

// Provider
final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return MapRepository(FirebaseFirestore.instance);
});