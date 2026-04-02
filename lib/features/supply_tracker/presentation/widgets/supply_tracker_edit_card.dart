import 'package:flutter/material.dart';
import 'package:project_bihon/shared/widgets/app_button.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class SupplyTrackerEditCard extends StatefulWidget {
  final String title;
  final String descriptionText;
  final String saveButtonLabel;
  final String initialName;
  final String? initialCategory;
  final int initialStockCount;
  final DateTime initialExpirationDate;
  final Future<void> Function({
    required String itemName,
    required String category,
    required int stockCount,
    required DateTime expirationDate,
  }) onSave;
  final VoidCallback onCancel;

  const SupplyTrackerEditCard({
    super.key,
    this.title = 'Edit Supply Item',
    this.descriptionText = 'Update item details and save your changes.',
    this.saveButtonLabel = 'Save Changes',
    required this.initialName,
    this.initialCategory,
    required this.initialStockCount,
    required this.initialExpirationDate,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<SupplyTrackerEditCard> createState() => _SupplyTrackerEditCardState();
}

class _SupplyTrackerEditCardState extends State<SupplyTrackerEditCard> {
  static const List<String> _categoryOptions = [
    'Food',
    'Water',
    'Medical',
    'Tools',
    'Hygiene',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _stockController;
  late DateTime _expirationDate;
  String? _selectedCategory;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _stockController = TextEditingController(text: widget.initialStockCount.toString());
    _expirationDate = widget.initialExpirationDate;
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _expirationDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _expirationDate = pickedDate;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final parsedStock = int.parse(_stockController.text.trim());
    try {
      await widget.onSave(
        itemName: _nameController.text.trim(),
        category: _selectedCategory!,
        stockCount: parsedStock,
        expirationDate: _expirationDate,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      title: Text(widget.title),
      description: Text(widget.descriptionText),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(labelText: 'Item Name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Item name is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categoryOptions
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Category is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stockController,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(labelText: 'Amount / Stock Count'),
              keyboardType: TextInputType.number,
              validator: (value) {
                final parsed = int.tryParse((value ?? '').trim());
                if (parsed == null) {
                  return 'Enter a valid number.';
                }
                if (parsed < 0) {
                  return 'Amount cannot be negative.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text('Expiration Date: ${_formatDate(_expirationDate)}'),
                ),
                AppButton(
                  onPressed: _isSubmitting ? null : _pickDate,
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.small,
                  child: const Text('Pick Date'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    onPressed: _isSubmitting ? null : widget.onCancel,
                    variant: AppButtonVariant.outline,
                    expands: true,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    onPressed: _isSubmitting ? null : _submit,
                    variant: AppButtonVariant.primary,
                    expands: true,
                    child: Text(_isSubmitting ? 'Saving...' : widget.saveButtonLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
