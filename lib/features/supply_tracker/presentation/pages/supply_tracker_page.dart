import 'package:flutter/material.dart';
import 'package:project_bihon/features/supply_tracker/presentation/widgets/widgets.dart';
import 'package:project_bihon/shared/widgets/app_button.dart';

enum SupplyTrackerView { cards, table }

class SupplyTrackerPage extends StatefulWidget {
  const SupplyTrackerPage({super.key});

  @override
  State<SupplyTrackerPage> createState() => _SupplyTrackerPageState();
}

class _SupplyTrackerPageState extends State<SupplyTrackerPage> {
  SupplyTrackerView _selectedView = SupplyTrackerView.table;

  final List<Map<String, dynamic>> _mockItems = [
    {
      'itemName': 'Medical Masks (N95)',
      'description': 'High-efficiency respirator masks for medical use',
      'stockCount': 150,
      'expirationDate': DateTime(2026, 6, 15),
      'imageUrl': null,
    },
    {
      'itemName': 'Surgical Gloves',
      'description': 'Latex-free, sterile surgical gloves',
      'stockCount': 500,
      'expirationDate': DateTime(2025, 12, 31),
      'imageUrl': null,
    },
    {
      'itemName': 'Antiseptic Solution',
      'description': '70% Isopropyl alcohol antiseptic',
      'stockCount': 45,
      'expirationDate': DateTime(2026, 2, 28),
      'imageUrl': null,
    },
    {
      'itemName': 'First Aid Kit',
      'description': 'Comprehensive emergency first aid supplies',
      'stockCount': 12,
      'expirationDate': DateTime(2026, 9, 10),
      'imageUrl': null,
    },
    {
      'itemName': 'Bandages & Gauze',
      'description': 'Sterile medical bandages and gauze pads',
      'stockCount': 200,
      'expirationDate': DateTime(2027, 1, 5),
      'imageUrl': null,
    },
    {
      'itemName': 'Thermometer (Digital)',
      'description': 'Non-contact infrared digital thermometer',
      'stockCount': 8,
      'expirationDate': DateTime(2028, 5, 20),
      'imageUrl': null,
    },
  ];

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _handleEdit(Map<String, dynamic> item) {
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
                initialName: item['itemName'] as String,
                initialDescription: item['description'] as String,
                initialStockCount: item['stockCount'] as int,
                initialExpirationDate: item['expirationDate'] as DateTime,
                onCancel: () {
                  Navigator.of(dialogContext).pop();
                },
                onSave: ({
                  required String itemName,
                  required String description,
                  required int stockCount,
                  required DateTime expirationDate,
                }) {
                  setState(() {
                    item['itemName'] = itemName;
                    item['description'] = description;
                    item['stockCount'] = stockCount;
                    item['expirationDate'] = expirationDate;
                  });

                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Updated: ${item['itemName']}')),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleDelete(Map<String, dynamic> item) {
    setState(() {
      _mockItems.remove(item);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted: ${item['itemName']}')),
    );
  }

  void _showItemDetailsDialog(BuildContext context, {required Map<String, dynamic> item}) {
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
                itemName: item['itemName'] as String,
                description: item['description'] as String,
                stockCount: item['stockCount'] as int,
                expirationDate: item['expirationDate'] as DateTime,
                imageUrl: item['imageUrl'] as String?,
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

  Widget _buildCardsView() {
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
            for (final item in _mockItems)
              SizedBox(
                width: cardWidth,
                child: SupplyTrackerItemCard(
                  itemName: item['itemName'] as String,
                  description: item['description'] as String,
                  stockCount: item['stockCount'] as int,
                  expirationDate: item['expirationDate'] as DateTime,
                  imageUrl: item['imageUrl'] as String?,
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

  Widget _buildTableView() {
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
            DataColumn(label: Text('Description')),
            DataColumn(label: Text('Stock Count'), numeric: true),
            DataColumn(label: Text('Expiration')),
            DataColumn(label: Text('View More Details')),
            DataColumn(label: Text('Edit')),
            DataColumn(label: Text('Delete')),
          ],
          rows: [
            for (final item in _mockItems)
              DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Text(
                        item['itemName'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 260,
                      child: Text(
                        item['description'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text('${item['stockCount']}')),
                  DataCell(Text(_formatDate(item['expirationDate'] as DateTime))),
                  DataCell(
                    TextButton(
                      onPressed: () {
                        _showItemDetailsDialog(context, item: item);
                      },
                      child: const Text('View details'),
                    ),
                  ),
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
          _selectedView == SupplyTrackerView.cards ? _buildCardsView() : _buildTableView(),
        ],
      ),
    );
  }
}
