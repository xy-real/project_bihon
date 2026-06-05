import 'package:flutter/material.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/dashboard_design.dart';

class CrisyncBottomNavigation extends StatelessWidget {
  const CrisyncBottomNavigation({
    super.key,
    this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int? selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const List<_CrisyncNavItem> _items = [
    _CrisyncNavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    _CrisyncNavItem(
      label: 'Alerts',
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications,
    ),
    _CrisyncNavItem(
      label: 'Evacuation',
      icon: Icons.map_outlined,
      selectedIcon: Icons.map,
    ),
    _CrisyncNavItem(
      label: 'Supplies',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
    ),
    _CrisyncNavItem(
      label: 'Contacts',
      icon: Icons.contacts_outlined,
      selectedIcon: Icons.contacts,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DashboardDesign.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(color: DashboardDesign.outline(context)),
        ),
        boxShadow: [
          if (Theme.of(context).brightness == Brightness.light)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            10,
            8,
            10,
            bottomPadding > 0 ? 4 : 8,
          ),
          child: Row(
            children: [
              for (var index = 0; index < _items.length; index++)
                Expanded(
                  child: _AnimatedNavDestination(
                    item: _items[index],
                    selected: selectedIndex == index,
                    onTap: () => onDestinationSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedNavDestination extends StatelessWidget {
  const _AnimatedNavDestination({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _CrisyncNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = DashboardDesign.deepNavy;
    final inactiveColor = DashboardDesign.mutedText(context);
    final color = selected ? activeColor : inactiveColor;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: SizedBox(
              height: 58,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: selected ? 46 : 38,
                    height: 28,
                    decoration: BoxDecoration(
                      color: selected
                          ? DashboardDesign.statusBackground(
                              context,
                              DashboardDesign.deepNavy,
                            )
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: Icon(
                        selected ? item.selectedIcon : item.icon,
                        key: ValueKey('${item.label}-$selected'),
                        color: color,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight:
                                  selected ? FontWeight.w900 : FontWeight.w600,
                            ) ??
                        TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w900 : FontWeight.w600,
                        ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.label,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CrisyncNavItem {
  const _CrisyncNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
