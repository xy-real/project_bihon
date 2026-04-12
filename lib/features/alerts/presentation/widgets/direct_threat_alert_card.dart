import 'package:flutter/material.dart';
import 'package:project_bihon/features/alerts/data/models/cached_alert.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? Colors.orange[700]! : Colors.red;
    final accentBg = isDark ? Colors.orange[900]! : Colors.red[50]!;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: accentColor,
              width: 4,
              style: BorderStyle.solid,
            ),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with icon and label chip
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: accentColor,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Chip(
                        label: Text(
                          'HIGH RISK FOR YOUR AREA',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                        ),
                        backgroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Alert title
                  Text(
                    alert.title.isNotEmpty ? alert.title : 'Alert',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Alert content
                  Text(
                    alert.content.isNotEmpty
                        ? alert.content
                        : 'No additional details available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: textColor,
                          height: 1.5,
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Footer: severity badge and published date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          alert.severity.isNotEmpty
                              ? alert.severity.toUpperCase()
                              : 'UNKNOWN',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(alert.publishedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                      ),
                    ],
                  ),

                  // More details button
                  if (onMoreDetails != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onMoreDetails,
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text('More Details'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: accentColor),
                          foregroundColor: accentColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
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
