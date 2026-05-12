// lib/features/green_map/views/green_map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/flutter_map.dart' show CircleLayer, CircleMarker;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/green_location_model.dart';
import '../viewmodels/map_viewmodel.dart';

// ── Màu theo loại ─────────────────────────────────────────────────────────────
const _kRecyclingColor = AppColors.primaryGreen;
const _kChargingColor  = Color(0xFF42A5F5);
const _kMarketColor    = Color(0xFFFF9800);
const _kUserColor      = Color(0xFF5C6BC0);
const _kRadiusColor    = Color(0x1A2DDA93); // vòng bán kính xanh nhạt

Color _typeColor(GreenLocationType t) {
  switch (t) {
    case GreenLocationType.recycling:   return _kRecyclingColor;
    case GreenLocationType.charging:    return _kChargingColor;
    case GreenLocationType.greenMarket: return _kMarketColor;
  }
}

IconData _typeIcon(GreenLocationType t) {
  switch (t) {
    case GreenLocationType.recycling:   return Icons.recycling_rounded;
    case GreenLocationType.charging:    return Icons.electric_bolt_rounded;
    case GreenLocationType.greenMarket: return Icons.storefront_rounded;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Screen
// ─────────────────────────────────────────────────────────────────────────────

class GreenMapScreen extends ConsumerStatefulWidget {
  const GreenMapScreen({super.key});

  @override
  ConsumerState<GreenMapScreen> createState() => _GreenMapScreenState();
}

class _GreenMapScreenState extends ConsumerState<GreenMapScreen> {
  final _mapCtrl    = MapController();
  final _searchCtrl = TextEditingController();

  static const _defaultCenter = LatLng(16.0544, 108.2022); // Đà Nẵng
  static const _osmRadiusMeters = 5000.0; // bán kính 5km

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _goToUser() {
    final pos = ref.read(mapViewModelProvider).userLocation;
    if (pos != null) _mapCtrl.move(pos, 14.0);
  }

  Future<void> _openDirections(GreenLocation loc) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${loc.position.latitude},${loc.position.longitude}'
      '&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context, ) {
    final state  = ref.watch(mapViewModelProvider);
    final vm     = ref.read(mapViewModelProvider.notifier);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Row(
          children: [
            Icon(Icons.eco_rounded, color: AppColors.primaryGreen, size: 20),
            SizedBox(width: 6),
            Text('Green Map',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        actions: [
          if (state.isOsmLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    color: AppColors.primaryGreen, strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: vm.refresh,
          ),
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            onPressed: _goToUser,
          ),
        ],
      ),

      body: Column(
        children: [
          // Search + Filter
          _SearchFilterPanel(
            searchCtrl:      _searchCtrl,
            activeFilter:    state.activeFilter,
            onFilterChanged: vm.setFilter,
            onSearchChanged: (_) => setState(() {}),
          ),

          // Stat bar
          _StatBar(state: state),

          // Map chiếm phần còn lại
          Expanded(
            child: Stack(
              children: [
                // ── FlutterMap ─────────────────────────────────────────────
                _buildMap(state, vm),

                // Loading overlay lần đầu
                if (state.isLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.18),
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryGreen),
                    ),
                  ),

                // OSM badge góc trên phải
                if (state.osmFetched && state.countOsm() > 0)
                  Positioned(
                    top: 10, right: 10,
                    child: _OsmBadge(count: state.countOsm()),
                  ),

                // Error banner nhỏ
                if (state.error != null && !state.isLoading)
                  _ErrorBanner(message: state.error!, onRetry: vm.refresh),

                // OSM error nhỏ
                if (state.osmError != null && !state.isOsmLoading)
                  Positioned(
                    top: 10, left: 10, right: 60,
                    child: _SmallBanner(
                      message: 'Không tải được OSM. Chỉ hiện Firebase.',
                      icon:    Icons.cloud_off_rounded,
                      color:   AppColors.accentOrange,
                    ),
                  ),

                // Location detail card (bên dưới map)
                if (state.selectedLocation != null)
                  Positioned(
                    left: 12, right: 12, bottom: 12,
                    child: _LocationDetailCard(
                      location:     state.selectedLocation!,
                      onClose:      vm.clearSelection,
                      onDirections: () =>
                          _openDirections(state.selectedLocation!),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── BUILD MAP ───────────────────────────────────────────────────────────────

  Widget _buildMap(MapState state, MapViewModel vm) {
    final center = state.userLocation ?? _defaultCenter;
    final query  = _searchCtrl.text.toLowerCase().trim();

    // Lọc theo search + filter
    final visible = state.filteredLocations.where((loc) {
      if (query.isEmpty) return true;
      return loc.name.toLowerCase().contains(query) ||
          (loc.address?.toLowerCase().contains(query) ?? false);
    }).toList();

    return FlutterMap(
      mapController: _mapCtrl,
      options: MapOptions(
  initialCenter: center,
  initialZoom: 13.5,
  minZoom: 5,
  maxZoom: 19,

  // Tap nền → bỏ chọn
  onTap: (_, __) => vm.clearSelection(),

  // Auto fetch OSM khi kéo map
  onPositionChanged: (position, hasGesture) {
      final center = position.center;
    if (hasGesture && center != null) {
      vm.fetchOsmAt(center);
    }
  },
),
      children: [
        // ── 1. Tile layer (OpenStreetMap) ─────────────────────────────────
        TileLayer(
          urlTemplate:          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.green_app',
          maxZoom:              19,
        ),

        // ── 2. Vòng bán kính 5km quanh user ──────────────────────────────
        if (state.userLocation != null)
          CircleLayer(
            circles: [
              // Vùng fill nhạt
              CircleMarker(
                point:       state.userLocation!,
                radius:      _osmRadiusMeters,
                useRadiusInMeter: true,
                color:       _kRadiusColor,
                borderColor: AppColors.primaryGreen.withValues(alpha: 0.5),
                borderStrokeWidth: 1.5,
              ),
            ],
          ),

        // ── 3. Markers các địa điểm xanh ─────────────────────────────────
        MarkerLayer(
          rotate:  true, // marker luôn thẳng khi xoay map
          markers: [
            // Vị trí user — render sau cùng để nằm trên
            if (state.userLocation != null)
              Marker(
                point:  state.userLocation!,
                width:  50,
                height: 50,
                // alignment: center — tọa độ đúng tâm marker
                child: const _UserMarker(),
              ),

            // Các địa điểm — width/height = kích thước bubble thôi
            // KHÔNG dùng alignment: topCenter (sẽ lệch tọa độ)
            ...visible.map((loc) {
              final isSelected = state.selectedLocation?.id == loc.id;
              return Marker(
                point:  loc.position,
                width:  isSelected ? 52 : 42,
                height: isSelected ? 52 : 42,
                // Căn tọa độ vào giữa marker
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    vm.selectLocation(loc);
                    // Animate map đến marker
                    _mapCtrl.move(loc.position, _mapCtrl.camera.zoom < 14
                        ? 14.0
                        : _mapCtrl.camera.zoom);
                  },
                  child: _MarkerBubble(
                    type:       loc.type,
                    source:     loc.source,
                    isSelected: isSelected,
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

// ─────────────────────────────────────────────────────────────────────────────
//  Marker Bubble — tròn, không có đuôi (tránh lệch tọa độ)
// ─────────────────────────────────────────────────────────────────────────────

class _MarkerBubble extends StatelessWidget {
  const _MarkerBubble({
    required this.type,
    required this.source,
    required this.isSelected,
  });
  final GreenLocationType type;
  final LocationSource    source;
  final bool              isSelected;

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(type);
    final isOsm = source == LocationSource.osm;
    final size  = isSelected ? 52.0 : 42.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width:  size,
      height: size,
      decoration: BoxDecoration(
        color: isOsm
            ? color.withValues(alpha: 0.80)
            : color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
          width: isSelected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color:      color.withValues(alpha: isSelected ? 0.7 : 0.4),
            blurRadius: isSelected ? 16 : 8,
            spreadRadius: isSelected ? 3 : 1,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            _typeIcon(type),
            color: Colors.white,
            size:  isSelected ? 26 : 20,
          ),
          // Badge nhỏ OSM góc dưới phải
          if (isOsm)
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                  color:  Colors.white,
                  shape:  BoxShape.circle,
                  border: Border.all(color: color, width: 1),
                ),
                child: const Center(
                  child: Icon(Icons.public_rounded,
                      size: 9, color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  User Marker
// ─────────────────────────────────────────────────────────────────────────────

class _UserMarker extends StatelessWidget {
  const _UserMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Halo
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color:  _kUserColor.withValues(alpha: 0.20),
            shape:  BoxShape.circle,
          ),
        ),
        // Dot
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            color:  _kUserColor,
            shape:  BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color:      _kUserColor.withValues(alpha: 0.6),
                blurRadius: 8,
                offset:     const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Search + Filter Panel
// ─────────────────────────────────────────────────────────────────────────────

class _SearchFilterPanel extends StatelessWidget {
  const _SearchFilterPanel({
    required this.searchCtrl,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.onSearchChanged,
  });

  final TextEditingController  searchCtrl;
  final GreenLocationType?     activeFilter;
  final void Function(GreenLocationType?) onFilterChanged;
  final void Function(String)             onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: searchCtrl,
            onChanged:  onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm tên hoặc địa chỉ...',
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.textSecondary, size: 20),
              suffixIcon: searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          color: AppColors.textSecondary, size: 18),
                      onPressed: () {
                        searchCtrl.clear();
                        onSearchChanged('');
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),

          // Filter chips
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  emoji: '📋', label: 'Tất cả',
                  active: activeFilter == null,
                  color: AppColors.primaryGreen,
                  onTap: () => onFilterChanged(null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  emoji: '♻️', label: 'Thu gom',
                  active: activeFilter == GreenLocationType.recycling,
                  color: _kRecyclingColor,
                  onTap: () => onFilterChanged(GreenLocationType.recycling),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  emoji: '⚡', label: 'Sạc điện',
                  active: activeFilter == GreenLocationType.charging,
                  color: _kChargingColor,
                  onTap: () => onFilterChanged(GreenLocationType.charging),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  emoji: '🌿', label: 'Chợ xanh',
                  active: activeFilter == GreenLocationType.greenMarket,
                  color: _kMarketColor,
                  onTap: () => onFilterChanged(GreenLocationType.greenMarket),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.emoji,
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });
  final String emoji, label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.18)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? color : scheme.outline,
              width: active ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                  color:      active ? color : AppColors.textSecondary,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  fontSize:   12,
                )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Stat Bar
// ─────────────────────────────────────────────────────────────────────────────

class _StatBar extends StatelessWidget {
  const _StatBar({required this.state});
  final MapState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(emoji: '♻️', label: 'Thu gom',
              count: state.count(GreenLocationType.recycling),
              color: _kRecyclingColor),
          _Divider(),
          _StatItem(emoji: '⚡', label: 'Sạc điện',
              count: state.count(GreenLocationType.charging),
              color: _kChargingColor),
          _Divider(),
          _StatItem(emoji: '🌿', label: 'Chợ xanh',
              count: state.count(GreenLocationType.greenMarket),
              color: _kMarketColor),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.emoji, required this.label,
    required this.count, required this.color,
  });
  final String emoji, label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$count địa điểm',
                style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      height: 28, width: 1,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5));
}

// ─────────────────────────────────────────────────────────────────────────────
//  OSM Badge
// ─────────────────────────────────────────────────────────────────────────────

class _OsmBadge extends StatelessWidget {
  const _OsmBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset:     const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.public_rounded,
              color: AppColors.primaryGreen, size: 13),
          const SizedBox(width: 4),
          Text('+$count OSM',
              style: const TextStyle(
                color:      AppColors.primaryGreen,
                fontSize:   11,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Location Detail Card
// ─────────────────────────────────────────────────────────────────────────────

class _LocationDetailCard extends StatelessWidget {
  const _LocationDetailCard({
    required this.location,
    required this.onClose,
    required this.onDirections,
  });
  final GreenLocation location;
  final VoidCallback  onClose;
  final VoidCallback  onDirections;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color  = _typeColor(location.type);
    final isOsm  = location.source == LocationSource.osm;

    return Material(
      elevation:    8,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color:        scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 0),
              child: Row(
                children: [
                  // Icon loại
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color:        color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(location.type.emoji,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(location.name,
                            style: TextStyle(
                              color:      scheme.onSurface,
                              fontWeight: FontWeight.w800,
                              fontSize:   15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Badge loại
                            _Badge(
                              label: location.type.label,
                              color: color,
                            ),
                            const SizedBox(width: 6),
                            // Badge nguồn
                            _Badge(
                              label:    isOsm ? 'OpenStreetMap' : 'Đã xác minh',
                              color:    isOsm ? Colors.grey : AppColors.primaryGreen,
                              icon:     isOsm
                                  ? Icons.public_rounded
                                  : Icons.verified_rounded,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed:   onClose,
                    icon:        Icon(Icons.close_rounded,
                        color: scheme.onSurface.withValues(alpha: 0.5),
                        size: 20),
                    padding:     EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),

            // Info rows
            if (location.address    != null ||
                location.description != null ||
                location.openHours.isNotEmpty ||
                location.phone       != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Column(
                  children: [
                    if (location.address != null)
                      _InfoRow(icon: Icons.location_on_outlined,
                          text: location.address!, color: color),
                    if (location.description != null)
                      _InfoRow(icon: Icons.info_outline_rounded,
                          text: location.description!, color: color,
                          maxLines: 2),
                    if (location.openHours.isNotEmpty)
                      _InfoRow(icon: Icons.access_time_rounded,
                          text: location.openHours.join('  •  '),
                          color: color),
                    if (location.phone != null)
                      _InfoRow(icon: Icons.phone_outlined,
                          text: location.phone!, color: color),
                  ],
                ),
              ),

            // Nút chỉ đường
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: onDirections,
                  icon:  const Icon(Icons.directions_rounded, size: 18),
                  label: const Text('Chỉ đường Google Maps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.icon});
  final String   label;
  final Color    color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    required this.color,
    this.maxLines = 1,
  });
  final IconData icon;
  final String   text;
  final Color    color;
  final int      maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 7),
          Expanded(
            child: Text(text,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Banners
// ─────────────────────────────────────────────────────────────────────────────

class _SmallBanner extends StatelessWidget {
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
      elevation: 3,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: TextStyle(color: color, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      top: 10, left: 12, right: 12,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color:        scheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_rounded, color: scheme.error, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message,
                    style: TextStyle(
                        color: scheme.onErrorContainer, fontSize: 12)),
              ),
              TextButton(
                  onPressed: onRetry,
                  child: const Text('Thử lại')),
            ],
          ),
        ),
      ),
    );
  }
}