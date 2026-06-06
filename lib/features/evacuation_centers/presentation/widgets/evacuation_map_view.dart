import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:project_bihon/features/dashboard/presentation/widgets/dashboard_design.dart';
import 'package:project_bihon/features/evacuation_centers/data/models/cached_evac_center.dart';
import 'package:project_bihon/shared/widgets/app_badge.dart';

/// Map widget displaying evacuation centers with distance-aware markers.
///
/// Features:
/// - Displays evacuation centers as markers on a map
/// - Marker colors indicate status
/// - Shows user location as a distinct orange marker if provided
/// - Bottom sheet on marker tap with center details
/// - Defaults to Baybay City view if no user position provided
/// - Uses the existing FlutterMap tile layer
class EvacuationMapView extends StatelessWidget {
  const EvacuationMapView({
    super.key,
    required this.centers,
    this.userPosition,
    this.onInteractionChanged,
  });

  /// List of evacuation centers to display as markers.
  final List<CachedEvacCenter> centers;

  /// Optional user position; if provided, map centers on user and shows user marker.
  final Position? userPosition;

  /// Notifies a parent swipe container when the user is interacting with the map.
  final ValueChanged<bool>? onInteractionChanged;

  Color _getMarkerColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return DashboardDesign.success;
      case 'near capacity':
        return DashboardDesign.warning;
      case 'full':
      case 'closed':
        return DashboardDesign.danger;
      default:
        return Colors.grey;
    }
  }

  void _showCenterDetails(BuildContext context, CachedEvacCenter center) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              center.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Capacity: ${center.capacity}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                AppBadge(
                  variant: center.status.toLowerCase() == 'open'
                      ? AppBadgeVariant.primary
                      : center.status.toLowerCase() == 'near capacity'
                          ? AppBadgeVariant.secondary
                          : AppBadgeVariant.destructive,
                  child: Text(center.status),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapCenter = userPosition != null
        ? ll.LatLng(userPosition!.latitude, userPosition!.longitude)
        : const ll.LatLng(10.6840, 124.8000);

    final mapZoom = userPosition != null ? 15.0 : 13.0;

    final markers = <fm.Marker>[
      if (userPosition != null)
        fm.Marker(
          point: ll.LatLng(userPosition!.latitude, userPosition!.longitude),
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFF7A1A),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.my_location,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ...centers.where((center) => center.hasValidCoordinates).map(
        (center) => fm.Marker(
          point: ll.LatLng(center.latitude, center.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showCenterDetails(context, center),
            child: Container(
              decoration: BoxDecoration(
                color: _getMarkerColor(center.status),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    ];

    return Listener(
      onPointerDown: (_) => onInteractionChanged?.call(true),
      onPointerUp: (_) => onInteractionChanged?.call(false),
      onPointerCancel: (_) => onInteractionChanged?.call(false),
      child: fm.FlutterMap(
        options: fm.MapOptions(
          initialCenter: mapCenter,
          initialZoom: mapZoom,
        ),
        children: [
          fm.TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.project_bihon',
          ),
          fm.MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}
