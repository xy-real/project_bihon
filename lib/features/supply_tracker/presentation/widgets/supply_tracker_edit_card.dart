import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/dashboard_design.dart';
import 'package:project_bihon/shared/widgets/app_toast.dart';

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

  static const List<String> _unitOptions = [
    'units',
    'L',
    'kg',
    'packs',
    'cans',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _stockController;
  late final TextEditingController _notesController;
  late DateTime _expirationDate;
  String? _selectedCategory;
  String _selectedUnit = _unitOptions.first;
  String? _imageUrl;
  bool _isSubmitting = false;

  bool get _isAddMode => widget.title.toLowerCase().contains('add');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _stockController = TextEditingController(
      text: widget.initialStockCount == 0
          ? ''
          : widget.initialStockCount.toString(),
    );
    _notesController = TextEditingController();
    _expirationDate = widget.initialExpirationDate;
    _selectedCategory = widget.initialCategory;
    _imageUrl = widget.initialImageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _notesController.dispose();
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
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  bool _isNetworkImage(String path) {
    final parsed = Uri.tryParse(path);
    return parsed != null &&
        (parsed.scheme == 'http' || parsed.scheme == 'https');
  }

  Future<String> _persistImage(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, 'supply_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final extension =
        p.extension(sourcePath).isNotEmpty ? p.extension(sourcePath) : '.jpg';
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

      AppToast.success(
        context,
        title: 'Image added',
        message: source == ImageSource.camera
            ? 'Photo captured successfully.'
            : 'Photo selected from gallery.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppToast.errorFromException(
        context,
        title: 'Unable to add image',
        error: error,
      );
    }
  }

  Future<void> _showImageOptions() async {
    if (_isSubmitting) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_imageUrl != null && _imageUrl!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Remove Photo'),
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _imageUrl = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoArea() {
    final hasImage = _imageUrl != null && _imageUrl!.isNotEmpty;
    final imagePath = _imageUrl ?? '';
    final image = hasImage
        ? (_isNetworkImage(imagePath)
            ? Image.network(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPhotoPlaceholder(),
              )
            : Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPhotoPlaceholder(),
              ))
        : _buildPhotoPlaceholder();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DashboardDesign.radius),
        onTap: _isSubmitting ? null : _showImageOptions,
        child: Ink(
          decoration: BoxDecoration(
            color: DashboardDesign.surfaceVariant(context),
            borderRadius: BorderRadius.circular(DashboardDesign.radius),
          ),
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: DashboardDesign.outline(context),
              radius: DashboardDesign.radius,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DashboardDesign.radius),
              child: AspectRatio(
                aspectRatio: 16 / 7,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    image,
                    if (hasImage)
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.58),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                color: Colors.white,
                                size: 15,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Change',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
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
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            color: DashboardDesign.mutedText(context),
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            'ADD ITEM PHOTO',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: DashboardDesign.mutedText(context),
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
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

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: DashboardDesign.surfaceVariant(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DashboardDesign.compactRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DashboardDesign.compactRadius),
        borderSide: BorderSide(color: DashboardDesign.outline(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DashboardDesign.compactRadius),
        borderSide: const BorderSide(
          color: DashboardDesign.deepNavy,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DashboardDesign.compactRadius),
        borderSide: const BorderSide(color: DashboardDesign.danger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: DashboardDesign.mutedText(context),
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(
        color: DashboardDesign.surface(context),
        border: Border(
          bottom: BorderSide(color: DashboardDesign.outline(context)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _isSubmitting ? null : widget.onCancel,
                ),
              ),
              Expanded(
                child: Text(
                  _isAddMode ? 'Add Supply' : 'Edit Supply',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              const SizedBox(width: 56),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPhotoArea(),
          const SizedBox(height: 22),
          _fieldLabel('ITEM NAME'),
          TextFormField(
            controller: _nameController,
            enabled: !_isSubmitting,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(hintText: 'e.g. Bottled Water'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Item name is required.';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          _fieldLabel('CATEGORY'),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            onChanged: _isSubmitting
                ? null
                : (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
            decoration: _inputDecoration(hintText: 'Select a category'),
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
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _fieldLabel('QUANTITY'),
                    TextFormField(
                      controller: _stockController,
                      enabled: !_isSubmitting,
                      decoration: _inputDecoration(hintText: '0'),
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
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _fieldLabel('UNIT'),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedUnit,
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _selectedUnit = value;
                              });
                            },
                      decoration: _inputDecoration(hintText: 'units'),
                      items: _unitOptions
                          .map(
                            (unit) => DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _fieldLabel('EXPIRATION DATE'),
          InkWell(
            borderRadius: BorderRadius.circular(DashboardDesign.compactRadius),
            onTap: _isSubmitting ? null : _pickDate,
            child: InputDecorator(
              decoration: _inputDecoration(
                hintText: 'dd/mm/yyyy',
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              child: Text(_formatDate(_expirationDate)),
            ),
          ),
          const SizedBox(height: 18),
          _fieldLabel('NOTES (OPTIONAL)'),
          TextFormField(
            controller: _notesController,
            enabled: !_isSubmitting,
            minLines: 4,
            maxLines: 6,
            decoration: _inputDecoration(
              hintText: 'Storage location or specific details...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: DashboardDesign.surface(context),
        border: Border(
          top: BorderSide(color: DashboardDesign.outline(context)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  _isSubmitting
                      ? 'Saving...'
                      : (_isAddMode ? 'Save Item' : 'Save Changes'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: DashboardDesign.deepNavy,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      DashboardDesign.deepNavy.withValues(alpha: 0.34),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DashboardDesign.radius),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DashboardDesign.background(context),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.92,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 112),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: _buildFormFields(),
                  ),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect.deflate(0.75));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dashWidth = 7.0;
      const gapWidth = 5.0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
