import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;
import 'package:uuid/uuid.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/crisync_bottom_navigation.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/crisync_main_app_bar.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/dashboard_design.dart';
import 'package:project_bihon/features/supply_tracker/data/models/supply_item.dart';
import 'package:project_bihon/features/supply_tracker/data/repositories/supply_repository.dart';
import 'package:project_bihon/features/supply_tracker/presentation/widgets/widgets.dart';
import 'package:project_bihon/main.dart'
    show getLocalNotificationService, getSupplyRepository;
import 'package:project_bihon/shared/services/local_notification_service.dart';
import 'package:project_bihon/shared/widgets/app_button.dart';
import 'package:project_bihon/shared/widgets/app_toast.dart';

enum SupplyTrackerView { cards, table }

enum SupplySortOption {
  expirationSoonest,
  quantityLowToHigh,
  quantityHighToLow,
  nameAToZ,
  categoryAToZ,
}

class SupplyTrackerPage extends StatefulWidget {
  const SupplyTrackerPage({
    super.key,
    this.showBottomNavigation = true,
    this.onTabSelected,
  });

  final bool showBottomNavigation;
  final ValueChanged<int>? onTabSelected;

  @override
  State<SupplyTrackerPage> createState() => _SupplyTrackerPageState();
}

class _SupplyTrackerPageState extends State<SupplyTrackerPage> {
  static const String _allCategoriesFilter = 'All Categories';

