import 'package:flutter/material.dart';
import 'package:project_bihon/features/alerts/data/models/cached_alert.dart';

/// Alert card for general advisories to the household.
///
/// Displays alerts that do not match the household's risk classification
/// with standard, muted styling.
///
/// Visual hierarchy:
/// - Standard card style (no accent border)
/// - Small muted label: "General Baybay City Advisory"
/// - Alert title and content
///
/// Supports light and dark mode, handles empty/null values gracefully.
class GeneralAdvisoryAlertCard extends StatelessWidget {
  /// The alert data to display.
  final CachedAlert alert;

  /// Optional callback when card is tapped.
  final VoidCallback? onTap;

  /// Optional callback for more details/expand action.
  final VoidCallback? onMoreDetails;

  const GeneralAdvisoryAlertCard({
    super.key,
    required this.alert,
    this.onTap,
    this.onMoreDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                // Muted label
                Text(
                  'General Baybay City Advisory',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: mutedColor,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),

                // Alert title
                Text(
                  alert.title.isNotEmpty ? alert.title : 'Alert',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
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

                // Footer: advisory type and published date
                Row(
                  children: [
                    Text(
                      alert.advisoryType.isNotEmpty
                          ? alert.advisoryType
                          : 'Advisory',
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: mutedColor,
                                fontWeight: FontWeight.w500,
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
                    ),
                  ),
                ],
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
