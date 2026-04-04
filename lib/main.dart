import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'features/emergency_contacts/data/models/contact.dart';
import 'features/emergency_contacts/data/repositories/contact_repository.dart';
import 'features/emergency_contacts/presentation/pages/contacts_page.dart';
import 'features/emergency_contacts/presentation/pages/safety_status_page.dart';
import 'features/supply_tracker/presentation/pages/supply_tracker_page.dart';
import 'features/supply_tracker/data/models/supply_item.dart';
import 'features/supply_tracker/data/repositories/supply_repository.dart';
import 'shared/services/local_notification_service.dart';
import 'shared/shared.dart';
import 'splash/logo_splash_screen.dart';

late SupplyRepository _supplyRepository;
late ContactRepository _contactRepository;
late LocalNotificationService _localNotificationService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(SupplyItemAdapter());
  Hive.registerAdapter(ContactAdapter());

  // Initialize SupplyRepository
  _supplyRepository = SupplyRepository();
  await _supplyRepository.initBox();

  // Initialize ContactRepository
  _contactRepository = ContactRepository();
  await _contactRepository.initBox();
  await _contactRepository.seedIfNeeded();

  // Initialize local notification service
  _localNotificationService = LocalNotificationService.instance;
  await _localNotificationService.initialize();

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
      home: const LogoSplashScreen(),
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
        if (settings.name == '/safety-status') {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (context) => const SafetyStatusPage(),
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

  const HomePage({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crisync'),
        actions: [
          IconButton(
            tooltip: 'Emergency Contacts',
            onPressed: () {
              Navigator.of(context).pushNamed('/contacts');
            },
            icon: const Icon(Icons.contacts_outlined),
          ),
          IconButton(
            tooltip: 'Safety Status',
            onPressed: () {
              Navigator.of(context).pushNamed('/safety-status');
            },
            icon: const Icon(Icons.sms_outlined),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: AppThemeSwitcher(
                themeMode: themeMode,
                onChanged: onThemeChanged,
                showLabel: false,
              ),
            ),
          ),
        ],
      ),
      body: const SupplyTrackerPage(),
    );
  }
}

/// Global getter to access the SupplyRepository from anywhere in the app.
SupplyRepository getSupplyRepository() => _supplyRepository;

/// Global getter to access the ContactRepository from anywhere in the app.
ContactRepository getContactRepository() => _contactRepository;

/// Global getter to access local notifications from anywhere in the app.
LocalNotificationService getLocalNotificationService() => _localNotificationService;