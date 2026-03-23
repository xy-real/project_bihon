import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;
import 'package:shadcn_ui/shadcn_ui.dart';

class SupplyTrackerItemCard extends StatelessWidget {
  final String itemName;
  final String description;
  final int stockCount;
  final DateTime expirationDate;
  final VoidCallback? onTap;

  const SupplyTrackerItemCard({
    super.key,
    required this.itemName,
    required this.description,
    required this.stockCount,
    required this.expirationDate,
    this.onTap,
  });

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isExpiringSoon() {
    final now = DateTime.now();
    final daysUntilExpiry = expirationDate.difference(now).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
  }

  bool _isExpired() {
    return DateTime.now().isAfter(expirationDate);
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _isExpired();
    final isExpiringSoon = _isExpiringSoon();
    final theme = Theme.of(context).textTheme;

    return ShadCard(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final widthScale = (constraints.maxWidth / 320).clamp(0.86, 1.08);
            final titleSize = 16.0 * widthScale;
            final descriptionSize = 13.0 * widthScale;
            final labelSize = 11.0 * widthScale;
            final valueSize = 14.0 * widthScale;
            final statusSize = 10.0 * widthScale;
            final iconSize = 16.0 * widthScale;
            final verticalGap = 8.0 * widthScale;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        itemName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.titleMedium?.copyWith(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (isExpired || isExpiringSoon) ...[
                      SizedBox(width: 8 * widthScale),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8 * widthScale,
                          vertical: 4 * widthScale,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isExpired ? Colors.red.shade100 : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isExpired ? 'Expired' : 'Expiring soon',
                          style: theme.labelSmall?.copyWith(
                            fontSize: statusSize,
                            fontWeight: FontWeight.w700,
                            color: isExpired
                                ? Colors.red.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: verticalGap),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyMedium?.copyWith(
                    fontSize: descriptionSize,
                    height: 1.25,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 12 * widthScale),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _InfoGroup(
                        icon: lucide.LucideIcons.package,
                        iconSize: iconSize,
                        iconColor: Colors.grey.shade600,
                        label: 'Stock',
                        value: '$stockCount items',
                        labelStyle: theme.labelSmall?.copyWith(
                          fontSize: labelSize,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                        valueStyle: theme.bodyMedium?.copyWith(
                          fontSize: valueSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: 12 * widthScale),
                    Expanded(
                      child: _InfoGroup(
                        icon: lucide.LucideIcons.calendar,
                        iconSize: iconSize,
                        iconColor: isExpired
                            ? Colors.red.shade600
                            : isExpiringSoon
                                ? Colors.orange.shade600
                                : Colors.grey.shade600,
                        label: 'Expires',
                        value: _formatDate(expirationDate),
                        labelStyle: theme.labelSmall?.copyWith(
                          fontSize: labelSize,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                        valueStyle: theme.bodyMedium?.copyWith(
                          fontSize: valueSize,
                          fontWeight: FontWeight.w700,
                          color: isExpired
                              ? Colors.red.shade600
                              : isExpiringSoon
                                  ? Colors.orange.shade600
                                  : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoGroup extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const _InfoGroup({
    required this.icon,
    required this.iconSize,
    required this.iconColor,
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: iconSize, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: labelStyle),
              const SizedBox(height: 2),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: valueStyle),
            ],
          ),
        ),
      ],
    );
  }
}
