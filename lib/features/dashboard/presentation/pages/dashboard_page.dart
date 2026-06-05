import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:project_bihon/features/alerts/data/models/cached_alert.dart';
import 'package:project_bihon/features/alerts/data/repositories/alerts_repository.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/dashboard_design.dart';
import 'package:project_bihon/features/emergency_contacts/data/models/contact.dart';
import 'package:project_bihon/features/emergency_contacts/data/repositories/contact_repository.dart';
import 'package:project_bihon/features/emergency_contacts/domain/contact_validation.dart';
import 'package:project_bihon/features/evacuation_centers/data/models/cached_evac_center.dart';
import 'package:project_bihon/features/evacuation_centers/data/repositories/evacuation_center_repository.dart';
import 'package:project_bihon/features/household/data/repositories/household_repository.dart';
import 'package:project_bihon/features/preparedness_instruction/repositories/instruction_guide_repository.dart';
import 'package:project_bihon/features/preparedness_instruction/ui/category_grid.dart';
import 'package:project_bihon/features/supply_tracker/data/models/supply_item.dart';
import 'package:project_bihon/features/supply_tracker/data/repositories/supply_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.supplyRepository,
    required this.alertsRepository,
    required this.contactRepository,
    required this.householdRepository,
    required this.evacuationCenterRepository,
    required this.instructionGuideRepository,
    this.onOpenMainTab,
  }) : snapshot = null;

  const DashboardPage.fromSnapshot({
    super.key,
    required DashboardSnapshot this.snapshot,
    this.onOpenMainTab,
  })  : supplyRepository = null,
        alertsRepository = null,
        contactRepository = null,
        householdRepository = null,
        evacuationCenterRepository = null,
        instructionGuideRepository = null;

  static const int _preparednessScore = 65;
  static const int _essentialSupplyTarget = 12;

  final SupplyRepository? supplyRepository;
  final AlertsRepository? alertsRepository;
  final ContactRepository? contactRepository;
  final HouseholdRepository? householdRepository;
  final EvacuationCenterRepository? evacuationCenterRepository;
  final InstructionGuideRepository? instructionGuideRepository;
  final DashboardSnapshot? snapshot;
  final ValueChanged<int>? onOpenMainTab;

  void _open(BuildContext context, String routeName) {
    final mainTabIndex = switch (routeName) {
      '/home' => 0,
      '/alerts' => 1,
      '/evacuation-centers' => 2,
      '/supplies' => 3,
      '/contacts' => 4,
      _ => null,
    };

    if (mainTabIndex != null && onOpenMainTab != null) {
      onOpenMainTab!(mainTabIndex);
      return;
    }

    Navigator.of(context).pushNamed(routeName);
  }

  void _showReportUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report incident is not available yet.'),
      ),
    );
  }

  Future<void> _callContact(BuildContext context, Contact contact) async {
    final phone = ContactValidation.normalizePhone(contact.phoneNumber);
    final uri = Uri.parse('tel:$phone');

    try {
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No dialer is available.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start call.')),
        );
      }
    }
  }

  int _expiredCount(List<SupplyItem> supplies) {
    return supplies.where((item) => item.isExpired).length;
  }

  int _expiringSoonCount(List<SupplyItem> supplies) {
    return supplies.where((item) => !item.isExpired && item.expiresSoon).length;
  }

  SupplyItem? _soonestSupply(List<SupplyItem> supplies) {
    if (supplies.isEmpty) {
      return null;
    }

    final sorted = [...supplies]
      ..sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
    return sorted.first;
  }

  String _supplySubtitle(List<SupplyItem> supplies) {
    if (supplies.isEmpty) {
      return 'Add emergency supplies';
    }

    final expired = _expiredCount(supplies);
    if (expired > 0) {
      return '$expired expired ${expired == 1 ? 'item' : 'items'} need review';
    }

    final expiringSoon = _expiringSoonCount(supplies);
    final soonest = _soonestSupply(supplies);
    if (expiringSoon > 0 && soonest != null) {
      final days = soonest.expirationDate.difference(DateTime.now()).inDays;
      final normalizedDays = days < 0 ? 0 : days;
      return '${soonest.name} in $normalizedDays ${normalizedDays == 1 ? 'day' : 'days'}';
    }

    final lowStock = supplies.where((item) => item.quantity <= 2).length;
    if (lowStock > 0) {
      return '$lowStock low-stock ${lowStock == 1 ? 'item' : 'items'}';
    }

    return 'Inventory looks ready';
  }

  String _alertTitle(List<CachedAlert> alerts) {
    final activeAlerts = alerts.where((alert) => alert.isActive).toList();
    if (activeAlerts.isEmpty) {
      return 'No active alerts';
    }
    return '${activeAlerts.length} active ${activeAlerts.length == 1 ? 'alert' : 'alerts'}';
  }

  String _alertSubtitle(List<CachedAlert> alerts) {
    final activeAlerts = alerts.where((alert) => alert.isActive).toList();
    if (activeAlerts.isEmpty) {
      return 'All clear locally';
    }
    return activeAlerts.first.title;
  }

  String _evacuationSubtitle(List<CachedEvacCenter> centers) {
    if (centers.isEmpty) {
      return 'No cached centers yet';
    }

    final nearCapacity = centers
        .where((center) => center.status.toLowerCase() == 'near capacity')
        .length;
    if (nearCapacity > 0) {
      return 'Nearby capacity >50%';
    }

    final openCenters =
        centers.where((center) => center.status.toLowerCase() == 'open').length;
    if (openCenters > 0) {
      return '$openCenters open ${openCenters == 1 ? 'center' : 'centers'} available';
    }

    return 'Review center status';
  }

  List<_ContactPreview> _contactPreviews(List<Contact> contacts) {
    if (contacts.isNotEmpty) {
      return contacts
          .take(3)
          .map(
            (contact) => _ContactPreview(
              name: contact.name,
              relationship: contact.type,
              contact: contact,
            ),
          )
          .toList();
    }

    return const [
      _ContactPreview(name: 'John Doe', relationship: 'Brother'),
      _ContactPreview(name: 'Jane Smith', relationship: 'Mother'),
      _ContactPreview(
        name: 'Barangay Captain',
        relationship: 'Local Authority',
      ),
    ];
  }

  Widget _buildPreparednessScoreCard(
    BuildContext context,
    List<SupplyItem> supplies,
    List<Contact> contacts,
  ) {
    final trackedSupplyCount = supplies.length.clamp(0, _essentialSupplyTarget);

    return _DashboardCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Preparedness Score',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Stay ready for any situation.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DashboardDesign.mutedText(context),
                ),
          ),
          const SizedBox(height: 18),
          Text(
            '$_preparednessScore%',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: DashboardDesign.deepNavy,
                ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _preparednessScore / 100,
              minHeight: 10,
              backgroundColor: DashboardDesign.surfaceVariant(context),
              valueColor: const AlwaysStoppedAnimation<Color>(
                DashboardDesign.deepNavy,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _SummaryRow(
            icon: LucideIcons.packageCheck,
            text: '$trackedSupplyCount of $_essentialSupplyTarget essential supplies',
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            icon: LucideIcons.users,
            text:
                '${contacts.length} family ${contacts.length == 1 ? 'contact' : 'contacts'} added',
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _open(context, PreparednessCategoryGridPage.routeName),
              style: TextButton.styleFrom(
                foregroundColor: DashboardDesign.deepNavy,
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
              child: const Text('Improve Now ->'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCards(
    BuildContext context,
    List<CachedAlert> alerts,
    List<CachedEvacCenter> centers,
    List<SupplyItem> supplies,
  ) {
    final cards = [
      _StatusCardData(
        color: DashboardDesign.danger,
        icon: Icons.warning_amber_rounded,
        title: _alertTitle(alerts),
        subtitle: _alertSubtitle(alerts),
        routeName: '/alerts',
      ),
      _StatusCardData(
        color: DashboardDesign.info,
        icon: LucideIcons.mapPin,
        title: '${centers.length} evac centers',
        subtitle: _evacuationSubtitle(centers),
        routeName: '/evacuation-centers',
      ),
      _StatusCardData(
        color: DashboardDesign.warning,
        icon: LucideIcons.droplets,
        title: _expiringSoonCount(supplies) > 0
            ? '${_expiringSoonCount(supplies)} supplies expiring'
            : 'Supplies expiring',
        subtitle: _supplySubtitle(supplies),
        routeName: '/supplies',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 3 : 1;
        const gap = DashboardDesign.gap;
        final width = (constraints.maxWidth - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards)
              SizedBox(
                width: width,
                child: _QuickStatusCard(
                  data: card,
                  onTap: () => _open(context, card.routeName),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildContactsCard(BuildContext context, List<Contact> contacts) {
    final previews = _contactPreviews(contacts);

    return _DashboardCard(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Emergency Contacts',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () => _open(context, '/contacts'),
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          for (final preview in previews)
            _ContactPreviewRow(
              preview: preview,
              onCall: preview.contact == null
                  ? () => _open(context, '/contacts')
                  : () => _callContact(context, preview.contact!),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _ActionButtonData(
        label: 'Send Safety Status',
        icon: LucideIcons.shieldCheck,
        color: DashboardDesign.deepNavy,
        onTap: () => _open(context, '/safety-status'),
      ),
      _ActionButtonData(
        label: 'Call Emergency',
        icon: LucideIcons.phoneCall,
        color: DashboardDesign.warning,
        onTap: () => _open(context, '/contacts'),
      ),
      _ActionButtonData(
        label: 'Report Incident',
        icon: LucideIcons.megaphone,
        color: DashboardDesign.danger,
        onTap: () => _showReportUnavailable(context),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        const gap = DashboardDesign.gap;
        final width = isWide
            ? (constraints.maxWidth - (gap * (actions.length - 1))) /
                actions.length
            : constraints.maxWidth;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final action in actions)
              SizedBox(
                width: width,
                child: _DashboardActionButton(action: action),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDashboard({
    required BuildContext context,
    required List<SupplyItem> supplies,
    required List<CachedAlert> alerts,
    required List<CachedEvacCenter> centers,
    required List<Contact> contacts,
  }) {
    final horizontalPadding = MediaQuery.sizeOf(context).width >= 600
        ? DashboardDesign.marginTablet
        : DashboardDesign.marginMobile;

    return ColoredBox(
      color: DashboardDesign.background(context),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            DashboardDesign.gap,
            horizontalPadding,
            DashboardDesign.sectionGap,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPreparednessScoreCard(context, supplies, contacts),
                  const SizedBox(height: DashboardDesign.gap),
                  _buildStatusCards(context, alerts, centers, supplies),
                  const SizedBox(height: DashboardDesign.gap),
                  _buildContactsCard(context, contacts),
                  const SizedBox(height: DashboardDesign.gap),
                  _buildQuickActions(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = this.snapshot;
    if (snapshot != null) {
      return Scaffold(
        body: _buildDashboard(
          context: context,
          supplies: snapshot.supplies,
          alerts: snapshot.alerts,
          contacts: snapshot.contacts,
          centers: snapshot.centers,
        ),
      );
    }

    return ValueListenableBuilder<Box<SupplyItem>>(
      valueListenable: supplyRepository!.getItemsListenable(),
      builder: (context, suppliesBox, _) {
        return ValueListenableBuilder<Box<CachedAlert>>(
          valueListenable: alertsRepository!.getAlertsListenable(),
          builder: (context, alertsBox, _) {
            return ValueListenableBuilder<Box<Contact>>(
              valueListenable: contactRepository!.getContactsListenable(),
              builder: (context, contactsBox, _) {
                return ValueListenableBuilder<Box<CachedEvacCenter>>(
                  valueListenable: evacuationCenterRepository!.getListenable(),
                  builder: (context, centersBox, _) {
                    return _buildDashboard(
                      context: context,
                      supplies: suppliesBox.values.toList(),
                      alerts: alertsBox.values.toList(),
                      contacts: contactsBox.values.toList(),
                      centers: centersBox.values.toList(),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class DashboardSnapshot {
  const DashboardSnapshot({
    this.supplies = const [],
    this.alerts = const [],
    this.contacts = const [],
    this.centers = const [],
  });

  final List<SupplyItem> supplies;
  final List<CachedAlert> alerts;
  final List<Contact> contacts;
  final List<CachedEvacCenter> centers;
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: DashboardDesign.surface(context),
        borderRadius: BorderRadius.circular(DashboardDesign.radius),
        border: Border.all(color: DashboardDesign.outline(context)),
        boxShadow: DashboardDesign.cardShadow(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: DashboardDesign.mutedText(context)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DashboardDesign.mutedText(context),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _QuickStatusCard extends StatelessWidget {
  const _QuickStatusCard({
    required this.data,
    required this.onTap,
  });

  final _StatusCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DashboardDesign.radius),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: DashboardDesign.surface(context),
            borderRadius: BorderRadius.circular(DashboardDesign.radius),
            border: Border.all(color: DashboardDesign.outline(context)),
            boxShadow: DashboardDesign.cardShadow(context),
          ),
          child: SizedBox(
            height: 112,
            child: Row(
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: data.color,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(DashboardDesign.radius),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: DashboardDesign.statusBackground(
                              context,
                              data.color,
                            ),
                            borderRadius: BorderRadius.circular(
                              DashboardDesign.compactRadius,
                            ),
                          ),
                          child: Icon(data.icon, color: data.color, size: 23),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                data.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: DashboardDesign.mutedText(context),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 22),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactPreviewRow extends StatelessWidget {
  const _ContactPreviewRow({
    required this.preview,
    required this.onCall,
  });

  final _ContactPreview preview;
  final VoidCallback onCall;

  String get _initials {
    final parts = preview.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: DashboardDesign.statusBackground(
              context,
              DashboardDesign.info,
            ),
            child: Text(
              _initials,
              style: const TextStyle(
                color: DashboardDesign.deepNavy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preview.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  preview.relationship,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DashboardDesign.mutedText(context),
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Call contact',
            onPressed: onCall,
            icon: const Icon(Icons.phone_outlined),
          ),
        ],
      ),
    );
  }
}

class _DashboardActionButton extends StatelessWidget {
  const _DashboardActionButton({required this.action});

  final _ActionButtonData action;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: action.onTap,
      icon: Icon(action.icon),
      label: Text(
        action.label,
        overflow: TextOverflow.ellipsis,
      ),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        backgroundColor: action.color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DashboardDesign.radius),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _StatusCardData {
  const _StatusCardData({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.routeName,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final String routeName;
}

class _ActionButtonData {
  const _ActionButtonData({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _ContactPreview {
  const _ContactPreview({
    required this.name,
    required this.relationship,
    this.contact,
  });

  final String name;
  final String relationship;
  final Contact? contact;
}
