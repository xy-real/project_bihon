import 'package:flutter/material.dart';
import 'package:project_bihon/features/household/data/repositories/household_repository.dart';

/// Maps canonical risk classifications to user-friendly labels and descriptions.
const Map<String, Map<String, String>> riskClassificationOptions = {
  'coastal': {
    'label': 'Near the ocean',
    'description': 'Susceptible to storm surge and coastal flooding',
  },
  'flood_prone': {
    'label': 'Near river or low-lying area',
    'description': 'Prone to flooding during heavy rainfall',
  },
  'landslide_prone': {
    'label': 'Near steep slope or mountain',
    'description': 'Risk of landslides during heavy rainfall',
  },
};

/// A reusable widget for selecting and saving the household risk classification.
///
/// Displays a radio-group with user-friendly labels that map to canonical
/// risk classification values (coastal, flood_prone, landslide_prone).
///
/// On selection, automatically saves the canonical value to Hive via the
/// provided [householdRepository].
///
/// Shows a confirmation SnackBar after successful save.
class RiskClassificationPicker extends StatefulWidget {
  /// The household repository for saving the selection.
  final HouseholdRepository householdRepository;

  /// Optional callback when the risk classification is changed.
  final VoidCallback? onChanged;

  /// Whether to show descriptions under each option.
  final bool showDescriptions;

  /// Initial selected value (canonical form: 'coastal', 'flood_prone', etc).
  /// If null, no initial selection is shown.
  final String? initialValue;

  const RiskClassificationPicker({
    super.key,
    required this.householdRepository,
    this.onChanged,
    this.showDescriptions = true,
    this.initialValue,
  });

  @override
  State<RiskClassificationPicker> createState() =>
      _RiskClassificationPickerState();
}

class _RiskClassificationPickerState extends State<RiskClassificationPicker> {
  late String? _selectedValue;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  /// Handle radio selection and save to Hive.
  Future<void> _handleSelection(String canonicalValue) async {
    setState(() {
      _selectedValue = canonicalValue;
      _isSaving = true;
    });

    try {
      await widget.householdRepository.updateRiskClassification(canonicalValue);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Home location updated to "${riskClassificationOptions[canonicalValue]?['label']}"',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );

        widget.onChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save home location. Please try again.'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...riskClassificationOptions.entries.map((entry) {
          final canonicalValue = entry.key;
          final label = entry.value['label']!;
          final description = entry.value['description']!;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isSaving
                    ? null
                    : () => _handleSelection(canonicalValue),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // ignore: deprecated_member_use
                      Radio<String?>(
                        value: canonicalValue,
                        groupValue: _selectedValue,
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                if (value != null) {
                                  _handleSelection(value);
                                }
                              },
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            if (widget.showDescriptions)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  description,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
