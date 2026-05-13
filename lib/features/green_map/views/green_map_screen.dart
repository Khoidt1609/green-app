// lib/features/green_map/views/green_map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/flutter_map.dart'
    show CircleLayer, CircleMarker;
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/green_location_model.dart';
import '../viewmodels/map_viewmodel.dart';

// ─────────────────────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────────────────────

const _kRecyclingColor =
    AppColors.primaryGreen;

const _kChargingColor =
    Color(0xFF42A5F5);

const _kMarketColor =
    Color(0xFFFF9800);

const _kUserColor =
    Color(0xFF5C6BC0);

const _kRadiusColor =
    Color(0x1A2DDA93);

// ─────────────────────────────────────────────────────────────

Color _typeColor(
  GreenLocationType t,
) {
  switch (t) {
    case GreenLocationType.recycling:
      return _kRecyclingColor;

    case GreenLocationType.charging:
      return _kChargingColor;

    case GreenLocationType.greenMarket:
      return _kMarketColor;
  }
}

IconData _typeIcon(
  GreenLocationType t,
) {
  switch (t) {
    case GreenLocationType.recycling:
      return Icons.recycling_rounded;

    case GreenLocationType.charging:
      return Icons.electric_bolt_rounded;

    case GreenLocationType.greenMarket:
      return Icons.storefront_rounded;
  }
}

// ─────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────

class GreenMapScreen
    extends ConsumerStatefulWidget {
  const GreenMapScreen({
    super.key,
  });

  @override
  ConsumerState<GreenMapScreen>
      createState() =>
          _GreenMapScreenState();
}

