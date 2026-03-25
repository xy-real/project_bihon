import 'package:flutter/material.dart';
import 'package:project_bihon/features/supply_tracker/presentation/widgets/widgets.dart';

class SupplyTrackerPage extends StatelessWidget {
  const SupplyTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mockItems = [
      {
        'itemName': 'Medical Masks (N95)',
        'description': 'High-efficiency respirator masks for medical use',
        'stockCount': 150,
        'expirationDate': DateTime(2026, 6, 15),
      },
      {
        'itemName': 'Surgical Gloves',
        'description': 'Latex-free, sterile surgical gloves',
        'stockCount': 500,
        'expirationDate': DateTime(2025, 12, 31),
      },
      {
        'itemName': 'Antiseptic Solution',
        'description': '70% Isopropyl alcohol antiseptic',
        'stockCount': 45,
        'expirationDate': DateTime(2026, 2, 28),
      },
      {
        'itemName': 'First Aid Kit',
        'description': 'Comprehensive emergency first aid supplies',
        'stockCount': 12,
        'expirationDate': DateTime(2026, 9, 10),
      },
      {
        'itemName': 'Bandages & Gauze',
        'description': 'Sterile medical bandages and gauze pads',
        'stockCount': 200,
        'expirationDate': DateTime(2027, 1, 5),
      },
      {
        'itemName': 'Thermometer (Digital)',
        'description': 'Non-contact infrared digital thermometer',
        'stockCount': 8,
        'expirationDate': DateTime(2028, 5, 20),
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1000 ? 3 : width >= 640 ? 2 : 1;
        final gap = 16.0;
        final cardWidth = (width - (gap * (columns - 1))) / columns;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final item in mockItems)
                SizedBox(
                  width: cardWidth,
                  child: SupplyTrackerItemCard(
                    itemName: item['itemName'] as String,
                    description: item['description'] as String,
                    stockCount: item['stockCount'] as int,
                    expirationDate: item['expirationDate'] as DateTime,
                    imageUrl: null,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tapped: ${item['itemName']}')),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
