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

enum SupplySortOption {
  expirationSoonest,
  quantityLowToHigh,
  quantityHighToLow,
  nameAToZ,
  categoryAToZ,
}

class SupplyTrackerPage extends StatefulWidget {
  const SupplyTrackerPage({super.key});

  @override
  State<SupplyTrackerPage> createState() => _SupplyTrackerPageState();
}

class _SupplyTrackerPageState extends State<SupplyTrackerPage> {
  SupplyTrackerView _selectedView = SupplyTrackerView.table;
  String _selectedCategoryFilter = 'All';
  SupplySortOption _selectedSortOption = SupplySortOption.expirationSoonest;
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

  int _findItemIndexById(String itemId) {
    return _repository.getAllItems().indexWhere((item) => item.id == itemId);
  }

  Future<void> _handleAddItem() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: SafeArea(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SupplyTrackerEditCard(
                title: 'Add Supply Item',
                descriptionText: 'Create a new supply entry for your inventory.',
                saveButtonLabel: 'Add Item',
                initialName: '',
                initialCategory: null,
                initialStockCount: 0,
                initialExpirationDate: DateTime.now().add(const Duration(days: 30)),
                onCancel: () {
                  Navigator.of(sheetContext).pop();
                },
                onSave: ({
                  required String itemName,
                  required String category,
                  required int stockCount,
                  required DateTime expirationDate,
                }) async {
                  const uuid = Uuid();
                  final newItem = SupplyItem(
                    id: uuid.v4(),
                    name: itemName,
                    category: category,
                    quantity: stockCount,
                    expirationDate: expirationDate,
                  );

                  if (mounted) {
                    Navigator.of(sheetContext).pop();
                  }

                  try {
                    await _repository.addItem(newItem);
                    await _notificationService.scheduleSupplyExpirationReminder(newItem);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Item added successfully: ${newItem.name}')),
                      );
                    }
                  } catch (_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to add item. Please try again.'),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleEdit(SupplyItem item) {
    final index = _findItemIndexById(item.id);
    if (index == -1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item not found. Please refresh and try again.')),
        );
      }
      return;
    }

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
                initialCategory: item.category,
                initialStockCount: item.quantity,
                initialExpirationDate: item.expirationDate,
                onCancel: () {
                  Navigator.of(dialogContext).pop();
                },
                onSave: ({
                  required String itemName,
                  required String category,
                  required int stockCount,
                  required DateTime expirationDate,
                }) async {
                  final updatedItem = SupplyItem(
                    id: item.id,
                    name: itemName,
                    category: category,
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

  Future<void> _handleDelete(SupplyItem item) async {
    final index = _findItemIndexById(item.id);
    if (index == -1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item not found. Please refresh and try again.')),
        );
      }
      return;
    }

    await _repository.deleteItem(index);
    await _notificationService.cancelSupplyExpirationReminder(item.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted: ${item.name}')),
      );
    }
  }

  void _showItemDetailsDialog(BuildContext context, {required SupplyItem item}) {
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
                  _handleEdit(item);
                },
                onDelete: () {
                  Navigator.of(context).pop();
                  _handleDelete(item);
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
                    _showItemDetailsDialog(context, item: items[i]);
                  },
                  onEdit: () => _handleEdit(items[i]),
                  onDelete: () => _handleDelete(items[i]),
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
                        _showItemDetailsDialog(context, item: items[i]);
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
                        onPressed: () => _handleEdit(items[i]),
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
                        onPressed: () => _handleDelete(items[i]),
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

  Widget _buildCategoryFilterChips(List<SupplyItem> items) {
    final categories = items.map((item) => item.category).toSet().toList()..sort();
    final filters = ['All', ...categories];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final filter in filters)
          ChoiceChip(
            label: Text(filter),
            selected: _selectedCategoryFilter == filter,
            onSelected: (_) {
              setState(() {
                _selectedCategoryFilter = filter;
              });
            },
          ),
      ],
    );
  }

  String _sortLabel(SupplySortOption option) {
    switch (option) {
      case SupplySortOption.expirationSoonest:
        return 'Expiration (Soonest)';
      case SupplySortOption.quantityLowToHigh:
        return 'Quantity (Low to High)';
      case SupplySortOption.quantityHighToLow:
        return 'Quantity (High to Low)';
      case SupplySortOption.nameAToZ:
        return 'Name (A to Z)';
      case SupplySortOption.categoryAToZ:
        return 'Category (A to Z)';
    }
  }

  List<SupplyItem> _sortItems(List<SupplyItem> items) {
    final sorted = List<SupplyItem>.from(items);

    switch (_selectedSortOption) {
      case SupplySortOption.expirationSoonest:
        sorted.sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
      case SupplySortOption.quantityLowToHigh:
        sorted.sort((a, b) => a.quantity.compareTo(b.quantity));
      case SupplySortOption.quantityHighToLow:
        sorted.sort((a, b) => b.quantity.compareTo(a.quantity));
      case SupplySortOption.nameAToZ:
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case SupplySortOption.categoryAToZ:
        sorted.sort((a, b) => a.category.toLowerCase().compareTo(b.category.toLowerCase()));
    }

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<SupplyItem>>(
      valueListenable: _repository.getItemsListenable(),
      builder: (context, box, _) {
        final items = box.values.toList();
        final filteredItems = _selectedCategoryFilter == 'All'
            ? items
            : items.where((item) => item.category == _selectedCategoryFilter).toList();
        final sortedItems = _sortItems(filteredItems);

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
              const SizedBox(height: 12),
              AppButton(
                onPressed: _handleAddItem,
                variant: AppButtonVariant.primary,
                leading: const Icon(Icons.add_circle_outline, size: 16),
                child: const Text('Add Item'),
              ),
              const SizedBox(height: 12),
              _buildCategoryFilterChips(items),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Sort by:',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<SupplySortOption>(
                      value: _selectedSortOption,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: SupplySortOption.values
                          .map(
                            (option) => DropdownMenuItem<SupplySortOption>(
                              value: option,
                              child: Text(_sortLabel(option)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _selectedSortOption = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _selectedView == SupplyTrackerView.cards
                  ? _buildCardsView(sortedItems)
                  : _buildTableView(sortedItems),
            ],
          ),
        );
      },
    );
  }
}
