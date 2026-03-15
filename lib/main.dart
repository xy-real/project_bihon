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
      theme: BihonTheme.light(),
      darkTheme: BihonTheme.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Project Bihon')),
      body: const Center(child: Text('Clean slate ready. Start building!')),
    );
  }
}