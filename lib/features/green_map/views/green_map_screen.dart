import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import 'package:green_app/data/models/green_location_model.dart';
import '../viewmodels/map_viewmodel.dart';

class GreenMapScreen extends ConsumerStatefulWidget {
  const GreenMapScreen({super.key});

  @override
  ConsumerState<GreenMapScreen> createState() => _GreenMapScreenState();
}

class _GreenMapScreenState extends ConsumerState<GreenMapScreen> {
  final MapController _mapController = MapController();

  static const _defaultCenter = LatLng(16.0544, 108.2022); // Đà Nẵng

  // ── Helpers lấy màu từ AppColors ──────────────
  Color get _green => AppColors.primaryGreen;
  Color get _colorCharging => const Color(0xFF64B5F6);
  Color get _colorGreenMarket => const Color(0xFFFFB347);
  Color get _surface => Theme.of(context).colorScheme.surface;
  Color get _border => Theme.of(context).colorScheme.outline;
  Color get _textPrimary => Theme.of(context).colorScheme.onSurface;
  Color get _textSub =>
      Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
      Colors.grey.shade600;

  IconData _getMarkerIcon(GreenLocationType type) {
    switch (type) {
      case GreenLocationType.recycling:
        return Icons.recycling_rounded;
      case GreenLocationType.charging:
        return Icons.electric_bolt_rounded;
      case GreenLocationType.greenMarket:
        return Icons.storefront_rounded;
    }
  }

  Color _getMarkerColor(GreenLocationType type) {
    switch (type) {
      case GreenLocationType.recycling:
        return _green;
      case GreenLocationType.charging:
        return _colorCharging;
      case GreenLocationType.greenMarket:
        return _colorGreenMarket;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapViewModelProvider);
    final vm = ref.read(mapViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Green Map'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Map ──────────────────────────────
            _buildMap(state, vm),

            // ── Top overlay ──────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopOverlay(state, vm),
            ),

            // ── Bottom stats bar ─────────────────
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: _buildBottomBar(state),
            ),

            // ── Loading overlay ───────────────────
            if (state.isLoading)
              Center(
                child: CircularProgressIndicator(color: _green),
              ),

