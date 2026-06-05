import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'features/alerts/data/models/cached_alert.dart';
import 'features/alerts/data/repositories/alerts_repository.dart';
import 'features/alerts/presentation/pages/alerts_list_page.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/dashboard/presentation/widgets/crisync_bottom_navigation.dart';
import 'features/dashboard/presentation/widgets/dashboard_design.dart';
import 'features/evacuation_centers/data/models/cached_evac_center.dart';
import 'features/evacuation_centers/data/repositories/evacuation_center_repository.dart';
import 'features/evacuation_centers/presentation/pages/evacuation_center_page.dart';
import 'features/emergency_contacts/data/models/contact.dart';
import 'features/emergency_contacts/data/repositories/contact_repository.dart';
import 'features/emergency_contacts/presentation/pages/contacts_page.dart';
import 'features/emergency_contacts/presentation/pages/safety_status_page.dart';
import 'features/household/data/repositories/household_repository.dart';
import 'features/household/presentation/pages/onboarding_page.dart';
import 'features/household/presentation/pages/profile_settings_page.dart';
import 'features/preparedness_instruction/models/instruction_guide.dart';
import 'features/preparedness_instruction/repositories/instruction_guide_repository.dart';
import 'features/preparedness_instruction/ui/category_grid.dart';
import 'features/preparedness_instruction/ui/guide_viewer.dart';
import 'features/supply_tracker/presentation/pages/supply_tracker_page.dart';
import 'features/supply_tracker/data/models/supply_item.dart';
import 'features/supply_tracker/data/repositories/supply_repository.dart';
import 'shared/models/household.dart';
import 'shared/services/local_notification_service.dart';
import 'shared/services/supabase_service.dart';
import 'shared/shared.dart';
import 'splash/logo_splash_screen.dart';

late SupplyRepository _supplyRepository;
late ContactRepository _contactRepository;
late HouseholdRepository _householdRepository;
late AlertsRepository _alertsRepository;
late EvacuationCenterRepository _evacuationCenterRepository;
late LocalNotificationService _localNotificationService;
late InstructionGuideRepository _instructionGuideRepository;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(SupplyItemAdapter());
  Hive.registerAdapter(ContactAdapter());
  Hive.registerAdapter(HouseholdAdapter());
  Hive.registerAdapter(CachedAlertAdapter());
  Hive.registerAdapter(CachedEvacCenterAdapter());
  Hive.registerAdapter(InstructionGuideAdapter());

  // Initialize SupplyRepository
  _supplyRepository = SupplyRepository();
  await _supplyRepository.initBox();

  // Initialize ContactRepository
  _contactRepository = ContactRepository();
  await _contactRepository.initBox();
  await _contactRepository.seedIfNeeded();

  // Initialize HouseholdRepository
  _householdRepository = HouseholdRepository();
  await _householdRepository.initBox();

  // Initialize AlertsRepository
  _alertsRepository = AlertsRepository();
  await _alertsRepository.initBox();

  // Initialize preparedness instruction guides
  _instructionGuideRepository = InstructionGuideRepository();
  await _instructionGuideRepository.initBox();
  await _instructionGuideRepository.seedIfNeeded();

  // Initialize Supabase before any repository sync uses the global client.
  await SupabaseService.initialize(
    url: 'https://jlzxptmwxqfdpmwchnex.supabase.co',
    anonKey: 'sb_publishable_qSuKMyniP2rYkpkEogCMfg_Nvvi6rD7',
  );

  // Initialize EvacuationCenterRepository
  _evacuationCenterRepository = EvacuationCenterRepository();
  await _evacuationCenterRepository.initBox();
  await _evacuationCenterRepository.syncFromSupabase();

  // Initialize local notification service
  _localNotificationService = LocalNotificationService.instance;
  await _localNotificationService.initialize();

  // Initialize FMTC ObjectBox backend for offline map tile caching.
  // Must be called before any FMTCStore or download operations.
  // Wrapped in try/catch to prevent a caching failure from crashing the app.
  try {
    await FMTCObjectBoxBackend().initialise();
  } catch (e) {
    // Log but do not rethrow — map caching is non-critical.
    debugPrint('[FMTC] Backend initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _onThemeChanged(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: BihonTheme.light(),
      darkTheme: BihonTheme.dark(),
      home: LogoSplashScreen(
        resolveNextRoute: () async {
          final completed = _householdRepository.hasCompletedOnboarding();
          return completed ? '/home' : '/household-onboarding';
        },
      ),
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) {
              return ShadToaster(
                child: HomePage(
                  themeMode: _themeMode,
                  onThemeChanged: _onThemeChanged,
                ),
              );
            },
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          );
        }
        if (settings.name == '/contacts') {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (context) => const ContactsPage(),
          );
        }
        if (settings.name == '/supplies') {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (context) => const SupplyTrackerPage(),
          );
        }
        if (settings.name == '/safety-status') {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (context) => const SafetyStatusPage(),
          );
        }
        if (settings.name == '/household-onboarding') {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (context) => HouseholdOnboardingPage(
              householdRepository: _householdRepository,
              onComplete: () {
                Navigator.of(context).pushReplacementNamed('/home');
              },
            ),
          );
        }
        if (settings.name == '/profile-settings') {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (context) => ProfileSettingsPage(
              householdRepository: _householdRepository,
            ),
          );
        }
        if (settings.name == '/alerts') {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (context) => const AlertsListPage(),
          );
        }
        if (settings.name == PreparednessCategoryGridPage.routeName) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (context) => PreparednessCategoryGridPage(
              repository: _instructionGuideRepository,
            ),
          );
        }
        if (settings.name == PreparednessGuideViewerPage.routeName) {
          final guideId = settings.arguments as String?;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (context) {
              if (guideId == null || guideId.trim().isEmpty) {
                return const Scaffold(
                  body: Center(child: Text('Guide id is missing.')),
                );
              }
              return PreparednessGuideViewerPage(
                repository: _instructionGuideRepository,
                guideId: guideId,
              );
            },
          );
        }
        if (settings.name == '/evacuation-centers') {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (context) => const EvacuationCenterPage(),
          );
        }
        return null;
      },
    );
  }
}