  SupplyTrackerView _selectedView = SupplyTrackerView.cards;
  String _selectedCategoryFilter = _allCategoriesFilter;
  SupplySortOption _selectedSortOption = SupplySortOption.expirationSoonest;
  late SupplyRepository _repository;
  late LocalNotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _repository = getSupplyRepository();
    _notificationService = getLocalNotificationService();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SupplyTrackerEditCard(
                  title: 'Add Supply Item',
                  descriptionText:
                      'Create a new supply entry for your inventory.',
                  saveButtonLabel: 'Add Item',
                  initialName: '',
                  initialCategory: null,
                  initialImageUrl: null,
                  initialStockCount: 0,
                  initialExpirationDate:
                      DateTime.now().add(const Duration(days: 30)),
                  onCancel: () {
                    Navigator.of(sheetContext).pop();
                  },
                  onSave: ({
                    required String itemName,
                    required String category,
                    required String? imageUrl,
                    required int stockCount,
                    required DateTime expirationDate,
                  }) async {
                    const uuid = Uuid();
                    final newItem = SupplyItem(
                      id: uuid.v4(),
                      name: itemName,
                      category: category,
                      imageUrl: imageUrl,
                      quantity: stockCount,
                      expirationDate: expirationDate,
                    );

                    if (mounted) {
                      Navigator.of(sheetContext).pop();
                    }

                    try {
                      await _repository.addItem(newItem);
                      await _notificationService
                          .scheduleSupplyExpirationReminder(newItem);

                      if (mounted) {
                        AppToast.success(
                          context,
                          title: 'Item added',
                          message: newItem.name,
                        );
                      }
                    } catch (error) {
                      if (mounted) {
                        AppToast.errorFromException(
                          context,
                          title: 'Failed to add item',
                          error: error,
                        );
                      }
                    }
                  },
                ),
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
        AppToast.error(
          context,
          title: 'Item not found',
          message: 'Please refresh and try again.',
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
                initialImageUrl: item.imageUrl,
                initialStockCount: item.quantity,
                initialExpirationDate: item.expirationDate,
                onCancel: () {
                  Navigator.of(dialogContext).pop();
                },
                onSave: ({
                  required String itemName,
                  required String category,
                  required String? imageUrl,
                  required int stockCount,
                  required DateTime expirationDate,
                }) async {
                  final updatedItem = SupplyItem(
                    id: item.id,
                    name: itemName,
                    category: category,
                    imageUrl: imageUrl,
                    quantity: stockCount,
                    expirationDate: expirationDate,
                  );

                  try {
                    await _repository.updateItem(index, updatedItem);
                    await _notificationService
                        .scheduleSupplyExpirationReminder(updatedItem);

                    if (mounted && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                      AppToast.success(
                        context,
                        title: 'Item updated',
                        message: updatedItem.name,
                      );
                    }
                  } catch (error) {
                    if (mounted) {
                      AppToast.errorFromException(
                        context,
                        title: 'Failed to update item',
                        error: error,
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

  Future<void> _handleDelete(SupplyItem item) async {
    final index = _findItemIndexById(item.id);
    if (index == -1) {
      if (mounted) {
        AppToast.error(
          context,
          title: 'Item not found',
          message: 'Please refresh and try again.',
        );
      }
      return;
    }

    try {
      await _repository.deleteItem(index);
      await _notificationService.cancelSupplyExpirationReminder(item.id);
      if (mounted) {
        AppToast.success(
          context,
          title: 'Item deleted',
          message: item.name,
        );
      }
    } catch (error) {
      if (mounted) {
        AppToast.errorFromException(
          context,
          title: 'Failed to delete item',
          error: error,
        );
      }
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
                imageUrl: item.imageUrl,
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

  void _openTab(int index) {
    final onTabSelected = widget.onTabSelected;
    if (onTabSelected != null) {
      onTabSelected(index);
      return;
    }

    final navigator = Navigator.of(context);
    final routeName = switch (index) {
      0 => '/home',
      1 => '/alerts',
      2 => '/evacuation-centers',
      3 => null,
      4 => '/contacts',
      _ => null,
    };

    if (routeName == null) {
      return;
    }

    if (index == 0) {
      navigator.pushNamedAndRemoveUntil(routeName, (route) => false);
    } else {
      navigator.pushReplacementNamed(routeName);
    }
  }

  Widget _buildCardsView(List<SupplyItem> items) {
    if (items.isEmpty) {
      return _EmptySupplyState(onAddItem: _handleAddItem);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 760 ? 2 : 1;
        const gap = DashboardDesign.gap;
        final cardWidth = (width - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: cardWidth,
                child: SupplyTrackerItemCard(
                  itemName: item.name,
                  description: item.category,
                  stockCount: item.quantity,
                  expirationDate: item.expirationDate,
                  supplyItem: item,
                  imageUrl: item.imageUrl,
                  onTap: () {
                    _showItemDetailsDialog(context, item: item);
                  },
                  onEdit: () => _handleEdit(item),
                  onDelete: () => _handleDelete(item),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTableView(List<SupplyItem> items) {
    if (items.isEmpty) {
      return _EmptySupplyState(onAddItem: _handleAddItem);
    }

    return Container(
      decoration: BoxDecoration(
        color: DashboardDesign.surface(context),
        borderRadius: BorderRadius.circular(DashboardDesign.radius),
        border: Border.all(color: DashboardDesign.outline(context)),
        boxShadow: DashboardDesign.cardShadow(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 900),
          child: DataTable(
            columnSpacing: 18,
            headingRowHeight: 48,
            dataRowMinHeight: 64,
            dataRowMaxHeight: 72,
            columns: const [
              DataColumn(label: Text('Item Name')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Quantity'), numeric: true),
              DataColumn(label: Text('Expiration')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Edit')),
              DataColumn(label: Text('Delete')),
            ],
            rows: [
              for (final item in items)
                DataRow(
                  onSelectChanged: (_) {
                    _showItemDetailsDialog(context, item: item);
                  },
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 180,
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: Text(
                          item.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text('${item.quantity}')),
                    DataCell(
                      Text(
                        _formatDate(item.expirationDate),
                        style: TextStyle(
                          color: _statusColorFor(item),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    DataCell(_TableStatusBadge(item: item)),
                    DataCell(
                      SizedBox(
                        width: 84,
                        child: AppButton(
                          onPressed: () => _handleEdit(item),
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
                          onPressed: () => _handleDelete(item),
                          variant: AppButtonVariant.destructive,
                          size: AppButtonSize.small,
                          expands: true,
                          lightBackgroundColor: Colors.red.shade100,
                          darkBackgroundColor: Colors.red.shade300,
                          lightForegroundColor: Colors.red.shade800,
                          darkForegroundColor: Colors.red.shade900,
                          leading:
                              const Icon(Icons.delete_outline, size: 14),
                          child: const Text('Delete'),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _categoryOptions(List<SupplyItem> items) {
    final categories = items
        .map((item) => item.category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return [_allCategoriesFilter, ...categories];
  }

  String _sortLabel(SupplySortOption option) {
    switch (option) {
      case SupplySortOption.expirationSoonest:
        return 'Expiring Soon';
      case SupplySortOption.quantityLowToHigh:
        return 'Quantity low to high';
      case SupplySortOption.quantityHighToLow:
        return 'Quantity high to low';
      case SupplySortOption.nameAToZ:
        return 'Name A to Z';
      case SupplySortOption.categoryAToZ:
        return 'Category';
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
        sorted.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case SupplySortOption.categoryAToZ:
        sorted.sort(
          (a, b) =>
              a.category.toLowerCase().compareTo(b.category.toLowerCase()),
        );
    }

    return sorted;
  }

  Color _statusColorFor(SupplyItem item) {
    if (item.isExpired) {
      return DashboardDesign.danger;
    }
    if (item.expiresSoon) {
      return DashboardDesign.warning;
    }
    return DashboardDesign.success;
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Supply Tracker',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ),
        const SizedBox(width: 12),
        SegmentedButton<SupplyTrackerView>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            selectedBackgroundColor: DashboardDesign.deepNavy,
            selectedForegroundColor: Colors.white,
            foregroundColor: DashboardDesign.mutedText(context),
            side: BorderSide(color: DashboardDesign.outline(context)),
          ),
          segments: const [
            ButtonSegment<SupplyTrackerView>(
              value: SupplyTrackerView.table,
              label: Text('Table'),
            ),
            ButtonSegment<SupplyTrackerView>(
              value: SupplyTrackerView.cards,
              label: Text('Card'),
            ),
          ],
          selected: <SupplyTrackerView>{_selectedView},
          onSelectionChanged: (selection) {
            setState(() {
              _selectedView = selection.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildFilters(List<SupplyItem> items) {
    final categories = _categoryOptions(items);
    final selectedCategory = categories.contains(_selectedCategoryFilter)
        ? _selectedCategoryFilter
        : _allCategoriesFilter;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 640;
        final categoryFilter = _FilterDropdown<String>(
          label: 'Category',
          value: selectedCategory,
          items: categories
              .map(
                (category) => DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _selectedCategoryFilter = value;
            });
          },
        );
        final sortFilter = _FilterDropdown<SupplySortOption>(
          label: 'Sort',
          value: _selectedSortOption,
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
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: categoryFilter),
              const SizedBox(width: DashboardDesign.gap),
              Expanded(child: sortFilter),
            ],
          );
        }

        return Column(
          children: [
            categoryFilter,
            const SizedBox(height: 12),
            sortFilter,
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardDesign.background(context),
      appBar: const CrisyncMainAppBar(),
      bottomNavigationBar: widget.showBottomNavigation
          ? CrisyncBottomNavigation(
              selectedIndex: 3,
              onDestinationSelected: _openTab,
            )
          : null,
      floatingActionButton: FloatingActionButton(
        heroTag: 'supply-tracker-add',
        onPressed: _handleAddItem,
        backgroundColor: DashboardDesign.deepNavy,
        foregroundColor: Colors.white,
        tooltip: 'Add supply item',
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder<Box<SupplyItem>>(
        valueListenable: _repository.getItemsListenable(),
        builder: (context, box, _) {
          final items = box.values.toList();
          final categories = _categoryOptions(items);
          final selectedCategory = categories.contains(_selectedCategoryFilter)
              ? _selectedCategoryFilter
              : _allCategoriesFilter;
          final filteredItems = selectedCategory == _allCategoriesFilter
              ? items
              : items
                  .where((item) => item.category == selectedCategory)
                  .toList();
          final sortedItems = _sortItems(filteredItems);
          final horizontalPadding = MediaQuery.sizeOf(context).width >= 600
              ? DashboardDesign.marginTablet
              : DashboardDesign.marginMobile;

          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                DashboardDesign.gap,
                horizontalPadding,
                widget.showBottomNavigation ? 96 : 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: DashboardDesign.gap),
                      _buildFilters(items),
                      const SizedBox(height: DashboardDesign.sectionGap),
                      _selectedView == SupplyTrackerView.cards
                          ? _buildCardsView(sortedItems)
                          : _buildTableView(sortedItems),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      key: ValueKey<Object?>(value),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: DashboardDesign.surface(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DashboardDesign.compactRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DashboardDesign.compactRadius),
          borderSide: BorderSide(color: DashboardDesign.outline(context)),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

class _TableStatusBadge extends StatelessWidget {
  const _TableStatusBadge({required this.item});

  final SupplyItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.isExpired
        ? DashboardDesign.danger
        : item.expiresSoon
            ? DashboardDesign.warning
            : DashboardDesign.success;
    final text = item.isExpired
        ? 'EXPIRED'
        : item.expiresSoon
            ? 'SOON'
            : 'OK';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: DashboardDesign.statusBackground(context, color),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _EmptySupplyState extends StatelessWidget {
  const _EmptySupplyState({required this.onAddItem});

  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DashboardDesign.surface(context),
        borderRadius: BorderRadius.circular(DashboardDesign.radius),
        border: Border.all(color: DashboardDesign.outline(context)),
        boxShadow: DashboardDesign.cardShadow(context),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DashboardDesign.statusBackground(
                context,
                DashboardDesign.deepNavy,
              ),
            ),
            child: const Icon(
              lucide.LucideIcons.packagePlus,
              color: DashboardDesign.deepNavy,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No supplies yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first emergency supply item to start tracking readiness.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DashboardDesign.mutedText(context),
                ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onAddItem,
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
            style: FilledButton.styleFrom(
              backgroundColor: DashboardDesign.deepNavy,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DashboardDesign.radius),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