            // ── Selected location panel ───────────
            if (state.selectedLocation != null)
              Positioned(
                bottom: 80,
                left: 16,
                right: 16,
                child: _LocationDetailCard(
                  location: state.selectedLocation!,
                  onClose: vm.clearSelection,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(MapState state, MapViewModel vm) {
    final initialPos = state.userLocation ?? _defaultCenter;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialPos,
        initialZoom: 13.5,
        minZoom: 5,
        maxZoom: 18,
        onTap: (_, __) => vm.clearSelection(),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.green_app',
        ),
        MarkerLayer(
          markers: _buildMarkers(state, vm),
        ),
      ],
    );
  }

  List<Marker> _buildMarkers(MapState state, MapViewModel vm) {
    return state.filteredLocations.map((loc) {
      return Marker(
        point: loc.position,
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => vm.selectLocation(loc),
          child: Icon(
            _getMarkerIcon(loc.type),
            color: _getMarkerColor(loc.type),
            size: 38,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildTopOverlay(MapState state, MapViewModel vm) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.55),
            Colors.transparent,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Row(
                children: [
                  Icon(Icons.location_on_rounded, color: _green, size: 18),
                  const SizedBox(width: 5),
                  Text(
                    'Green Map',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Near me button
              GestureDetector(
                onTap: _goToUserLocation,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.near_me_rounded, color: _green, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        'Gần đây',
                        style: TextStyle(color: _textSub, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Search bar
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: _surface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.search_rounded, color: _textSub, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Tìm điểm thu gom, chợ xanh...',
                  style: TextStyle(color: _textSub, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _MapFilterChip(
                  label: 'Tất cả',
                  emoji: '📋',
                  isActive: state.activeFilter == null,
                  onTap: () => vm.setFilter(null),
                  activeColor: _green,
                ),
                const SizedBox(width: 8),
                _MapFilterChip(
                  label: 'Thu gom',
                  emoji: '♻️',
                  isActive: state.activeFilter == GreenLocationType.recycling,
                  onTap: () => vm.setFilter(GreenLocationType.recycling),
                  activeColor: _green,
                ),
                const SizedBox(width: 8),
                _MapFilterChip(
                  label: 'Sạc điện',
                  emoji: '⚡',
                  isActive: state.activeFilter == GreenLocationType.charging,
                  onTap: () => vm.setFilter(GreenLocationType.charging),
                  activeColor: _colorCharging,
                ),
                const SizedBox(width: 8),
                _MapFilterChip(
                  label: 'Chợ X',
                  emoji: '🌿',
                  isActive:
                      state.activeFilter == GreenLocationType.greenMarket,
                  onTap: () => vm.setFilter(GreenLocationType.greenMarket),
                  activeColor: _colorGreenMarket,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LegendDot(color: _green, label: 'Điểm Thu Gom'),
                const SizedBox(width: 12),
                _LegendDot(color: _colorCharging, label: 'Trạm Sạc Điện'),
                const SizedBox(width: 12),
                _LegendDot(color: _colorGreenMarket, label: 'Chợ Xanh'),
                const SizedBox(width: 12),
                const _LegendDot(color: Colors.blueAccent, label: 'Vị trí bạn'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(MapState state) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xE6091509), Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatChip(
            emoji: '♻️',
            count: state.count(GreenLocationType.recycling),
            label: 'Điểm thu gom',
            color: AppColors.primaryGreen,
          ),
          _StatChip(
            emoji: '⚡',
            count: state.count(GreenLocationType.charging),
            label: 'Trạm sạc',
            color: const Color(0xFF64B5F6),
          ),
          _StatChip(
            emoji: '🌿',
            count: state.count(GreenLocationType.greenMarket),
            label: 'Chợ xanh',
            color: const Color(0xFFFFB347),
          ),
        ],
      ),
    );
  }

  Future<void> _goToUserLocation() async {
    final userPos = ref.read(mapViewModelProvider).userLocation;
    if (userPos == null) return;
    _mapController.move(userPos, 15.0);
  }
}

// ─────────────────────────────────────────────
//  Map Filter Chip
// ─────────────────────────────────────────────
class _MapFilterChip extends StatelessWidget {
  const _MapFilterChip({
    required this.label,
    required this.emoji,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
  });

  final String label;
  final String emoji;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final border = Theme.of(context).colorScheme.outline;
    final textSub =
        Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
            Colors.grey.shade600;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.25)
              : surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : textSub,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Legend dot
// ─────────────────────────────────────────────
class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textSub =
        Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.75) ??
            Colors.grey.shade600;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: textSub, fontSize: 10)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Stat chip (bottom bar)
// ─────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.emoji,
    required this.count,
    required this.label,
    required this.color,
  });

  final String emoji;
  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textSub =
        Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
            Colors.grey.shade600;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        Text(label, style: TextStyle(color: textSub, fontSize: 10)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Location Detail Card
// ─────────────────────────────────────────────
class _LocationDetailCard extends StatelessWidget {
  const _LocationDetailCard({required this.location, required this.onClose});

  final GreenLocation location;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final textSub =
        Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
            Colors.grey.shade600;
    final textPrimary = Theme.of(context).colorScheme.onSurface;

    final typeColor = location.type == GreenLocationType.recycling
        ? AppColors.primaryGreen
        : location.type == GreenLocationType.charging
            ? const Color(0xFF64B5F6)
            : const Color(0xFFFFB347);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: typeColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    location.type.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        location.type.label,
                        style: TextStyle(color: typeColor, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon:
                    Icon(Icons.close_rounded, color: textSub, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (location.address != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.location_on_outlined, color: textSub, size: 14),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    location.address!,
                    style: TextStyle(color: textSub, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          if (location.description != null) ...[
            const SizedBox(height: 6),
            Text(
              location.description!,
              style: TextStyle(color: textSub, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (location.openHours.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.access_time_rounded, color: textSub, size: 14),
                const SizedBox(width: 5),
                Text(
                  location.openHours.join(', '),
                  style: TextStyle(color: textSub, fontSize: 12),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.directions_rounded, size: 16),
              label: const Text('Chỉ đường'),
              style: ElevatedButton.styleFrom(
                backgroundColor: typeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}