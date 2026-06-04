import 'package:flutter/material.dart';

class CrisyncBottomNavigation extends StatelessWidget {
  const CrisyncBottomNavigation({
    super.key,
    this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int? selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final selected = selectedIndex;
    if (selected == null) {
      final neutralColor = Theme.of(context).colorScheme.onSurfaceVariant;

      return NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: Colors.transparent,
          iconTheme: WidgetStatePropertyAll(
            IconThemeData(color: neutralColor),
          ),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(color: neutralColor, fontSize: 12),
          ),
        ),
        child: NavigationBar(
          selectedIndex: 0,
          onDestinationSelected: onDestinationSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications_outlined),
              label: 'Alerts',
            ),
            NavigationDestination(
              icon: Icon(Icons.location_on_outlined),
              selectedIcon: Icon(Icons.location_on_outlined),
              label: 'Evacuation',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2_outlined),
              label: 'Supplies',
            ),
            NavigationDestination(
              icon: Icon(Icons.contacts_outlined),
              selectedIcon: Icon(Icons.contacts_outlined),
              label: 'Contacts',
            ),
          ],
        ),
      );
    }

    return NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: onDestinationSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications),
          label: 'Alerts',
        ),
        NavigationDestination(
          icon: Icon(Icons.location_on_outlined),
          selectedIcon: Icon(Icons.location_on),
          label: 'Evacuation',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: 'Supplies',
        ),
        NavigationDestination(
          icon: Icon(Icons.contacts_outlined),
          selectedIcon: Icon(Icons.contacts),
          label: 'Contacts',
        ),
      ],
    );
  }
}
