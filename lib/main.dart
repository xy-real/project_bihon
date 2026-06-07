import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'features/ai_preparedness_score/data/repositories/ai_score_repository.dart';
import 'features/ai_preparedness_score/models/ai_score_cache.dart';
import 'features/ai_preparedness_score/services/ai_score_service.dart';
import 'features/ai_preparedness_score/ui/ai_score_detail_screen.dart';
import 'features/alerts/data/models/alert_sync_state.dart';
import 'features/alerts/data/models/cached_alert.dart';
import 'features/alerts/data/repositories/alerts_repository.dart';
import 'features/alerts/data/services/alert_sync_service.dart';
import 'features/dashboard/presentation/pages/main_tab_shell.dart';
import 'features/evacuation_centers/data/models/cached_evac_center.dart';
import 'features/evacuation_centers/data/repositories/evacuation_center_repository.dart';
import 'features/emergency_contacts/data/models/contact.dart';
import 'features/emergency_contacts/data/repositories/contact_repository.dart';
import 'features/emergency_contacts/presentation/pages/safety_status_page.dart';
import 'features/household/data/repositories/household_repository.dart';
import 'features/household/presentation/pages/onboarding_page.dart';
import 'features/household/presentation/pages/profile_settings_page.dart';
import 'features/preparedness_instruction/models/instruction_guide.dart';
import 'features/preparedness_instruction/repositories/instruction_guide_repository.dart';
import 'features/preparedness_instruction/ui/category_grid.dart';
import 'features/preparedness_instruction/ui/guide_viewer.dart';
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
late AlertSyncService _alertSyncService;
late EvacuationCenterRepository _evacuationCenterRepository;
late LocalNotificationService _localNotificationService;
late InstructionGuideRepository _instructionGuideRepository;
late AIScoreRepository _aiScoreRepository;
late AIScoreService _aiScoreService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(SupplyItemAdapter());
  Hive.registerAdapter(ContactAdapter());
  Hive.registerAdapter(HouseholdAdapter());
  Hive.registerAdapter(CachedAlertAdapter());
  Hive.registerAdapter(AlertSyncStateAdapter());
  Hive.registerAdapter(CachedEvacCenterAdapter());
  Hive.registerAdapter(InstructionGuideAdapter());
  Hive.registerAdapter(AIScoreCacheAdapter());

  // Initialize the offline cache for the latest AI preparedness score.
  _aiScoreRepository = AIScoreRepository();
  await _aiScoreRepository.initBox();

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

  _aiScoreService = AIScoreService(
    householdRepository: _householdRepository,
    supplyRepository: _supplyRepository,
    scoreRepository: _aiScoreRepository,
  );

  // Initialize AlertsRepository
  _alertsRepository = AlertsRepository();
  await _alertsRepository.initBox();
  await Hive.openBox<AlertSyncState>(AlertSyncState.boxName);

  // Initialize preparedness instruction guides
  _instructionGuideRepository = InstructionGuideRepository();
  await _instructionGuideRepository.initBox();
  await _instructionGuideRepository.seedIfNeeded();

  // Initialize Supabase before any repository sync uses the global client.
  await SupabaseService.initialize(
    url: 'https://jlzxptmwxqfdpmwchnex.supabase.co',
    anonKey: 'sb_publishable_qSuKMyniP2rYkpkEogCMfg_Nvvi6rD7',
  );

  _alertSyncService = AlertSyncService();
  unawaited(_alertSyncService.syncAlerts());

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
        final mainTabIndex = switch (settings.name) {
          '/home' => 0,
          '/alerts' => 1,
          '/evacuation-centers' => 2,
          '/supplies' => 3,
          '/contacts' => 4,
          _ => null,
        };

        if (mainTabIndex != null) {
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) {
              return ShadToaster(
                child: MainTabShell(
                  initialIndex: mainTabIndex,
                  themeMode: _themeMode,
                  onThemeChanged: _onThemeChanged,
                  supplyRepository: _supplyRepository,
                  alertsRepository: _alertsRepository,
                  alertSyncService: _alertSyncService,
                  contactRepository: _contactRepository,
                  householdRepository: _householdRepository,
                  evacuationCenterRepository: _evacuationCenterRepository,
                  instructionGuideRepository: _instructionGuideRepository,
                  aiScoreRepository: _aiScoreRepository,
                  aiScoreService: _aiScoreService,
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
        if (settings.name == AIScoreDetailScreen.routeName) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (context) => AIScoreDetailScreen(
              repository: _aiScoreRepository,
              service: _aiScoreService,
            ),
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
        return null;
      },
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

/// Global getter for alert synchronization into the local Hive cache.
AlertSyncService getAlertSyncService() => _alertSyncService;

/// Global getter to access the EvacuationCenterRepository from anywhere in the app.
EvacuationCenterRepository getEvacuationCenterRepository() => _evacuationCenterRepository;

/// Global getter to access the InstructionGuideRepository from anywhere in the app.
InstructionGuideRepository getInstructionGuideRepository() =>
    _instructionGuideRepository;

/// Global getter to access the cached AI preparedness score repository.
AIScoreRepository getAIScoreRepository() => _aiScoreRepository;

/// Global getter for user-triggered AI preparedness score recalculation.
AIScoreService getAIScoreService() => _aiScoreService;
