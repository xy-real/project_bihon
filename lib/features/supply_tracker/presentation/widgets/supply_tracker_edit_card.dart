import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:project_bihon/shared/widgets/app_button.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class SupplyTrackerEditCard extends StatefulWidget {
  final String title;
  final String descriptionText;
  final String saveButtonLabel;
  final String initialName;
  final String? initialCategory;
  final String? initialImageUrl;
  final int initialStockCount;
  final DateTime initialExpirationDate;
  final Future<void> Function({
    required String itemName,
    required String category,
    required String? imageUrl,
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
    this.initialImageUrl,
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
  String? _imageUrl;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _stockController = TextEditingController(text: widget.initialStockCount.toString());
    _expirationDate = widget.initialExpirationDate;
    _selectedCategory = widget.initialCategory;
    _imageUrl = widget.initialImageUrl;
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

  String _formatErrorMessage(Object error) {
    final message = error.toString().trim();
    return message.isEmpty ? 'Unknown error.' : message;
  }

  void _showToast({
    required String title,
    required String message,
    bool destructive = false,
  }) {
    final toaster = ShadToaster.maybeOf(context);
    if (toaster != null) {
      toaster.show(
        destructive
            ? ShadToast.destructive(
                title: Text(title),
                description: Text(message),
              )
            : ShadToast(
                title: Text(title),
                description: Text(message),
              ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.showSnackBar(SnackBar(content: Text('$title: $message')));
    }
  }

  bool _isNetworkImage(String path) {
    final parsed = Uri.tryParse(path);
    return parsed != null && (parsed.scheme == 'http' || parsed.scheme == 'https');
  }

  Future<String> _persistImage(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, 'supply_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final extension = p.extension(sourcePath).isNotEmpty ? p.extension(sourcePath) : '.jpg';
    final fileName = 'supply_${DateTime.now().millisecondsSinceEpoch}$extension';
    final destinationPath = p.join(imagesDir.path, fileName);
    final copied = await File(sourcePath).copy(destinationPath);
    return copied.path;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isSubmitting) {
      return;
    }

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );

      if (pickedFile == null) {
        return;
      }

      final persistedPath = await _persistImage(pickedFile.path);

      if (!mounted) {
        return;
      }

      setState(() {
        _imageUrl = persistedPath;
      });

      _showToast(
        title: 'Image added',
        message: source == ImageSource.camera
            ? 'Photo captured successfully.'
            : 'Photo selected from gallery.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showToast(
        title: 'Unable to add image',
        message: _formatErrorMessage(error),
        destructive: true,
      );
    }
  }

  Widget _buildImagePreview() {
    if (_imageUrl == null || _imageUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    final path = _imageUrl!;
    final isNetwork = _isNetworkImage(path);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: isNetwork
              ? Image.network(
                  path,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Text('Image preview unavailable'),
                  ),
                )
              : Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Text('Image preview unavailable'),
                  ),
                ),
        ),
      ),
    );
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
        imageUrl: _imageUrl,
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _imageUrl == null || _imageUrl!.isEmpty
                        ? 'Picture: None selected'
                        : 'Picture: Added',
                  ),
                ),
                AppButton(
                  onPressed: _isSubmitting ? null : () => _pickImage(ImageSource.camera),
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.small,
                  child: const Text('Camera'),
                ),
                const SizedBox(width: 8),
                AppButton(
                  onPressed: _isSubmitting ? null : () => _pickImage(ImageSource.gallery),
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.small,
                  child: const Text('Gallery'),
                ),
                if (_imageUrl != null && _imageUrl!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  AppButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            setState(() {
                              _imageUrl = null;
                            });
                          },
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.small,
                    child: const Text('Remove'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            _buildImagePreview(),
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
