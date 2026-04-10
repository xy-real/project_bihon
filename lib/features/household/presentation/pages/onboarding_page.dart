import 'package:flutter/material.dart';
import 'package:project_bihon/features/household/data/repositories/household_repository.dart';
import 'package:project_bihon/features/household/presentation/widgets/risk_classification_picker.dart';

/// Onboarding screen for household setup.
///
/// This screen guides the user through setting up their household profile,
/// including selection of home location type (risk classification).
///
/// Users can skip this step, and the app will default to 'unknown'.
class HouseholdOnboardingPage extends StatefulWidget {
  /// The household repository for saving data.
  final HouseholdRepository householdRepository;

  /// Callback when onboarding is completed or skipped.
  final VoidCallback onComplete;

  const HouseholdOnboardingPage({
    super.key,
    required this.householdRepository,
    required this.onComplete,
  });

  @override
  State<HouseholdOnboardingPage> createState() =>
      _HouseholdOnboardingPageState();
}

class _HouseholdOnboardingPageState extends State<HouseholdOnboardingPage> {
  String? _selectedRiskClassification;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentRiskClassification();
  }

  /// Load the current risk classification from Hive.
  Future<void> _loadCurrentRiskClassification() async {
    try {
      final household = await widget.householdRepository.getOrCreateHousehold();
      setState(() {
        if (household.risk_classification != 'unknown') {
          _selectedRiskClassification = household.risk_classification;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Handle skip action: defaults to 'unknown' and completes onboarding.
  Future<void> _handleSkip() async {
    await widget.householdRepository.updateRiskClassification('unknown');
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Your Home'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
                  Text(
                    'Where is your home located?',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This helps us prioritize alerts that are most relevant to your area.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 32),

                  // Risk classification picker
                  RiskClassificationPicker(
                    householdRepository: widget.householdRepository,
                    initialValue: _selectedRiskClassification,
                    onChanged: () {
                      setState(() {
                        _loadCurrentRiskClassification();
                      });
                    },
                  ),

                  const SizedBox(height: 32),

                  // Action buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _selectedRiskClassification != null
                              ? widget.onComplete
                              : null,
                      child: const Text('Continue'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _handleSkip,
                      child: const Text('Skip for now'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
