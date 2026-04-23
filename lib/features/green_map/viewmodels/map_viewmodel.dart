// lib/features/map/viewmodels/map_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';                    // ← Đổi sang latlong2
import 'package:green_app/data/models/green_location_model.dart';
import 'package:green_app/data/repositories/map_repository.dart';

class MapState {
  final List<GreenLocation> allLocations;
  final GreenLocationType? activeFilter;
  final bool isLoading;
  final String? error;
  final LatLng? userLocation;           // ← latlong2
  final GreenLocation? selectedLocation;

  const MapState({
    this.allLocations = const [],
    this.activeFilter,
    this.isLoading = false,
    this.error,
    this.userLocation,
    this.selectedLocation,
  });

  MapState copyWith({
    List<GreenLocation>? allLocations,
    GreenLocationType? activeFilter,
    bool? isLoading,
    String? error,
    LatLng? userLocation,
    GreenLocation? selectedLocation,
    bool clearFilter = false,
    bool clearError = false,
    bool clearSelected = false,
  }) {
    return MapState(
      allLocations: allLocations ?? this.allLocations,
      activeFilter: clearFilter ? null : activeFilter ?? this.activeFilter,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      userLocation: userLocation ?? this.userLocation,
      selectedLocation: clearSelected ? null : selectedLocation ?? this.selectedLocation,
    );
  }

  List<GreenLocation> get filteredLocations {
    if (activeFilter == null) return allLocations;
    return allLocations.where((l) => l.type == activeFilter).toList();
  }

  int count(GreenLocationType type) =>
      allLocations.where((l) => l.type == type).length;
}

class MapViewModel extends StateNotifier<MapState> {
  final MapRepository _repo;

  MapViewModel(this._repo) : super(const MapState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    await Future.wait([_loadLocations(), _loadUserLocation()]);
    state = state.copyWith(isLoading: false);
  }

  Future<void> _loadLocations() async {
    try {
      final locations = await _repo.getGreenLocations();
      state = state.copyWith(allLocations: locations);
    } catch (e) {
      state = state.copyWith(error: 'Không thể tải bản đồ: $e');
    }
  }

  Future<void> _loadUserLocation() async {
    final pos = await _repo.getCurrentLocation();
    if (pos != null) {
      state = state.copyWith(userLocation: pos);
    }
  }

  void setFilter(GreenLocationType? type) {
    if (state.activeFilter == type) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(activeFilter: type);
    }
  }

  void selectLocation(GreenLocation location) {
    state = state.copyWith(selectedLocation: location);
  }

  void clearSelection() {
    state = state.copyWith(clearSelected: true);
  }

  Future<void> refresh() => _init();

  /// Tìm địa điểm gần nhất theo type
  GreenLocation? nearestOf(GreenLocationType type) {
    final userPos = state.userLocation;
    if (userPos == null) return null;

    final locations = state.allLocations.where((l) => l.type == type).toList();
    if (locations.isEmpty) return null;

    locations.sort((a, b) {
      final dA = _repo.distanceBetween(userPos, a.position);
      final dB = _repo.distanceBetween(userPos, b.position);
      return dA.compareTo(dB);
    });

    return locations.first;
  }
}

// Provider
final mapViewModelProvider = StateNotifierProvider<MapViewModel, MapState>((ref) {
  return MapViewModel(ref.read(mapRepositoryProvider));
});