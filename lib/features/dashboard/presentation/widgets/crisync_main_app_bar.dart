import 'package:flutter/material.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/dashboard_design.dart';

class CrisyncHeaderLogo extends StatelessWidget {
  const CrisyncHeaderLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Image.asset('assets/crisync_logo.png', fit: BoxFit.contain),
    );
  }
}

class CrisyncMainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CrisyncMainAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: preferredSize.height,
      backgroundColor: DashboardDesign.surface(context),
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CrisyncHeaderLogo(),
          const SizedBox(width: 10),
          const Text('Crisync', style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Profile Settings',
          onPressed: () {
            Navigator.of(context).pushNamed('/profile-settings');
          },
          icon: const Icon(Icons.settings_outlined),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
