import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:project_bihon/features/supply_tracker/data/models/supply_item.dart';
import 'package:project_bihon/features/supply_tracker/data/repositories/supply_repository.dart';
import 'package:project_bihon/features/supply_tracker/presentation/widgets/widgets.dart';
import 'package:project_bihon/shared/widgets/app_button.dart';
import 'package:project_bihon/shared/services/local_notification_service.dart';
import 'package:project_bihon/main.dart' show getLocalNotificationService, getSupplyRepository;

enum SupplyTrackerView { cards, table }

class SupplyTrackerPage extends StatefulWidget {
  const SupplyTrackerPage({super.key});

  @override
  State<SupplyTrackerPage> createState() => _SupplyTrackerPageState();
}

class _SupplyTrackerPageState extends State<SupplyTrackerPage> {
  SupplyTrackerView _selectedView = SupplyTrackerView.table;
  late SupplyRepository _repository;
  late LocalNotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _repository = getSupplyRepository();
    _notificationService = getLocalNotificationService();
    _initializeSeedData();
  }

  /// Initialize seed data if the box is empty
  Future<void> _initializeSeedData() async {
    if (_repository.getAllItems().isEmpty) {
      const uuid = Uuid();
      final seedItems = [
        SupplyItem(
          id: uuid.v4(),
          name: 'Medical Masks (N95)',
          category: 'Medical',
          quantity: 150,
          expirationDate: DateTime(2026, 6, 15),
        ),
        SupplyItem(
          id: uuid.v4(),
          name: 'Surgical Gloves',
          category: 'Medical',
          quantity: 500,
          expirationDate: DateTime(2025, 12, 31),
        ),
        SupplyItem(
          id: uuid.v4(),
          name: 'Antiseptic Solution',
          category: 'Medical',
          quantity: 45,
          expirationDate: DateTime(2026, 2, 28),
        ),
        SupplyItem(
          id: uuid.v4(),
          name: 'First Aid Kit',
          category: 'Medical',
          quantity: 12,
          expirationDate: DateTime(2026, 9, 10),
        ),
        SupplyItem(
          id: uuid.v4(),
          name: 'Bandages & Gauze',
          category: 'Medical',
          quantity: 200,
          expirationDate: DateTime(2027, 1, 5),
        ),
        SupplyItem(
          id: uuid.v4(),
          name: 'Thermometer (Digital)',
          category: 'Medical',
          quantity: 8,
          expirationDate: DateTime(2028, 5, 20),
        ),
      ];

      for (final item in seedItems) {
        await _repository.addItem(item);
        await _notificationService.scheduleSupplyExpirationReminder(item);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _handleEdit(SupplyItem item, int index) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SupplyTrackerEditCard(
                initialName: item.name,
                initialDescription: item.category,
                initialStockCount: item.quantity,
                initialExpirationDate: item.expirationDate,
                onCancel: () {
                  Navigator.of(dialogContext).pop();
                },
                onSave: ({
                  required String itemName,
                  required String description,
                  required int stockCount,
                  required DateTime expirationDate,
                }) async {
                  final updatedItem = SupplyItem(
                    id: item.id,
                    name: itemName,
                    category: description,
                    quantity: stockCount,
                    expirationDate: expirationDate,
                  );

                  await _repository.updateItem(index, updatedItem);
                    await _notificationService
                      .scheduleSupplyExpirationReminder(updatedItem);

                  if (mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Updated: ${updatedItem.name}')),
                    );
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleDelete(SupplyItem item, int index) async {
    await _repository.deleteItem(index);
    await _notificationService.cancelSupplyExpirationReminder(item.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted: ${item.name}')),
      );
    }
  }

  void _showItemDetailsDialog(BuildContext context, {required SupplyItem item, required int index}) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SupplyTrackerItemCard(
                itemName: item.name,
                description: item.category,
                stockCount: item.quantity,
                expirationDate: item.expirationDate,
                imageUrl: null,
                                supplyItem: item,
                onTap: () {
                  Navigator.of(context).pop();
                },
                onEdit: () {
                  Navigator.of(context).pop();
                  _handleEdit(item, index);
                },
                onDelete: () {
                  Navigator.of(context).pop();
                  _handleDelete(item, index);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardsView(List<SupplyItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1000 ? 3 : width >= 640 ? 2 : 1;
        final gap = 16.0;
        final cardWidth = (width - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (int i = 0; i < items.length; i++)
              SizedBox(
                width: cardWidth,
                child: SupplyTrackerItemCard(
                  itemName: items[i].name,
                  description: items[i].category,
                  stockCount: items[i].quantity,
                  expirationDate: items[i].expirationDate,
                                    supplyItem: items[i],
                  imageUrl: null,
                  onTap: () {
                    _showItemDetailsDialog(context, item: items[i], index: i);
                  },
                  onEdit: () => _handleEdit(items[i], i),
                  onDelete: () => _handleDelete(items[i], i),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTableView(List<SupplyItem> items) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 980),
        child: DataTable(
          columnSpacing: 20,
          headingRowHeight: 48,
          dataRowMinHeight: 56,
          dataRowMaxHeight: 72,
          columns: const [
            DataColumn(label: Text('Item Name')),
            DataColumn(label: Text('Category')),
            DataColumn(label: Text('Quantity'), numeric: true),
            DataColumn(label: Text('Expiration')),
            DataColumn(label: Text('View More Details')),
            DataColumn(label: Text('Edit')),
            DataColumn(label: Text('Delete')),
          ],
          rows: [
            for (int i = 0; i < items.length; i++)
              DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Text(
                        items[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 120,
                      child: Text(
                        items[i].category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text('${items[i].quantity}')),
                  DataCell(
                    Row(
                      children: [
                        Text(
                          _formatDate(items[i].expirationDate),
                          style: TextStyle(
                            color: items[i].isExpired
                                ? Colors.red.shade600
                                : items[i].expiresSoon
                                    ? Colors.orange.shade600
                                    : Colors.green.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: items[i].isExpired
                                ? Colors.red.shade100
                                : items[i].expiresSoon
                                    ? Colors.orange.shade100
                                    : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            items[i].isExpired
                                ? 'Expired'
                                : items[i].expiresSoon
                                    ? 'Expiring Soon'
                                    : 'Good',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: items[i].isExpired
                                  ? Colors.red.shade700
                                  : items[i].expiresSoon
                                      ? Colors.orange.shade700
                                      : Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    AppButton(
                      onPressed: () {
                        _showItemDetailsDialog(context, item: items[i], index: i);
                      },
                      variant: AppButtonVariant.ghost,
                      size: AppButtonSize.small,
                      child: const Text('View details'),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 84,
                      child: AppButton(
                        onPressed: () => _handleEdit(items[i], i),
                        variant: AppButtonVariant.outline,
                        size: AppButtonSize.small,
                        expands: true,
                        lightBackgroundColor: Colors.amber.shade100,
                        darkBackgroundColor: Colors.amber.shade200,
                        lightForegroundColor: Colors.amber.shade900,
                        darkForegroundColor: Colors.amber.shade900,
                        lightBorderColor: Colors.amber.shade300,
                        darkBorderColor: Colors.amber.shade200,
                        leading: const Icon(Icons.edit_outlined, size: 14),
                        child: const Text('Edit'),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 92,
                      child: AppButton(
                        onPressed: () => _handleDelete(items[i], i),
                        variant: AppButtonVariant.destructive,
                        size: AppButtonSize.small,
                        expands: true,
                        lightBackgroundColor: Colors.red.shade100,
                        darkBackgroundColor: Colors.red.shade300,
                        lightForegroundColor: Colors.red.shade800,
                        darkForegroundColor: Colors.red.shade900,
                        leading: const Icon(Icons.delete_outline, size: 14),
                        child: const Text('Delete'),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<SupplyItem>>(
      valueListenable: _repository.getItemsListenable(),
      builder: (context, box, _) {
        final items = box.values.toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Supply Tracker',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              SegmentedButton<SupplyTrackerView>(
                segments: const [
                  ButtonSegment<SupplyTrackerView>(
                    value: SupplyTrackerView.cards,
                    label: Text('Card View'),
                    icon: Icon(Icons.grid_view_rounded),
                  ),
                  ButtonSegment<SupplyTrackerView>(
                    value: SupplyTrackerView.table,
                    label: Text('Table View'),
                    icon: Icon(Icons.table_rows_rounded),
                  ),
                ],
                selected: <SupplyTrackerView>{_selectedView},
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedView = selection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              _selectedView == SupplyTrackerView.cards
                  ? _buildCardsView(items)
                  : _buildTableView(items),
            ],
          ),
        );
      },
    );
  }
}