class _GreenMapScreenState
    extends ConsumerState<GreenMapScreen> {
  final _mapCtrl = MapController();

  final _searchCtrl =
      TextEditingController();

  static const _defaultCenter =
      LatLng(16.0544, 108.2022);

  static const _osmRadiusMeters =
      5000.0;

  @override
  void dispose() {
    _searchCtrl.dispose();

    super.dispose();
  }

  void _goToUser() {
    final pos = ref
        .read(mapViewModelProvider)
        .userLocation;

    if (pos != null) {
      _mapCtrl.move(pos, 14.0);
    }
  }

  Future<void> _openDirections(
    GreenLocation loc,
  ) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${loc.position.latitude},${loc.position.longitude}'
      '&travelmode=driving',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(mapViewModelProvider);

    final vm = ref.read(
      mapViewModelProvider.notifier,
    );

    final canPop =
        Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        leading: canPop
            ? IconButton(
                icon: const Icon(
                  Icons
                      .arrow_back_ios_new_rounded,
                ),
                onPressed: () {
                  Navigator.of(context)
                      .pop();
                },
              )
            : null,

        title: const Row(
          children: [
            Icon(
              Icons.eco_rounded,
              color:
                  AppColors.primaryGreen,
              size: 20,
            ),
            SizedBox(width: 6),
            Text(
              'Green Map',
              style: TextStyle(
                fontWeight:
                    FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),

        actions: [
          if (state.isOsmLoading)
            const Padding(
              padding:
                  EdgeInsets.symmetric(
                horizontal: 8,
              ),
              child: SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(
                  color: AppColors
                      .primaryGreen,
                  strokeWidth: 2,
                ),
              ),
            ),

          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            onPressed: vm.refresh,
          ),

          IconButton(
            icon: const Icon(
              Icons.my_location_rounded,
            ),
            onPressed: _goToUser,
          ),
        ],
      ),

      body: Column(
        children: [
          // SEARCH + FILTER

          _SearchFilterPanel(
            searchCtrl: _searchCtrl,
            activeFilter:
                state.activeFilter,
            onFilterChanged:
                vm.setFilter,
            onSearchChanged:
                (_) => setState(() {}),
          ),

          // STAT BAR

          _StatBar(state: state),

          // MAP

          Expanded(
            child: Stack(
              children: [
                _buildMap(
                  state,
                  vm,
                ),

                // LOADING

                if (state.isLoading)
                  Container(
                    color: Colors.black
                        .withValues(
                      alpha: 0.18,
                    ),
                    child: const Center(
                      child:
                          CircularProgressIndicator(
                        color: AppColors
                            .primaryGreen,
                      ),
                    ),
                  ),

                // OSM BADGE

                if (state.osmFetched &&
                    state.countOsm() > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _OsmBadge(
                      count:
                          state.countOsm(),
                    ),
                  ),

                // ERROR

                if (state.error != null &&
                    !state.isLoading)
                  _ErrorBanner(
                    message:
                        state.error!,
                    onRetry:
                        vm.refresh,
                  ),

                // OSM ERROR

                if (state.osmError != null &&
                    !state.isOsmLoading)
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 60,
                    child: _SmallBanner(
                      message:
                          'Không tải được OpenStreetMap.',
                      icon: Icons
                          .cloud_off_rounded,
                      color: AppColors
                          .accentOrange,
                    ),
                  ),

                // DETAIL CARD

                if (state.selectedLocation !=
                    null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child:
                        _LocationDetailCard(
                      location: state
                          .selectedLocation!,
                      onClose:
                          vm.clearSelection,
                      onDirections: () {
                        _openDirections(
                          state
                              .selectedLocation!,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD MAP
  // ─────────────────────────────────────────────────────────────

  Widget _buildMap(
    MapState state,
    MapViewModel vm,
  ) {
    final center =
        state.userLocation ??
            _defaultCenter;

    final query = _searchCtrl.text
        .toLowerCase()
        .trim();

    // FILTER SEARCH

    final visible =
        state.filteredLocations.where(
      (loc) {
        if (query.isEmpty) {
          return true;
        }

        return loc.name
                .toLowerCase()
                .contains(query) ||
            (loc.address
                    ?.toLowerCase()
                    .contains(query) ??
                false);
      },
    ).toList();

    return FlutterMap(
      mapController: _mapCtrl,

      options: MapOptions(
        initialCenter: center,
        initialZoom: 13.5,
        minZoom: 5,
        maxZoom: 19,

        // TAP BACKGROUND

        onTap: (_, __) {
          vm.clearSelection();
        },

        // FETCH OSM WHEN MOVE

        onPositionChanged:
            (position, hasGesture) {
          final center =
              position.center;

          if (hasGesture &&
              center != null) {
            vm.fetchOsmAt(center);
          }
        },
      ),

      children: [
        // TILE LAYER

        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

          userAgentPackageName:
              'com.example.green_app',

          maxZoom: 19,
          tileProvider: CancellableNetworkTileProvider(),
        ),

        // USER RADIUS

        if (state.userLocation != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point:
                    state.userLocation!,

                radius:
                    _osmRadiusMeters,

                useRadiusInMeter: true,

                color: _kRadiusColor,

                borderColor:
                    AppColors
                        .primaryGreen
                        .withValues(
                  alpha: 0.5,
                ),

                borderStrokeWidth: 1.5,
              ),
            ],
          ),

        // MARKERS

        MarkerLayer(
          rotate: true,

          markers: [
            // USER

            if (state.userLocation != null)
              Marker(
                point:
                    state.userLocation!,

                width: 50,
                height: 50,

                child:
                    const _UserMarker(),
              ),

            // LOCATIONS

            ...visible.map((loc) {
              final isSelected =
                  state.selectedLocation
                          ?.id ==
                      loc.id;

              return Marker(
                point: loc.position,

                width:
                    isSelected
                        ? 52
                        : 42,

                height:
                    isSelected
                        ? 52
                        : 42,

                child: GestureDetector(
                  behavior:
                      HitTestBehavior
                          .opaque,

                  onTap: () {
                    vm.selectLocation(
                      loc,
                    );

                    _mapCtrl.move(
                      loc.position,
                      _mapCtrl.camera
                                  .zoom <
                              14
                          ? 14.0
                          : _mapCtrl
                              .camera
                              .zoom,
                    );
                  },

                  child: _MarkerBubble(
                    type: loc.type,
                    source:
                        loc.source,
                    isSelected:
                        isSelected,
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}
// ─────────────────────────────────────────────────────────────
// SEARCH + FILTER PANEL
// ─────────────────────────────────────────────────────────────

class _SearchFilterPanel
    extends StatelessWidget {
  const _SearchFilterPanel({
    required this.searchCtrl,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.onSearchChanged,
  });

  final TextEditingController searchCtrl;

  final GreenLocationType? activeFilter;

  final ValueChanged<
      GreenLocationType?> onFilterChanged;

  final ValueChanged<String>
      onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 3),
            color:
                Colors.black.withValues(
              alpha: 0.05,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          // SEARCH

          TextField(
            controller: searchCtrl,

            onChanged: onSearchChanged,

            decoration: InputDecoration(
              hintText:
                  'Tìm địa điểm xanh...',
              prefixIcon: const Icon(
                Icons.search_rounded,
              ),
              filled: true,
              fillColor:
                  const Color(0xFFF5F7FA),

              contentPadding:
                  const EdgeInsets.symmetric(
                vertical: 12,
              ),

              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                borderSide:
                    BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // FILTERS

          SingleChildScrollView(
            scrollDirection:
                Axis.horizontal,
            child: Row(
              children: [
                _FilterChipItem(
                  label: 'Tất cả',
                  icon:
                      Icons.apps_rounded,
                  color:
                      AppColors.primaryGreen,
                  selected:
                      activeFilter ==
                          null,
                  onTap: () {
                    onFilterChanged(
                      null,
                    );
                  },
                ),

                const SizedBox(width: 8),

                _FilterChipItem(
                  label: 'Tái chế',
                  icon: Icons
                      .recycling_rounded,
                  color:
                      _kRecyclingColor,
                  selected:
                      activeFilter ==
                          GreenLocationType
                              .recycling,
                  onTap: () {
                    onFilterChanged(
                      GreenLocationType
                          .recycling,
                    );
                  },
                ),

                const SizedBox(width: 8),

                _FilterChipItem(
                  label: 'Trạm sạc',
                  icon: Icons
                      .electric_bolt_rounded,
                  color:
                      _kChargingColor,
                  selected:
                      activeFilter ==
                          GreenLocationType
                              .charging,
                  onTap: () {
                    onFilterChanged(
                      GreenLocationType
                          .charging,
                    );
                  },
                ),

                const SizedBox(width: 8),

                _FilterChipItem(
                  label: 'Chợ xanh',
                  icon: Icons
                      .storefront_rounded,
                  color:
                      _kMarketColor,
                  selected:
                      activeFilter ==
                          GreenLocationType
                              .greenMarket,
                  onTap: () {
                    onFilterChanged(
                      GreenLocationType
                          .greenMarket,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FILTER CHIP
// ─────────────────────────────────────────────────────────────

class _FilterChipItem
    extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;

  final IconData icon;

  final Color color;

  final bool selected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(30),

      onTap: onTap,

      child: AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 220,
        ),

        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),

        decoration: BoxDecoration(
          color: selected
              ? color
              : color.withValues(
                  alpha: 0.08,
                ),

          borderRadius:
              BorderRadius.circular(
            30,
          ),

          border: Border.all(
            color: selected
                ? color
                : color.withValues(
                    alpha: 0.18,
                  ),
          ),
        ),

        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? Colors.white
                  : color,
            ),

            const SizedBox(width: 6),

            Text(
              label,
              style: TextStyle(
                fontWeight:
                    FontWeight.w700,

                color: selected
                    ? Colors.white
                    : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STAT BAR
// ─────────────────────────────────────────────────────────────

class _StatBar extends StatelessWidget {
  const _StatBar({
    required this.state,
  });

  final MapState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: [
          _MiniStat(
            icon:
                Icons.recycling_rounded,
            color:
                _kRecyclingColor,
            value: state.count(
              GreenLocationType
                  .recycling,
            ),
          ),

          const SizedBox(width: 10),

          _MiniStat(
            icon: Icons
                .electric_bolt_rounded,
            color:
                _kChargingColor,
            value: state.count(
              GreenLocationType
                  .charging,
            ),
          ),

          const SizedBox(width: 10),

          _MiniStat(
            icon:
                Icons.storefront_rounded,
            color: _kMarketColor,
            value: state.count(
              GreenLocationType
                  .greenMarket,
            ),
          ),

          const Spacer(),

          Text(
            '${state.filteredLocations.length} địa điểm',
            style: const TextStyle(
              fontWeight:
                  FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MINI STAT
// ─────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.color,
    required this.value,
  });

  final IconData icon;

  final Color color;

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color:
            color.withValues(alpha: 0.08),

        borderRadius:
            BorderRadius.circular(14),
      ),

      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),

          const SizedBox(width: 5),

          Text(
            value.toString(),
            style: TextStyle(
              fontWeight:
                  FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────
// MARKER BUBBLE
// ─────────────────────────────────────────────────────────────

class _MarkerBubble
    extends StatelessWidget {
  const _MarkerBubble({
    required this.type,
    required this.source,
    required this.isSelected,
  });

  final GreenLocationType type;

  final LocationSource source;

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(type);

    return AnimatedScale(
      duration:
          const Duration(milliseconds: 180),

      scale: isSelected ? 1.18 : 1,

      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,

          border: Border.all(
            color: Colors.white,
            width: 3,
          ),

          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, 3),
              color:
                  color.withValues(
                alpha: 0.35,
              ),
            ),
          ],
        ),

        child: Icon(
          _typeIcon(type),
          color: Colors.white,
          size: isSelected ? 26 : 22,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// USER MARKER
// ─────────────────────────────────────────────────────────────

class _UserMarker
    extends StatelessWidget {
  const _UserMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 42,
          height: 42,

          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                _kUserColor.withValues(
              alpha: 0.20,
            ),
          ),
        ),

        Container(
          width: 20,
          height: 20,

          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kUserColor,

            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LOCATION DETAIL CARD
// ─────────────────────────────────────────────────────────────

class _LocationDetailCard
    extends StatelessWidget {
  const _LocationDetailCard({
    required this.location,
    required this.onClose,
    required this.onDirections,
  });

  final GreenLocation location;

  final VoidCallback onClose;

  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final color =
        _typeColor(location.type);

    return Material(
      elevation: 10,
      borderRadius:
          BorderRadius.circular(24),

      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(
            24,
          ),
        ),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,

                  decoration:
                      BoxDecoration(
                    color:
                        color.withValues(
                      alpha: 0.12,
                    ),
                    shape:
                        BoxShape.circle,
                  ),

                  child: Icon(
                    _typeIcon(
                      location.type,
                    ),
                    color: color,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        location.name,
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight
                                  .w800,
                        ),
                      ),

                      const SizedBox(
                        height: 2,
                      ),

                      Text(
                        location
                            .type.label,
                        style: TextStyle(
                          color: color,
                          fontWeight:
                              FontWeight
                                  .w700,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: onClose,
                  icon: const Icon(
                    Icons.close_rounded,
                  ),
                ),
              ],
            ),

            if (location.address !=
                null) ...[
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 18,
                  ),

                  const SizedBox(width: 6),

                  Expanded(
                    child: Text(
                      location.address!,
                    ),
                  ),
                ],
              ),
            ],

            if (location.description !=
                null) ...[
              const SizedBox(height: 10),

              Text(
                location.description!,
              ),
            ],

            if (location.openHours
                .isNotEmpty) ...[
              const SizedBox(height: 10),

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 18,
                  ),

                  const SizedBox(width: 6),

                  Expanded(
                    child: Text(
                      location
                          .openHours
                          .join('\n'),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed:
                    onDirections,

                icon: const Icon(
                  Icons
                      .directions_rounded,
                ),

                label: const Text(
                  'Chỉ đường',
                ),

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor:
                      Colors.white,

                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 14,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// OSM BADGE
// ─────────────────────────────────────────────────────────────

class _OsmBadge
    extends StatelessWidget {
  const _OsmBadge({
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),

      decoration: BoxDecoration(
        color: Colors.black87,

        borderRadius:
            BorderRadius.circular(30),
      ),

      child: Text(
        'OSM: $count',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ERROR BANNER
// ─────────────────────────────────────────────────────────────

class _ErrorBanner
    extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin:
            const EdgeInsets.all(20),

        padding:
            const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            20,
          ),
        ),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 42,
              color: Colors.red,
            ),

            const SizedBox(height: 12),

            Text(
              message,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: onRetry,
              child: const Text(
                'Thử lại',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SMALL BANNER
// ─────────────────────────────────────────────────────────────

class _SmallBanner
    extends StatelessWidget {
  const _SmallBanner({
    required this.message,
    required this.icon,
    required this.color,
  });

  final String message;

  final IconData icon;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius:
          BorderRadius.circular(14),

      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            14,
          ),
        ),

        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 18,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}