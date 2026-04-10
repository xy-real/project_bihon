import 'package:flutter/material.dart';
import 'package:project_bihon/features/household/data/repositories/household_repository.dart';
import 'package:project_bihon/features/household/presentation/widgets/risk_classification_picker.dart';
import 'package:project_bihon/features/household/presentation/widgets/risk_classification_picker.dart'
    as rcp;

/// Profile settings page for household configuration.
///
/// Allows users to view and edit their household profile, including
/// the home location type (risk classification).
///
/// Changes are saved immediately to Hive.
class ProfileSettingsPage extends StatefulWidget {
  /// The household repository for reading/writing data.
  final HouseholdRepository householdRepository;

  const ProfileSettingsPage({
    super.key,
    required this.householdRepository,
  });

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  late Future<void> _loadingFuture;
  String _currentRiskClassification = 'unknown';
  bool _showPicker = false;

  @override
  void initState() {
    super.initState();
    _loadingFuture = _loadHouseholdData();
  }

  /// Load household data from Hive.
  Future<void> _loadHouseholdData() async {
    try {
      final household =
          await widget.householdRepository.getOrCreateHousehold();
      setState(() {
        _currentRiskClassification = household.risk_classification;
      });
    } catch (e) {
      // Handle error silently, default to 'unknown'
      setState(() {
        _currentRiskClassification = 'unknown';
      });
    }
  }

  /// Get the user-friendly label for the current risk classification.
  String _getLabelForClassification(String classification) {
    return rcp.riskClassificationOptions[classification]?['label'] ??
        'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
      ),
      body: FutureBuilder<void>(
        future: _loadingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
              // Household section header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Household',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              // Home location type row
              _buildSettingsRow(
                context: context,
                title: 'Home location type',
                subtitle: _currentRiskClassification != 'unknown'
                    ? _getLabelForClassification(_currentRiskClassification)
                    : 'Not set',
                onTap: () {
                  setState(() {
                    _showPicker = !_showPicker;
                  });
                },
                trailing: Icon(
                  _showPicker ? Icons.expand_less : Icons.expand_more,
                ),
              ),

              // Expandable picker
              if (_showPicker)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: RiskClassificationPicker(
                    householdRepository: widget.householdRepository,
                    initialValue: _currentRiskClassification,
                    onChanged: () async {
                      // Reload data after change
                      await _loadHouseholdData();
                      setState(() {
                        _showPicker = false;
                      });
                    },
                  ),
                ),

              const Divider(),
            ],
          );
        },
      ),
    );
  }

  /// Build a custom settings row with title, subtitle, and trailing widget.
  Widget _buildSettingsRow({
    required BuildContext context,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
