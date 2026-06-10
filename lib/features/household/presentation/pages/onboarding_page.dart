import 'package:flutter/material.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/dashboard_design.dart';
import 'package:project_bihon/features/household/data/repositories/household_repository.dart';

/// First-install onboarding screen for household location/risk setup.
///
/// This screen does not request GPS permission and does not store coordinates.
/// It stores only the selected household risk classification used by alerts.
class HouseholdOnboardingPage extends StatefulWidget {
  final HouseholdRepository householdRepository;
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
  static const List<_LocationOption> _options = [
    _LocationOption(
      id: 'coastal',
      riskValue: 'coastal',
      title: 'Coastal Area',
      riskText: 'Risk: Typhoon, Storm Surge',
      icon: Icons.water_drop_outlined,
    ),
    _LocationOption(
      id: 'flood_prone',
      riskValue: 'flood_prone',
      title: 'Flood-Prone Area',
      riskText: 'Risk: Flash flood, landslide',
      icon: Icons.flood_outlined,
    ),
    _LocationOption(
      id: 'mountainous',
      riskValue: 'landslide_prone',
      title: 'Mountainous Area',
      riskText: 'Risk: Landslide, flooding',
      icon: Icons.landscape_outlined,
    ),
    _LocationOption(
      id: 'urban',
      riskValue: 'unknown',
      title: 'Urban Area',
      riskText: 'Risk: General emergency',
      icon: Icons.location_city_outlined,
    ),
    _LocationOption(
      id: 'unknown',
      riskValue: 'unknown',
      title: 'Unknown / Not sure',
      riskText: 'Select if you are unsure',
      icon: Icons.help_outline,
    ),
  ];

  String? _selectedOptionId;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentRiskClassification();
  }

  Future<void> _loadCurrentRiskClassification() async {
    try {
      final household = await widget.householdRepository.getOrCreateHousehold();
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedOptionId = switch (household.risk_classification) {
          'coastal' => 'coastal',
          'flood_prone' => 'flood_prone',
          'landslide_prone' => 'mountainous',
          _ => null,
        };
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  _LocationOption? _selectedOption() {
    for (final option in _options) {
      if (option.id == _selectedOptionId) {
        return option;
      }
    }
    return null;
  }

  Future<void> _completeWithRisk(String riskValue) async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.householdRepository.updateRiskClassification(riskValue);
      await widget.householdRepository.setOnboardingCompleted();
      if (mounted) {
        widget.onComplete();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to save setup. Please try again.'),
            behavior: SnackBarBehavior.floating,
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

  Future<void> _handleContinue() async {
    final selected = _selectedOption();
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a home location category to continue.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await _completeWithRisk(selected.riskValue);
  }

  Future<void> _handleSkip() async {
    await _completeWithRisk('unknown');
  }

  void _showUnavailable(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label is not available yet.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: DashboardDesign.surface(context),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 16),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: DashboardDesign.deepNavy,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Crisync',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 62),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where is your home located?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'Help us send you relevant emergency alerts and personalized recommendations.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DashboardDesign.mutedText(context),
                height: 1.45,
              ),
        ),
      ],
    );
  }

  Widget _buildOptionCard(_LocationOption option) {
    final selected = option.id == _selectedOptionId;
    final color = selected
        ? DashboardDesign.deepNavy
        : DashboardDesign.mutedText(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DashboardDesign.radius),
        onTap: _isSaving
            ? null
            : () {
                setState(() {
                  _selectedOptionId = option.id;
                });
              },
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? DashboardDesign.statusBackground(
                    context,
                    DashboardDesign.deepNavy,
                  )
                : DashboardDesign.surface(context),
            borderRadius: BorderRadius.circular(DashboardDesign.radius),
            border: Border.all(
              color:
                  selected ? DashboardDesign.deepNavy : DashboardDesign.outline(context),
              width: selected ? 1.7 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: DashboardDesign.deepNavy.withValues(alpha: 0.13),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : DashboardDesign.cardShadow(context),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.82)
                      : DashboardDesign.surfaceVariant(context),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(option.icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.riskText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DashboardDesign.mutedText(context),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: _isSaving ? null : _handleContinue,
          style: FilledButton.styleFrom(
            backgroundColor: DashboardDesign.deepNavy,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                DashboardDesign.deepNavy.withValues(alpha: 0.36),
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashboardDesign.radius),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
          child: Text(_isSaving ? 'Saving...' : 'Continue'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _isSaving ? null : _handleSkip,
          style: OutlinedButton.styleFrom(
            foregroundColor: DashboardDesign.deepNavy,
            minimumSize: const Size.fromHeight(54),
            side: const BorderSide(color: DashboardDesign.deepNavy),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashboardDesign.radius),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
          child: const Text('Skip'),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          '© 2024 Crisync Emergency Systems',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DashboardDesign.mutedText(context),
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 0,
          children: [
            TextButton(
              onPressed: () => _showUnavailable('Privacy Policy'),
              child: const Text('Privacy Policy'),
            ),
            TextButton(
              onPressed: () => _showUnavailable('Terms of Service'),
              child: const Text('Terms of Service'),
            ),
            TextButton(
              onPressed: () => _showUnavailable('Help Center'),
              child: const Text('Help Center'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardDesign.background(context),
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 26),
                              for (final option in _options) ...[
                                _buildOptionCard(option),
                                const SizedBox(height: 12),
                              ],
                              const SizedBox(height: 12),
                              _buildActions(),
                              const SizedBox(height: 28),
                              _buildFooter(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LocationOption {
  const _LocationOption({
    required this.id,
    required this.riskValue,
    required this.title,
    required this.riskText,
    required this.icon,
  });

  final String id;
  final String riskValue;
  final String title;
  final String riskText;
  final IconData icon;
}
