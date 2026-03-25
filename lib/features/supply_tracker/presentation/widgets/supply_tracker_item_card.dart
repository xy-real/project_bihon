import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;
import 'package:shadcn_ui/shadcn_ui.dart';

class SupplyTrackerItemCard extends StatelessWidget {
  final String itemName;
  final String description;
  final int stockCount;
  final DateTime expirationDate;
  final String? imageUrl;
  final VoidCallback? onTap;

  const SupplyTrackerItemCard({
    super.key,
    required this.itemName,
    required this.description,
    required this.stockCount,
    required this.expirationDate,
    this.imageUrl,
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
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 270;
            final imageAspectRatio = isCompact ? 4 / 3 : 16 / 9;
            final iconSize = isCompact ? 12.0 : 13.0;
            final titleSize = isCompact ? 12.0 : 13.0;
            final descSize = isCompact ? 10.0 : 11.0;
            final labelSize = isCompact ? 8.0 : 9.0;
            final valueSize = isCompact ? 10.0 : 11.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onTap,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    child: AspectRatio(
                      aspectRatio: imageAspectRatio,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
                          ),
                        ),
                        child: imageUrl != null
                            ? Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildImagePlaceholder(context, iconSize);
                                },
                              )
                            : _buildImagePlaceholder(context, iconSize),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              itemName,
                              maxLines: isCompact ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: titleSize,
                                height: 1.1,
                              ),
                            ),
                          ),
                          if (isExpired || isExpiringSoon) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: isExpired ? Colors.red.shade100 : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                isExpired ? 'Exp' : 'Soon',
                                style: theme.labelSmall?.copyWith(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: isExpired ? Colors.red.shade700 : Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: isCompact ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.labelSmall?.copyWith(
                          fontSize: descSize,
                          height: 1.2,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (isCompact)
                        Column(
                          children: [
                            _CompactInfoGroup(
                              icon: lucide.LucideIcons.package,
                              iconSize: iconSize,
                              iconColor: Colors.grey.shade600,
                              label: 'Stock',
                              value: '$stockCount',
                              labelStyle: theme.labelSmall?.copyWith(
                                fontSize: labelSize,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                              valueStyle: theme.labelSmall?.copyWith(
                                fontSize: valueSize,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _CompactInfoGroup(
                              icon: lucide.LucideIcons.calendar,
                              iconSize: iconSize,
                              iconColor: isExpired
                                  ? Colors.red.shade600
                                  : isExpiringSoon
                                      ? Colors.orange.shade600
                                      : Colors.grey.shade600,
                              label: 'Date',
                              value: _formatDate(expirationDate).split('-').last,
                              labelStyle: theme.labelSmall?.copyWith(
                                fontSize: labelSize,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                              valueStyle: theme.labelSmall?.copyWith(
                                fontSize: valueSize,
                                fontWeight: FontWeight.w700,
                                color: isExpired
                                    ? Colors.red.shade600
                                    : isExpiringSoon
                                        ? Colors.orange.shade600
                                        : null,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _CompactInfoGroup(
                                icon: lucide.LucideIcons.package,
                                iconSize: iconSize,
                                iconColor: Colors.grey.shade600,
                                label: 'Stock',
                                value: '$stockCount',
                                labelStyle: theme.labelSmall?.copyWith(
                                  fontSize: labelSize,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                                valueStyle: theme.labelSmall?.copyWith(
                                  fontSize: valueSize,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _CompactInfoGroup(
                                icon: lucide.LucideIcons.calendar,
                                iconSize: iconSize,
                                iconColor: isExpired
                                    ? Colors.red.shade600
                                    : isExpiringSoon
                                        ? Colors.orange.shade600
                                        : Colors.grey.shade600,
                                label: 'Date',
                                value: _formatDate(expirationDate).split('-').last,
                                labelStyle: theme.labelSmall?.copyWith(
                                  fontSize: labelSize,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                                valueStyle: theme.labelSmall?.copyWith(
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
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(BuildContext context, double iconSize) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            lucide.LucideIcons.image,
            size: iconSize * 2.5,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'No image',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _CompactInfoGroup extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const _CompactInfoGroup({
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: iconSize, color: iconColor),
        const SizedBox(width: 3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: labelStyle),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: valueStyle),
            ],
          ),
        ),
      ],
    );
  }
}
