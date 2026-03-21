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

    return ShadCard(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with item name and status indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      itemName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Expired',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                      ),
                    )
                  else if (isExpiringSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Soon',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // Description
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              // Stock and Expiration Date row
              Column(
                children: [
                  // Stock Count
                  Row(
                    children: [
                      Icon(
                        lucide.LucideIcons.package,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stock',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.grey.shade600,
                                    fontSize: 10,
                                  ),
                            ),
                            Text(
                              '$stockCount items',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Expiration Date
                  Row(
                    children: [
                      Icon(
                        lucide.LucideIcons.calendar,
                        size: 16,
                        color: isExpired
                            ? Colors.red.shade600
                            : isExpiringSoon
                                ? Colors.orange.shade600
                                : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expires',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.grey.shade600,
                                    fontSize: 10,
                                  ),
                            ),
                            Text(
                              _formatDate(expirationDate),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                    color: isExpired
                                        ? Colors.red.shade600
                                        : isExpiringSoon
                                            ? Colors.orange.shade600
                                            : null,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
