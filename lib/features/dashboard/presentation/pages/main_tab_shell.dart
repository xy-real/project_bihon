import 'package:flutter/material.dart';
import 'package:project_bihon/features/alerts/data/repositories/alerts_repository.dart';
import 'package:project_bihon/features/alerts/presentation/pages/alerts_list_page.dart';
import 'package:project_bihon/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/crisync_bottom_navigation.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/dashboard_design.dart';
import 'package:project_bihon/features/emergency_contacts/data/repositories/contact_repository.dart';
import 'package:project_bihon/features/emergency_contacts/presentation/pages/contacts_page.dart';
import 'package:project_bihon/features/evacuation_centers/data/repositories/evacuation_center_repository.dart';
import 'package:project_bihon/features/evacuation_centers/presentation/pages/evacuation_center_page.dart';
import 'package:project_bihon/features/household/data/repositories/household_repository.dart';
import 'package:project_bihon/features/preparedness_instruction/repositories/instruction_guide_repository.dart';
import 'package:project_bihon/features/supply_tracker/data/repositories/supply_repository.dart';
import 'package:project_bihon/features/supply_tracker/presentation/pages/supply_tracker_page.dart';
import 'package:project_bihon/shared/shared.dart';

class MainTabShell extends StatefulWidget {
  const MainTabShell({
    super.key,
    this.initialIndex = 0,
    required this.themeMode,
    required this.onThemeChanged,
    required this.supplyRepository,
    required this.alertsRepository,
    required this.contactRepository,
    required this.householdRepository,
    required this.evacuationCenterRepository,
    required this.instructionGuideRepository,
  });

  final int initialIndex;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final SupplyRepository supplyRepository;
  final AlertsRepository alertsRepository;
  final ContactRepository contactRepository;
  final HouseholdRepository householdRepository;
  final EvacuationCenterRepository evacuationCenterRepository;
  final InstructionGuideRepository instructionGuideRepository;

  @override
  State<MainTabShell> createState() => _MainTabShellState();
}

class _MainTabShellState extends State<MainTabShell> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _isInteractingWithMap = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToTab(int index) async {
    final targetIndex = index.clamp(0, 4);
    if (targetIndex == _currentIndex) {
      return;
    }

    setState(() {
      _currentIndex = targetIndex;
      _isInteractingWithMap = false;
    });

    await _pageController.animateToPage(
      targetIndex,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _handlePageChanged(int index) {
    setState(() {
      _currentIndex = index;
      if (index != 2) {
        _isInteractingWithMap = false;
      }
    });
  }

  void _handleMapInteractionChanged(bool isInteracting) {
    if (_isInteractingWithMap == isInteracting) {
      return;
    }

    setState(() {
      _isInteractingWithMap = isInteracting;
    });
  }

  Widget _buildLogoAvatar() {
    return CircleAvatar(
      radius: 18,
      backgroundColor: DashboardDesign.deepNavy,
      child: ClipOval(
        child: Image.asset(
          'assets/logo.png',
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 20,
            );
          },
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        backgroundColor: DashboardDesign.surface(context),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLogoAvatar(),
            const SizedBox(width: 10),
            const Text(
              'Crisync',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: AppThemeSwitcher(
                themeMode: widget.themeMode,
                onChanged: widget.onThemeChanged,
                showLabel: false,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Profile Settings',
            onPressed: () {
              Navigator.of(context).pushNamed('/profile-settings');
            },
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: DashboardPage(
        supplyRepository: widget.supplyRepository,
        alertsRepository: widget.alertsRepository,
        contactRepository: widget.contactRepository,
        householdRepository: widget.householdRepository,
        evacuationCenterRepository: widget.evacuationCenterRepository,
        instructionGuideRepository: widget.instructionGuideRepository,
        onOpenMainTab: _goToTab,
      ),
    );
  }

  List<Widget> _buildTabs() {
    return [
      _KeepAliveTab(child: _buildHomeTab()),
      _KeepAliveTab(
        child: AlertsListPage(
          showBottomNavigation: false,
          onTabSelected: _goToTab,
        ),
      ),
      _KeepAliveTab(
        child: EvacuationCenterPage(
          repository: widget.evacuationCenterRepository,
          showBottomNavigation: false,
          onTabSelected: _goToTab,
          onMapInteractionChanged: _handleMapInteractionChanged,
        ),
      ),
      _KeepAliveTab(
        child: SupplyTrackerPage(
          showBottomNavigation: false,
          onTabSelected: _goToTab,
        ),
      ),
      _KeepAliveTab(
        child: ContactsPage(
          showBottomNavigation: false,
          onTabSelected: _goToTab,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          _goToTab(0);
        }
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          physics: _isInteractingWithMap
              ? const NeverScrollableScrollPhysics()
              : const PageScrollPhysics(),
          onPageChanged: _handlePageChanged,
          children: _buildTabs(),
        ),
        bottomNavigationBar: CrisyncBottomNavigation(
          selectedIndex: _currentIndex,
          onDestinationSelected: _goToTab,
        ),
      ),
    );
  }
}

class _KeepAliveTab extends StatefulWidget {
  const _KeepAliveTab({required this.child});

  final Widget child;

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
