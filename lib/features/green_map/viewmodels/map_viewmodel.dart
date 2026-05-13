// lib/features/map/viewmodels/map_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/green_location_model.dart';
import '../../../data/repositories/map_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────────────────────

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

  /// true khi GPS không lấy được, đang dùng vị trí mặc định
  final bool usingFallbackLocation;

  // ─────────────────────────────────────────────────────────────

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
      allLocations:
          allLocations ?? this.allLocations,

      activeFilter: clearFilter
          ? null
          : activeFilter ?? this.activeFilter,

      isLoading:
          isLoading ?? this.isLoading,

      isOsmLoading:
          isOsmLoading ?? this.isOsmLoading,

      error: clearError
          ? null
          : error ?? this.error,

      osmError: clearOsmError
          ? null
          : osmError ?? this.osmError,

      userLocation:
          userLocation ?? this.userLocation,

      selectedLocation: clearSelected
          ? null
          : selectedLocation ??
              this.selectedLocation,

      osmFetched:
          osmFetched ?? this.osmFetched,

      usingFallbackLocation:
          usingFallbackLocation ??
              this.usingFallbackLocation,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // COMPUTED
  // ─────────────────────────────────────────────────────────────

  List<GreenLocation> get filteredLocations {
    List<GreenLocation> result = allLocations;

    // Filter theo loại
    if (activeFilter != null) {
      result = result
          .where((l) => l.type == activeFilter)
          .toList();
    }

    // Chỉ lọc theo bán kính khi userLocation hợp lệ
    // (không phải null và không phải tọa độ 0,0)
    if (userLocation != null &&
        userLocation!.latitude != 0 &&
        userLocation!.longitude != 0) {
      const distance = Distance();

      result = result.where((loc) {
        final meters = distance.distance(
          userLocation!,
          loc.position,
        );

        return meters <= 5000;
      }).toList();
    }

    return result;
  }

  int count(GreenLocationType type) {
    return filteredLocations
        .where((l) => l.type == type)
        .length;
  }

  int countOsm() {
    return filteredLocations
        .where(
          (l) => l.source == LocationSource.osm,
        )
        .length;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIEWMODEL
// ─────────────────────────────────────────────────────────────────────────────

class MapViewModel extends StateNotifier<MapState> {
  MapViewModel(this._repo) : super(const MapState()) {
    _init();
  }

  final MapRepository _repo;

  // chống spam request khi kéo map
  LatLng? _lastFetchCenter;

  // ─────────────────────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────────────────────

  Future<void> _init() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearOsmError: true,
    );

    try {
      // ── GPS ──────────────────────────────────────────────────

      final userPos =
          await _repo.getCurrentLocation();

      // Dù GPS có hay không đều chọn được center để load OSM
      // Nếu GPS fail → dùng fallback Đà Nẵng
      final center = userPos ?? kFallbackLocation;
      final usingFallback = userPos == null;

      print(
        'MAP CENTER: ${center.latitude}, ${center.longitude} '
        '(fallback: $usingFallback)',
      );

      // Cập nhật userLocation nếu GPS OK
      if (userPos != null) {
        state = state.copyWith(
          userLocation: userPos,
          usingFallbackLocation: false,
        );
      } else {
        state = state.copyWith(
          usingFallbackLocation: true,
        );
      }

      // Luôn load OSM, không phụ thuộc GPS
      await _loadOsm(center);
    } catch (e) {
      print('MAP INIT ERROR: $e');

      state = state.copyWith(
        error: 'Không thể tải bản đồ.',
      );
    }

    state = state.copyWith(
      isLoading: false,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // OSM
  // ─────────────────────────────────────────────────────────────

  Future<void> _loadOsm(LatLng center) async {
    state = state.copyWith(
      isOsmLoading: true,
      clearOsmError: true,
    );

    try {
      print(
        'LOAD OSM AT: '
        '${center.latitude}, '
        '${center.longitude}',
      );

      final osmLocs =
          await _repo.getOsmLocations(center);

      print('RAW OSM LOCATIONS: ${osmLocs.length}');

      // chống marker trùng
      final existing = state.allLocations;

      const distCalc = Distance();

      final deduped = osmLocs.where((osm) {
        return !existing.any(
          (old) =>
              distCalc.distance(
                old.position,
                osm.position,
              ) <
              30,
        );
      }).toList();

      print('DEDUPED OSM LOCATIONS: ${deduped.length}');

      state = state.copyWith(
        allLocations: [...existing, ...deduped],
        isOsmLoading: false,
        osmFetched: true,
      );
    } catch (e) {
      print('OSM ERROR: $e');

      state = state.copyWith(
        isOsmLoading: false,
        osmFetched: true,
        osmError:
            'Không tải được dữ liệu OpenStreetMap.',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // FILTER
  // ─────────────────────────────────────────────────────────────

  void setFilter(GreenLocationType? type) {
    // null = tất cả
    if (type == null) {
      state = state.copyWith(clearFilter: true);
      return;
    }

    // toggle filter
    if (state.activeFilter == type) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(activeFilter: type);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SELECTION
  // ─────────────────────────────────────────────────────────────

  void selectLocation(GreenLocation loc) {
    state = state.copyWith(selectedLocation: loc);
  }

  void clearSelection() {
    state = state.copyWith(clearSelected: true);
  }

  // ─────────────────────────────────────────────────────────────
  // REFRESH
  // ─────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    _lastFetchCenter = null;

    // reset locations
    state = state.copyWith(allLocations: []);

    await _init();
  }

  // ─────────────────────────────────────────────────────────────
  // FETCH OSM THEO MAP POSITION
  // ─────────────────────────────────────────────────────────────

  Future<void> fetchOsmAt(
    LatLng center, {
    int? radiusMeters,
  }) async {
    // đang loading → skip
    if (state.isOsmLoading) return;

    // chống spam request
    if (_lastFetchCenter != null) {
      final distance = const Distance().distance(
        _lastFetchCenter!,
        center,
      );

      // chỉ fetch khi move > 800m
      if (distance < 800) return;
    }

    _lastFetchCenter = center;

    await _loadOsm(center);
  }

  // ─────────────────────────────────────────────────────────────
  // NEAREST LOCATION
  // ─────────────────────────────────────────────────────────────

  GreenLocation? nearestOf(GreenLocationType type) {
    final userPos = state.userLocation;

    if (userPos == null) return null;

    final locs = state.allLocations
        .where((l) => l.type == type)
        .toList();

    if (locs.isEmpty) return null;

    locs.sort((a, b) {
      final dA = _repo.distanceBetween(
        userPos,
        a.position,
      );

      final dB = _repo.distanceBetween(
        userPos,
        b.position,
      );

      return dA.compareTo(dB);
    });

    return locs.first;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

final mapViewModelProvider =
    StateNotifierProvider<MapViewModel, MapState>(
  (ref) {
    return MapViewModel(
      ref.read(mapRepositoryProvider),
    );
  },
);