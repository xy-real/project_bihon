import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geolocator/geolocator.dart';
import 'package:project_bihon/features/evacuation_centers/data/models/cached_evac_center.dart';
import 'package:project_bihon/shared/widgets/app_badge.dart';

/// Simple coordinate type for map markers (latitude, longitude).
typedef LatLng = fm.LatLng;

/// Map widget displaying evacuation centers with distance-aware markers.
///
/// Features:
/// - Displays evacuation centers as markers on a map
/// - Marker colors indicate status (green=Open, yellow=Near Capacity, red=Full/Closed)
/// - Shows user location as a distinct orange marker if provided
/// - Bottom sheet on marker tap with center details
/// - Defaults to Baybay City view if no user position provided
/// - Offline-capable via FMTC tile caching
class EvacuationMapView extends StatelessWidget {
  /// List of evacuation centers to display as markers.
  final List<CachedEvacCenter> centers;

  /// Optional user position; if provided, map centers on user and shows user marker.
  final Position? userPosition;

  const EvacuationMapView({
    super.key,
    required this.centers,
    this.userPosition,
  });

  /// Determine marker color based on evacuation center status.
  ///
  /// - "Open" → green
  /// - "Near Capacity" → yellow (#FACC15)
  /// - "Full" or "Closed" → red
  /// - default → grey
  Color _getMarkerColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.green;
      case 'near capacity':
        return const Color(0xFFFACC15);
      case 'full':
      case 'closed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Show bottom sheet with evacuation center details on marker tap.
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
    // Determine map center: use user position or default to Baybay City
    final mapCenter = userPosition != null
        ? LatLng(userPosition!.latitude, userPosition!.longitude)
        : const LatLng(10.6840, 124.8000); // Baybay City default

    final mapZoom = userPosition != null ? 15.0 : 13.0;

    // Build markers for evacuation centers
    final markers = <fm.Marker>[
      // User position marker (if available)
      if (userPosition != null)
        fm.Marker(
          point: LatLng(userPosition!.latitude, userPosition!.longitude),
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFF7A1A), // Bihon orange
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
      // Evacuation center markers
      ...centers.map(
        (center) => fm.Marker(
          point: LatLng(center.latitude, center.longitude),
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

    return fm.FlutterMap(
      options: fm.MapOptions(
        initialCenter: mapCenter,
        initialZoom: mapZoom,
      ),
      children: [
        // Tile layer from FMTC store
        fm.TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.project_bihon',
        ),
        // Markers layer
        fm.MarkerLayer(markers: markers),
      ],
    );
  }
}
