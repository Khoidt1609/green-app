// lib/features/map/viewmodels/map_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/green_location_model.dart';
import '../../../data/repositories/map_repository.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class MapState {
  const MapState({
    this.allLocations    = const [],
    this.activeFilter,
    this.isLoading       = false,
    this.isOsmLoading    = false,   // loading riêng cho OSM
    this.error,
    this.osmError,
    this.userLocation,
    this.selectedLocation,
    this.osmFetched      = false,   // đã fetch OSM lần đầu chưa
  });

  final List<GreenLocation> allLocations;
  final GreenLocationType?  activeFilter;
  final bool                isLoading;
  final bool                isOsmLoading;
  final String?             error;
  final String?             osmError;
  final LatLng?             userLocation;
  final GreenLocation?      selectedLocation;
  final bool                osmFetched;

  MapState copyWith({
    List<GreenLocation>? allLocations,
    GreenLocationType?   activeFilter,
    bool?                isLoading,
    bool?                isOsmLoading,
    String?              error,
    String?              osmError,
    LatLng?              userLocation,
    GreenLocation?       selectedLocation,
    bool?                osmFetched,
    bool clearFilter   = false,
    bool clearError    = false,
    bool clearOsmError = false,
    bool clearSelected = false,
  }) {
    return MapState(
      allLocations:    allLocations    ?? this.allLocations,
      activeFilter:    clearFilter     ? null : activeFilter    ?? this.activeFilter,
      isLoading:       isLoading       ?? this.isLoading,
      isOsmLoading:    isOsmLoading    ?? this.isOsmLoading,
      error:           clearError      ? null : error            ?? this.error,
      osmError:        clearOsmError   ? null : osmError         ?? this.osmError,
      userLocation:    userLocation    ?? this.userLocation,
      selectedLocation: clearSelected  ? null : selectedLocation ?? this.selectedLocation,
      osmFetched:      osmFetched      ?? this.osmFetched,
    );
  }

  // ── Computed ─────────────────────────────────────────────────────────────

  /// Danh sách hiển thị sau khi lọc theo activeFilter
  List<GreenLocation> get filteredLocations {
    if (activeFilter == null) return allLocations;
    return allLocations.where((l) => l.type == activeFilter).toList();
  }

  /// Đếm theo loại (hiển thị stat bar)
  int count(GreenLocationType type) =>
      allLocations.where((l) => l.type == type).length;

  /// Đếm riêng theo nguồn
  int countFirebase() =>
      allLocations.where((l) => l.source == LocationSource.firebase).length;
  int countOsm() =>
      allLocations.where((l) => l.source == LocationSource.osm).length;
}

// ─── ViewModel ────────────────────────────────────────────────────────────────

class MapViewModel extends StateNotifier<MapState> {
  MapViewModel(this._repo) : super(const MapState()) {
    _init();
  }

  final MapRepository _repo;

  // ── Init: GPS trước, rồi Firebase, rồi OSM ──────────────────────────────

  Future<void> _init() async {
    state = state.copyWith(isLoading: true, clearError: true);

    // 1. Lấy vị trí GPS
    final userPos = await _repo.getCurrentLocation();
    if (userPos != null) {
      state = state.copyWith(userLocation: userPos);
    }

    // 2. Fetch Firebase (luôn có)
    await _loadFirebase();

    // 3. Fetch OSM nếu có vị trí
    if (userPos != null) {
      await _loadOsm(userPos);
    }

    state = state.copyWith(isLoading: false);
  }

  Future<void> _loadFirebase() async {
    try {
      final locs = await _repo.getFirebaseLocations();
      state = state.copyWith(allLocations: locs, clearError: true);
    } catch (_) {
      state = state.copyWith(
        error: 'Không thể tải dữ liệu Firebase.',
        isLoading: false,
      );
    }
  }

  /// Fetch OSM và gộp vào danh sách hiện tại (không xóa Firebase)
  Future<void> _loadOsm(LatLng center) async {
    state = state.copyWith(isOsmLoading: true, clearOsmError: true);
    try {
      final osmLocs = await _repo.getOsmLocations(center);

      // Loại trùng với Firebase đã có
      final existing = state.allLocations;
      const distCalc = Distance();
      final deduped = osmLocs.where((osm) {
        return !existing.any((fb) =>
            distCalc.distance(fb.position, osm.position) < 30);
      }).toList();

      state = state.copyWith(
        allLocations: [...existing, ...deduped],
        isOsmLoading: false,
        osmFetched: true,
      );
    } catch (_) {
      state = state.copyWith(
        isOsmLoading: false,
        osmFetched: true,
        osmError: 'Không tải được dữ liệu OpenStreetMap.',
      );
    }
  }

  // ── Public actions ────────────────────────────────────────────────────────

  void setFilter(GreenLocationType? type) {
    // null = "Tất cả" → luôn clear filter dù đang là gì
    if (type == null) {
      state = state.copyWith(clearFilter: true);
      return;
    }
    // Bấm lại cùng loại → toggle off (về Tất cả)
    if (state.activeFilter == type) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(activeFilter: type);
    }
  }

  void selectLocation(GreenLocation loc) =>
      state = state.copyWith(selectedLocation: loc);

  void clearSelection() =>
      state = state.copyWith(clearSelected: true);

  /// Full refresh: xóa hết → fetch lại từ đầu
  Future<void> refresh() => _init();

  /// Fetch thêm OSM theo vị trí map hiện tại
  Future<void> fetchOsmAt(LatLng center, {int? radiusMeters}) async {
    if (state.isOsmLoading) return;
    await _loadOsm(center);
  }

  /// Tìm địa điểm gần nhất theo type
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

// ─── Provider ─────────────────────────────────────────────────────────────────

final mapViewModelProvider =
    StateNotifierProvider<MapViewModel, MapState>((ref) {
  return MapViewModel(ref.read(mapRepositoryProvider));
});