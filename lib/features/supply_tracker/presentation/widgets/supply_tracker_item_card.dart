import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;
import 'package:project_bihon/features/dashboard/presentation/widgets/dashboard_design.dart';
import 'package:project_bihon/features/supply_tracker/data/models/supply_item.dart';

class SupplyTrackerItemCard extends StatelessWidget {
  final String itemName;
  final String description;
  final int stockCount;
  final DateTime expirationDate;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final SupplyItem? supplyItem;

  const SupplyTrackerItemCard({
    super.key,
    required this.itemName,
    required this.description,
    required this.stockCount,
    required this.expirationDate,
    this.imageUrl,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.supplyItem,
  });

  bool get _isExpired {
    return supplyItem?.isExpired ?? DateTime.now().isAfter(expirationDate);
  }

  bool get _isExpiringSoon {
    if (_isExpired) {
      return false;
    }
    if (supplyItem != null) {
      return supplyItem!.expiresSoon;
    }
    final daysUntilExpiry = expirationDate.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 7 && daysUntilExpiry >= 0;
  }

  Color get _statusColor {
    if (_isExpired) {
      return DashboardDesign.danger;
    }
    if (_isExpiringSoon) {
      return DashboardDesign.warning;
    }
    return DashboardDesign.success;
  }

  IconData get _categoryIcon {
    final category = description.toLowerCase();
    if (category.contains('water') || category.contains('hydrat')) {
      return lucide.LucideIcons.droplets;
    }
    if (category.contains('med') ||
        category.contains('medicine') ||
        category.contains('medical')) {
      return lucide.LucideIcons.pill;
    }
    if (category.contains('food')) {
      return lucide.LucideIcons.utensils;
    }
    if (category.contains('tool')) {
      return lucide.LucideIcons.wrench;
    }
    if (category.contains('hygiene')) {
      return lucide.LucideIcons.sparkles;
    }
    return lucide.LucideIcons.package;
  }

  String get _statusLabel {
    if (_isExpired) {
      return 'EXPIRED';
    }
    if (_isExpiringSoon) {
      final days = expirationDate.difference(DateTime.now()).inDays.clamp(0, 7);
      return '$days ${days == 1 ? 'DAY' : 'DAYS'}!';
    }
    return 'OK';
  }

  String get _formattedExpirationDate {
    return '${expirationDate.month.toString().padLeft(2, '0')}/'
        '${expirationDate.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor;
    final hasActions = onEdit != null || onDelete != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DashboardDesign.radius),
        child: Ink(
          decoration: BoxDecoration(
            color: DashboardDesign.surface(context),
            borderRadius: BorderRadius.circular(DashboardDesign.radius),
            border: Border.all(color: DashboardDesign.outline(context)),
            boxShadow: DashboardDesign.cardShadow(context),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DashboardDesign.radius),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 5,
                    color: statusColor,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: DashboardDesign.statusBackground(
                                context,
                                statusColor,
                              ),
                            ),
                            child: Icon(
                              _categoryIcon,
                              color: statusColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  itemName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$description - $stockCount',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: DashboardDesign.mutedText(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      lucide.LucideIcons.calendarDays,
                                      size: 16,
                                      color: DashboardDesign.mutedText(context),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Exp: $_formattedExpirationDate',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: DashboardDesign.mutedText(
                                            context,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _StatusBadge(
                                label: _statusLabel,
                                color: statusColor,
                              ),
                              if (hasActions) ...[
                                const SizedBox(height: 8),
                                PopupMenuButton<_SupplyCardAction>(
                                  tooltip: 'Supply item actions',
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (action) {
                                    switch (action) {
                                      case _SupplyCardAction.edit:
                                        onEdit?.call();
                                      case _SupplyCardAction.delete:
                                        onDelete?.call();
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    if (onEdit != null)
                                      const PopupMenuItem<_SupplyCardAction>(
                                        value: _SupplyCardAction.edit,
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                    if (onDelete != null)
                                      const PopupMenuItem<_SupplyCardAction>(
                                        value: _SupplyCardAction.delete,
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline),
                                            SizedBox(width: 8),
                                            Text('Delete'),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _SupplyCardAction { edit, delete }

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DashboardDesign.statusBackground(context, color),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}