class HomePage extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final Widget? dashboardBody;

  const HomePage({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    this.dashboardBody,
  });

  void _openTab(BuildContext context, int index) {
    final routeName = switch (index) {
      0 => null,
      1 => '/alerts',
      2 => '/evacuation-centers',
      3 => '/supplies',
      4 => '/contacts',
      _ => null,
    };

    if (routeName != null) {
      Navigator.of(context).pushNamed(routeName);
    }
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

  @override
  Widget build(BuildContext context) {
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
                themeMode: themeMode,
                onChanged: onThemeChanged,
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
      bottomNavigationBar: CrisyncBottomNavigation(
        selectedIndex: 0,
        onDestinationSelected: (index) => _openTab(context, index),
      ),
      body: dashboardBody ??
          DashboardPage(
            supplyRepository: _supplyRepository,
            alertsRepository: _alertsRepository,
            contactRepository: _contactRepository,
            householdRepository: _householdRepository,
            evacuationCenterRepository: _evacuationCenterRepository,
            instructionGuideRepository: _instructionGuideRepository,
          ),
    );
  }
}

/// Global getter to access the SupplyRepository from anywhere in the app.
SupplyRepository getSupplyRepository() => _supplyRepository;

/// Global getter to access the ContactRepository from anywhere in the app.
ContactRepository getContactRepository() => _contactRepository;

/// Global getter to access local notifications from anywhere in the app.
LocalNotificationService getLocalNotificationService() => _localNotificationService;

/// Global getter to access the HouseholdRepository from anywhere in the app.
HouseholdRepository getHouseholdRepository() => _householdRepository;

/// Global getter to access the AlertsRepository from anywhere in the app.
AlertsRepository getAlertsRepository() => _alertsRepository;

/// Global getter to access the EvacuationCenterRepository from anywhere in the app.
EvacuationCenterRepository getEvacuationCenterRepository() => _evacuationCenterRepository;

/// Global getter to access the InstructionGuideRepository from anywhere in the app.
InstructionGuideRepository getInstructionGuideRepository() =>
    _instructionGuideRepository;
