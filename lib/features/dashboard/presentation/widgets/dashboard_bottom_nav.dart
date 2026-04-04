import 'package:flutter/material.dart';
import 'package:project_bihon/shared/shared.dart';

class DashboardBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const DashboardBottomNav({super.key, this.currentIndex = 0, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topIconColor = Theme.of(context).appBarTheme.iconTheme?.color;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: BihonTheme.bihonOrange,
      unselectedItemColor: isDark
          ? (topIconColor ?? Colors.white70)
          : Colors.grey,
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          activeIcon: Icon(Icons.inventory_2),
          label: 'Supplies',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_outlined),
          activeIcon: Icon(Icons.notifications),
          label: 'Alerts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.contacts_outlined),
          activeIcon: Icon(Icons.contacts),
          label: 'Contacts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
