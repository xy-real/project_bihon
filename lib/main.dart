import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'features/supply_tracker/presentation/pages/supply_tracker_page.dart';
import 'features/supply_tracker/data/models/supply_item.dart';
import 'features/supply_tracker/data/repositories/supply_repository.dart';
import 'shared/shared.dart';

late SupplyRepository _supplyRepository;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(SupplyItemAdapter());

  // Initialize SupplyRepository
  _supplyRepository = SupplyRepository();
  await _supplyRepository.initBox();

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
      home: HomePage(
        themeMode: _themeMode,
        onThemeChanged: _onThemeChanged,
      ),
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