import 'package:flutter/material.dart';
import 'package:project_bihon/shared/widgets/app_button.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class SupplyTrackerEditCard extends StatefulWidget {
  final String initialName;
  final String initialDescription;
  final int initialStockCount;
  final DateTime initialExpirationDate;
  final void Function({
    required String itemName,
    required String description,
    required int stockCount,
    required DateTime expirationDate,
  }) onSave;
  final VoidCallback onCancel;

  const SupplyTrackerEditCard({
    super.key,
    required this.initialName,
    required this.initialDescription,
    required this.initialStockCount,
    required this.initialExpirationDate,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<SupplyTrackerEditCard> createState() => _SupplyTrackerEditCardState();
}

class _SupplyTrackerEditCardState extends State<SupplyTrackerEditCard> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _stockController;
  late DateTime _expirationDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController = TextEditingController(text: widget.initialDescription);
    _stockController = TextEditingController(text: widget.initialStockCount.toString());
    _expirationDate = widget.initialExpirationDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final parsedStock = int.parse(_stockController.text.trim());
    widget.onSave(
      itemName: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      stockCount: parsedStock,
      expirationDate: _expirationDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      title: const Text('Edit Supply Item'),
      description: const Text('Update item details and save your changes.'),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Item name is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stockController,
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
                  onPressed: _pickDate,
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
                    onPressed: widget.onCancel,
                    variant: AppButtonVariant.outline,
                    expands: true,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    onPressed: _submit,
                    variant: AppButtonVariant.primary,
                    expands: true,
                    child: const Text('Save Changes'),
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
