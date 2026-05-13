// lib/features/map/viewmodels/map_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/green_location_model.dart';
import '../../../data/repositories/map_repository.dart';

class MapState {
  const MapState({
    this.allLocations = const [],
    this.activeFilter,
    this.isLoading = false,
    this.isOsmLoading = false,
    this.error,
    this.osmError,
    this.userLocation,
    this.selectedLocation,
    this.osmFetched = false,
    this.usingFallbackLocation = false,
  });

  final List<GreenLocation> allLocations;
  final GreenLocationType? activeFilter;
  final bool isLoading;
  final bool isOsmLoading;
  final String? error;
  final String? osmError;
  final LatLng? userLocation;
  final GreenLocation? selectedLocation;
  final bool osmFetched;
  final bool usingFallbackLocation;

  MapState copyWith({
    List<GreenLocation>? allLocations,
    GreenLocationType? activeFilter,
    bool? isLoading,
    bool? isOsmLoading,
    String? error,
    String? osmError,
    LatLng? userLocation,
    GreenLocation? selectedLocation,
    bool? osmFetched,
    bool? usingFallbackLocation,
    bool clearFilter = false,
    bool clearError = false,
    bool clearOsmError = false,
    bool clearSelected = false,
  }) {
    return MapState(
      allLocations: allLocations ?? this.allLocations,
      activeFilter: clearFilter ? null : activeFilter ?? this.activeFilter,
      isLoading: isLoading ?? this.isLoading,
      isOsmLoading: isOsmLoading ?? this.isOsmLoading,
      error: clearError ? null : error ?? this.error,
      osmError: clearOsmError ? null : osmError ?? this.osmError,
      userLocation: userLocation ?? this.userLocation,
      selectedLocation: clearSelected ? null : selectedLocation ?? this.selectedLocation,
      osmFetched: osmFetched ?? this.osmFetched,
      usingFallbackLocation: usingFallbackLocation ?? this.usingFallbackLocation,
    );
  }

  List<GreenLocation> get filteredLocations {
    List<GreenLocation> result = allLocations;

    if (activeFilter != null) {
      result = result.where((l) => l.type == activeFilter).toList();
    }

    if (userLocation != null &&
        userLocation!.latitude != 0 &&
        userLocation!.longitude != 0) {
      const distance = Distance();
      result = result.where((loc) {
        final meters = distance.distance(userLocation!, loc.position);
        return meters <= 5000;
      }).toList();
    }

    return result;
  }

  int count(GreenLocationType type) =>
      filteredLocations.where((l) => l.type == type).length;

  int countOsm() =>
      filteredLocations.where((l) => l.source == LocationSource.osm).length;
}

class MapViewModel extends StateNotifier<MapState> {
  MapViewModel(this._repo) : super(const MapState()) {
    _init();
  }

  final MapRepository _repo;
  LatLng? _lastFetchCenter;

  Future<void> _init() async {
    state = state.copyWith(isLoading: true, clearError: true, clearOsmError: true);

    try {
      final userPos = await _repo.getCurrentLocation();
      final center = userPos ?? kFallbackLocation;

      if (userPos != null) {
        state = state.copyWith(userLocation: userPos, usingFallbackLocation: false);
      } else {
        state = state.copyWith(usingFallbackLocation: true);
      }

      await _loadOsm(center);
    } catch (e) {
      print('MAP INIT ERROR: $e');
      state = state.copyWith(error: 'Không thể tải bản đồ.');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _loadOsm(LatLng center) async {
    if (state.isOsmLoading) return;

    state = state.copyWith(isOsmLoading: true, clearOsmError: true);

    try {
      final osmLocs = await _repo.getOsmLocations(center);

      final existing = state.allLocations;
      const distCalc = Distance();

      final deduped = osmLocs.where((osm) {
        return !existing.any((old) =>
            distCalc.distance(old.position, osm.position) < 30);
      }).toList();

      state = state.copyWith(
        allLocations: [...existing, ...deduped],
        isOsmLoading: false,
        osmFetched: true,
      );
    } catch (e) {
      print('OSM LOAD ERROR: $e');
      state = state.copyWith(
        isOsmLoading: false,
        osmFetched: true,
        osmError: 'Không tải được dữ liệu OpenStreetMap.',
      );
    }
  }

  void setFilter(GreenLocationType? type) {
    if (type == null || state.activeFilter == type) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(activeFilter: type);
    }
  }

  void selectLocation(GreenLocation loc) => state = state.copyWith(selectedLocation: loc);
  void clearSelection() => state = state.copyWith(clearSelected: true);

  Future<void> refresh() async {
    _lastFetchCenter = null;
    state = state.copyWith(allLocations: []);
    await _init();
  }

  Future<void> fetchOsmAt(LatLng center) async {
    if (state.isOsmLoading) return;
    if (_lastFetchCenter != null) {
      final distance = const Distance().distance(_lastFetchCenter!, center);
      if (distance < 800) return;
    }

    _lastFetchCenter = center;
    await _loadOsm(center);
  }

  GreenLocation? nearestOf(GreenLocationType type) {
    final userPos = state.userLocation;
    if (userPos == null) return null;

    final locs = state.allLocations.where((l) => l.type == type).toList();
    if (locs.isEmpty) return null;

    locs.sort((a, b) {
      final dA = _repo.distanceBetween(userPos, a.position);
      final dB = _repo.distanceBetween(userPos, b.position);
      return dA.compareTo(dB);
    });

    return locs.first;
  }
}

final mapViewModelProvider = StateNotifierProvider<MapViewModel, MapState>(
  (ref) => MapViewModel(ref.read(mapRepositoryProvider)),
);