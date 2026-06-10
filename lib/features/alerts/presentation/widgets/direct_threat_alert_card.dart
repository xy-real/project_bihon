import 'package:flutter/material.dart';
import 'package:project_bihon/features/alerts/data/models/cached_alert.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/dashboard_design.dart';

/// Alert card for direct threats to the household.
///
/// Displays alerts that match the household's risk classification with
/// high-contrast styling to draw attention.
///
/// Visual hierarchy:
/// - High-contrast left border (red/deep orange)
/// - Leading warning icon
/// - "HIGH RISK FOR YOUR AREA" label chip
/// - Alert title and content
///
/// Supports light and dark mode, handles empty/null values gracefully.
class DirectThreatAlertCard extends StatelessWidget {
  /// The alert data to display.
  final CachedAlert alert;

  /// Optional callback when card is tapped.
  final VoidCallback? onTap;

  /// Optional callback for more details/expand action.
  final VoidCallback? onMoreDetails;

  const DirectThreatAlertCard({
    super.key,
    required this.alert,
    this.onTap,
    this.onMoreDetails,
  });

  @override
  Widget build(BuildContext context) {
    const accentColor = DashboardDesign.danger;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.transparent,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DashboardDesign.radius),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: DashboardDesign.surface(context),
          borderRadius: BorderRadius.circular(DashboardDesign.radius),
          border: Border.all(color: DashboardDesign.outline(context)),
          boxShadow: DashboardDesign.cardShadow(context),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DashboardDesign.radius),
            child: Stack(
              children: [
                const Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(DashboardDesign.radius),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(21, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StatusIcon(color: accentColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              alert.title.isNotEmpty ? alert.title : 'Alert',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                  ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _StatusBadge(
                            label: 'URGENT',
                            color: accentColor,
                            backgroundColor: const Color(0xFFFFDAD6),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        alert.content.isNotEmpty
                            ? alert.content
                            : 'No additional details available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: DashboardDesign.mutedText(context),
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatDate(alert.publishedAt),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: DashboardDesign.mutedText(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          if (onMoreDetails != null)
                            TextButton(
                              onPressed: onMoreDetails,
                              style: TextButton.styleFrom(
                                foregroundColor: accentColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                minimumSize: const Size(48, 40),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('More Details'),
                                  SizedBox(width: 2),
                                  Icon(Icons.chevron_right, size: 18),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Format a DateTime to a readable date string.
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: DashboardDesign.statusBackground(context, color),
        borderRadius: BorderRadius.circular(DashboardDesign.compactRadius),
      ),
      child: Icon(
        Icons.warning_amber_rounded,
        color: color,
        size: 26,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          backgroundColor.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? 0.28 : 1,
          ),
          DashboardDesign.surface(context),
        ),
        borderRadius: BorderRadius.circular(DashboardDesign.compactRadius),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
      ),
    );
  }
}
