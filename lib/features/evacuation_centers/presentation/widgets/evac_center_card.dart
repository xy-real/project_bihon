import 'package:flutter/material.dart';
import 'package:project_bihon/features/evacuation_centers/data/models/cached_evac_center.dart';
import 'package:project_bihon/shared/widgets/app_alert_banner.dart';
import 'package:project_bihon/shared/widgets/app_badge.dart';
import 'package:project_bihon/shared/widgets/app_card.dart';

/// Card widget displaying evacuation center information.
///
/// Shows:
/// - Center name (bold)
/// - Distance formatted as "X.X km" or "Distance unavailable"
/// - Capacity
/// - Status badge (green/yellow/red)
/// - Red alert if status is "Full" or "Closed"
class EvacCenterCard extends StatelessWidget {
  /// The evacuation center data to display.
  final CachedEvacCenter center;

  /// Optional distance in meters from user location.
  /// If null or not provided, displays "Distance unavailable".
  final double? distanceMeters;

  const EvacCenterCard({
    super.key,
    required this.center,
    this.distanceMeters,
  });

  /// Format distance from meters to kilometers with one decimal place.
  ///
  /// Returns "X.X km" if distanceMeters is provided, else "Distance unavailable".
  String _formatDistance() {
    if (distanceMeters == null) {
      return 'Distance unavailable';
    }
    final km = distanceMeters! / 1000;
    return '${km.toStringAsFixed(1)} km';
  }

  /// Determine badge variant based on evacuation center status.
  ///
  /// - "Open" → green (primary)
  /// - "Near Capacity" → yellow (secondary)
  /// - "Full" or "Closed" → red (destructive)
  /// - default → gray (outline)
  AppBadgeVariant _getBadgeVariant(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppBadgeVariant.primary;
      case 'near capacity':
        return AppBadgeVariant.secondary;
      case 'full':
      case 'closed':
        return AppBadgeVariant.destructive;
      default:
        return AppBadgeVariant.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFull = center.status.toLowerCase() == 'full' ||
        center.status.toLowerCase() == 'closed';

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name (bold)
          Text(
            center.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Distance
          Text(
            _formatDistance(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 12),

          // Capacity and Status row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Capacity
              Text(
                'Capacity: ${center.capacity}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              // Status Badge
              AppBadge(
                variant: _getBadgeVariant(center.status),
                child: Text(center.status),
              ),
            ],
          ),

          // Red alert if full or closed
          if (isFull) ...[
            const SizedBox(height: 12),
            AppAlertBanner(
              variant: AppAlertBannerVariant.destructive,
              title: '⚠ This center may be full. Seek an alternative.',
            ),
          ],
        ],
      ),
    );
  }
}
