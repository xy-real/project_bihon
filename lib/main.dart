import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'shared/shared.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      debugShowCheckedModeBanner: false,
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadZincColorScheme.light(),
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadZincColorScheme.dark(),
      ),
      home: const StarterHomePage(),
    );
  }
}

class StarterHomePage extends StatefulWidget {
  const StarterHomePage({super.key});

  @override
  State<StarterHomePage> createState() => _StarterHomePageState();
}

class _StarterHomePageState extends State<StarterHomePage> {
  final TextEditingController _itemNameController = TextEditingController();
  String _statusText = 'Ready to build your first feature.';

  @override
  void dispose() {
    _itemNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Bihon Starter'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            title: 'Start Coding Here',
            description: 'Use this page as your playground while learning Flutter.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _itemNameController,
                  label: 'Item Name',
                  placeholder: 'e.g. Flashlight',
                ),
                const SizedBox(height: 16),
                AppButton(
                  onPressed: () {
                    final name = _itemNameController.text.trim();
                    setState(() {
                      _statusText = name.isEmpty
                          ? 'Type an item name first.'
                          : 'Saved draft item: $name';
                    });
                  },
                  child: const Text('Save Draft'),
                ),
                const SizedBox(height: 12),
                Text(_statusText),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
