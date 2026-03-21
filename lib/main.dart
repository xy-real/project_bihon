import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'features/supply_tracker/presentation/pages/supply_tracker_page.dart';
import 'shared/shared.dart';

void main() {
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