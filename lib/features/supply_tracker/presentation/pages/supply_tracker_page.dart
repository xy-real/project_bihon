import 'package:flutter/material.dart';
import 'package:project_bihon/shared/shared.dart';

class SupplyTrackerPage extends StatelessWidget {
  const SupplyTrackerPage({super.key});

  static const headers = ['ID', 'Name', 'Role', 'Status'];
  static const rows = [
    ['001', 'Alicia Cruz', 'Admin', 'Active'],
    ['002', 'Marco Reyes', 'Editor', 'Pending'],
    ['003', 'Nina Santos', 'Viewer', 'Inactive'],
    ['004', 'Jared Lim', 'Editor', 'Active'],
  ];

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: AppTable(headers: headers, rows: rows),
    );
  }
}
