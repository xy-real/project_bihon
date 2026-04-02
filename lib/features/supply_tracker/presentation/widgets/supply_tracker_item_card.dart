import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;
import 'package:project_bihon/features/supply_tracker/data/models/supply_item.dart';
import 'package:project_bihon/shared/widgets/app_button.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool get _isExpired {
    return supplyItem?.isExpired ?? DateTime.now().isAfter(expirationDate);
  }

  bool get _isExpiringSoon {
    if (supplyItem != null) {
      return supplyItem!.expiresSoon;
    }
    final daysUntilExpiry = expirationDate.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 7 && daysUntilExpiry >= 0;
  }

  Color _getBorderColor() {
    if (_isExpired) return Colors.red.shade300;
    if (_isExpiringSoon) return Colors.orange.shade300;
    return Colors.green.shade200;
  }

  Color _getBackgroundTint() {
    if (_isExpired) {
      return Colors.red.shade50;
    } else if (_isExpiringSoon) {
      return Colors.orange.shade50;
    } else {
      return Colors.green.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _isExpired;
    final isExpiringSoon = _isExpiringSoon;
    final theme = Theme.of(context).textTheme;
    final borderColor = _getBorderColor();
    final bgTint = _getBackgroundTint();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ShadCard(
        padding: EdgeInsets.zero,
        child: Container(
          color: bgTint,
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
                                          : Colors.green.shade600,
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
                                            : Colors.green.shade600,
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
                                            : Colors.green.shade600,
                                    label: 'Date',
                                    value: _formatDate(expirationDate),
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
                                              : Colors.green.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (onEdit != null || onDelete != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (onEdit != null)
                                  Expanded(
                                    child: AppButton(
                                      onPressed: onEdit,
                                      variant: AppButtonVariant.outline,
                                      size: AppButtonSize.small,
                                      expands: true,
                                      lightBackgroundColor: Colors.amber.shade100,
                                      darkBackgroundColor: Colors.amber.shade200,
                                      lightForegroundColor: Colors.amber.shade900,
                                      darkForegroundColor: Colors.amber.shade900,
                                      lightBorderColor: Colors.amber.shade300,
                                      darkBorderColor: Colors.amber.shade200,
                                      leading: const Icon(Icons.edit_outlined, size: 16),
                                      child: const Text('Edit'),
                                    ),
                                  ),
                                if (onEdit != null && onDelete != null)
                                  const SizedBox(width: 8),
                                if (onDelete != null)
                                  Expanded(
                                    child: AppButton(
                                      onPressed: onDelete,
                                      variant: AppButtonVariant.destructive,
                                      size: AppButtonSize.small,
                                      expands: true,
                                      lightBackgroundColor: Colors.red.shade100,
                                      darkBackgroundColor: Colors.red.shade300,
                                      lightForegroundColor: Colors.red.shade800,
                                      darkForegroundColor: Colors.red.shade900,
                                      leading: const Icon(Icons.delete_outline, size: 16),
                                      child: const Text('Delete'),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
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
                  fontSize: 10,
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
      children: [
        Icon(icon, size: iconSize, color: iconColor),
        const SizedBox(width: 3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: labelStyle),
              Text(value, style: valueStyle),
            ],
          ),
        ),
      ],
    );
  }
}
