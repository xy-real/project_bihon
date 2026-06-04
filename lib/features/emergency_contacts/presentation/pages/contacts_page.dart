import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/crisync_bottom_navigation.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/dashboard_design.dart';
import 'package:project_bihon/features/emergency_contacts/data/models/contact.dart';
import 'package:project_bihon/features/emergency_contacts/data/repositories/contact_repository.dart';
import 'package:project_bihon/features/emergency_contacts/data/repositories/contact_repository_exceptions.dart';
import 'package:project_bihon/features/emergency_contacts/domain/contact_validation.dart';
import 'package:project_bihon/main.dart' show getContactRepository;
import 'package:project_bihon/shared/widgets/app_toast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  static const Uuid _uuid = Uuid();

  late final ContactRepository _repository;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _repository = getContactRepository();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Contact> _applySearch(List<Contact> contacts) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return contacts;
    }

    return contacts.where((contact) {
      final name = contact.name.toLowerCase();
      final phone = contact.phoneNumber.toLowerCase();
      final type = contact.type.toLowerCase();
      final management = contact.isPreFilled
          ? 'official authorities system managed verified agency'
          : 'personal network family neighbor';
      return name.contains(query) ||
          phone.contains(query) ||
          type.contains(query) ||
          management.contains(query);
    }).toList();
  }

  Map<String, List<Contact>> _groupByType(List<Contact> contacts) {
    final grouped = <String, List<Contact>>{};
    for (final contact in contacts) {
      grouped.putIfAbsent(contact.type, () => []).add(contact);
    }

    for (final entry in grouped.entries) {
      entry.value.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    }

    return grouped;
  }

  List<String> _orderedTypes(Map<String, List<Contact>> grouped) {
    final knownOrder = ContactValidation.allowedTypes;
    final inKnownOrder = knownOrder.where(grouped.containsKey).toList();
    final unknown = grouped.keys.where((type) => !knownOrder.contains(type)).toList()
      ..sort();
    return [...inKnownOrder, ...unknown];
  }

  Future<void> _callContact(Contact contact) async {
    final normalizedPhone = ContactValidation.normalizePhone(contact.phoneNumber);
    if (normalizedPhone.isEmpty) {
      AppToast.error(
        context,
        title: 'Call unavailable',
        message: 'This contact has no phone number.',
      );
      return;
    }

    final uri = Uri.parse('tel:$normalizedPhone');

    try {
      final launched = await launchUrl(uri);
      if (!launched && mounted) {
        AppToast.error(
          context,
          title: 'Call unavailable',
          message: 'No dialer is available for this device.',
        );
      }
    } catch (error) {
      if (mounted) {
        AppToast.errorFromException(
          context,
          title: 'Failed to start call',
          error: error,
        );
      }
    }
  }

  Future<void> _messageContact(Contact contact) async {
    final normalizedPhone = ContactValidation.normalizePhone(contact.phoneNumber);
    if (normalizedPhone.isEmpty) {
      AppToast.error(
        context,
        title: 'Messaging unavailable',
        message: 'Messaging is not available for this contact.',
      );
      return;
    }

    final uri = Uri.parse('sms:$normalizedPhone');

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        AppToast.error(
          context,
          title: 'Messaging unavailable',
          message: 'Messaging is not available for this contact.',
        );
      }
    } catch (error) {
      if (mounted) {
        AppToast.errorFromException(
          context,
          title: 'Failed to start messaging',
          error: error,
        );
      }
    }
  }

  Future<void> _deleteContact(Contact contact) async {
    if (contact.isPreFilled) {
      if (mounted) {
        AppToast.error(
          context,
          title: 'Protected contact',
          message: 'Pre-filled emergency contacts cannot be deleted.',
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Contact'),
          content: Text('Delete ${contact.name}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _repository.deleteContact(contact.id);
      if (mounted) {
        AppToast.success(
          context,
          title: 'Contact deleted',
          message: ContactValidation.normalizeName(contact.name),
        );
      }
    } on ContactPrefilledDeleteException {
      if (mounted) {
        AppToast.error(
          context,
          title: 'Protected contact',
          message: 'Pre-filled emergency contacts cannot be deleted.',
        );
      }
    } on ContactNotFoundException catch (error) {
      if (mounted) {
        AppToast.error(
          context,
          title: 'Contact missing',
          message: error.message,
        );
      }
    } catch (error) {
      if (mounted) {
        AppToast.errorFromException(
          context,
          title: 'Failed to delete contact',
          error: error,
        );
      }
    }
  }

  void _handleBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacementNamed('/home');
  }

  void _openTab(int index) {
    final navigator = Navigator.of(context);
    final routeName = switch (index) {
      0 => '/home',
      1 => '/alerts',
      2 => '/evacuation-centers',
      3 => '/supplies',
      4 => null,
      _ => null,
    };

    if (routeName == null) {
      return;
    }

    if (index == 0) {
      navigator.pushNamedAndRemoveUntil(routeName, (route) => false);
    } else {
      navigator.pushReplacementNamed(routeName);
    }
  }

  List<Contact> _personalContacts(List<Contact> contacts) {
    return contacts.where((contact) => !contact.isPreFilled).toList();
  }

  List<Contact> _officialContacts(List<Contact> contacts) {
    return contacts.where((contact) => contact.isPreFilled).toList();
  }

  String _initialsFor(String name) {
    final parts = name
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

  Color _officialAccent(Contact contact) {
    final name = contact.name.toLowerCase();
    if (name.contains('fire')) {
      return DashboardDesign.warning;
    }
    return DashboardDesign.info;
  }

  IconData _officialIcon(Contact contact) {
    final name = contact.name.toLowerCase();
    if (name.contains('fire')) {
      return Icons.local_fire_department_outlined;
    }
    if (name.contains('hospital')) {
      return Icons.local_hospital_outlined;
    }
    if (name.contains('police')) {
      return Icons.local_police_outlined;
    }
    return Icons.verified_user_outlined;
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final addButton = FilledButton.icon(
          onPressed: _showAddContactModal,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Add Contact'),
          style: FilledButton.styleFrom(
            backgroundColor: DashboardDesign.deepNavy,
            foregroundColor: Colors.white,
            minimumSize: const Size(150, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashboardDesign.radius),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        );

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency Contacts',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap a contact to initiate immediate communication.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DashboardDesign.mutedText(context),
                  ),
            ),
          ],
        );

        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleBlock,
              const SizedBox(height: 14),
              addButton,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: DashboardDesign.gap),
            addButton,
          ],
        );
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search name, role, or agency...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _query = '';
                  });
                },
                icon: const Icon(Icons.close),
              ),
        filled: true,
        fillColor: DashboardDesign.surface(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DashboardDesign.radius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DashboardDesign.radius),
          borderSide: BorderSide(color: DashboardDesign.outline(context)),
        ),
      ),
      onChanged: (value) {
        setState(() {
          _query = value;
        });
      },
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: DashboardDesign.statusBackground(
              context,
              DashboardDesign.deepNavy,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: DashboardDesign.deepNavy, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildSystemManagedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DashboardDesign.statusBackground(context, DashboardDesign.info),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'System Managed',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: DashboardDesign.info,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }

  Widget _buildGroupedSection({
    required String emptyMessage,
    required List<Contact> contacts,
    required bool official,
  }) {
    if (contacts.isEmpty) {
      return _EmptyContactsCard(message: emptyMessage);
    }

    final grouped = _groupByType(contacts);
    final orderedTypes = _orderedTypes(grouped);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < orderedTypes.length; index++) ...[
          _ContactTypeGroup(
            type: orderedTypes[index],
            contacts: grouped[orderedTypes[index]] ?? const <Contact>[],
            official: official,
            initialsFor: _initialsFor,
            officialAccent: _officialAccent,
            officialIcon: _officialIcon,
            onTap: _showEditContactModal,
            onCall: _callContact,
            onMessage: _messageContact,
            onDelete: _deleteContact,
          ),
          if (index != orderedTypes.length - 1)
            const SizedBox(height: DashboardDesign.gap),
        ],
      ],
    );
  }

  Widget _buildContactsContent(List<Contact> filtered) {
    final personalContacts = _personalContacts(filtered);
    final officialContacts = _officialContacts(filtered);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          icon: Icons.group_outlined,
          title: 'Personal Network',
        ),
        const SizedBox(height: 12),
        _buildGroupedSection(
          contacts: personalContacts,
          official: false,
          emptyMessage: _query.trim().isEmpty
              ? 'No personal contacts yet. Add a family or trusted contact.'
              : 'No personal contacts match your search.',
        ),
        const SizedBox(height: DashboardDesign.sectionGap),
        _buildSectionHeader(
          icon: Icons.verified_outlined,
          title: 'Official Authorities',
          trailing: _buildSystemManagedBadge(),
        ),
        const SizedBox(height: 12),
        _buildGroupedSection(
          contacts: officialContacts,
          official: true,
          emptyMessage: _query.trim().isEmpty
              ? 'No official contacts are cached yet.'
              : 'No official contacts match your search.',
        ),
      ],
    );
  }

  Future<void> _showEditContactModal(Contact existingContact) async {
    final updatedContactName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (sheetContext) {
        return _EditContactSheet(
          repository: _repository,
          existingContact: existingContact,
        );
      },
    );

    if (updatedContactName != null && mounted) {
      AppToast.success(
        context,
        title: 'Contact updated',
        message: updatedContactName,
      );
    }
  }

  Future<void> _showAddContactModal() async {
    final addedContactName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (sheetContext) {
        return _AddContactSheet(
          repository: _repository,
          createId: _uuid.v4,
        );
      },
    );

    if (addedContactName != null && mounted) {
      AppToast.success(
        context,
        title: 'Contact added',
        message: addedContactName,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = MediaQuery.sizeOf(context).width >= 600
        ? DashboardDesign.marginTablet
        : DashboardDesign.marginMobile;

    return Scaffold(
      backgroundColor: DashboardDesign.background(context),
      appBar: AppBar(
        toolbarHeight: 56,
        backgroundColor: DashboardDesign.surface(context),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBack,
        ),
        titleSpacing: 0,
        title: const Text(
          'Emergency Contacts',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Profile Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).pushNamed('/profile-settings');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: CrisyncBottomNavigation(
        selectedIndex: 4,
        onDestinationSelected: _openTab,
      ),
      body: ValueListenableBuilder<Box<Contact>>(
        valueListenable: _repository.getContactsListenable(),
        builder: (context, box, _) {
          final allContacts = box.values.toList();
          final filtered = _applySearch(allContacts);

          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                DashboardDesign.gap,
                horizontalPadding,
                96,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: DashboardDesign.gap),
                      _buildSearchField(),
                      const SizedBox(height: DashboardDesign.sectionGap),
                      _buildContactsContent(filtered),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ContactTypeGroup extends StatelessWidget {
  const _ContactTypeGroup({
    required this.type,
    required this.contacts,
    required this.official,
    required this.initialsFor,
    required this.officialAccent,
    required this.officialIcon,
    required this.onTap,
    required this.onCall,
    required this.onMessage,
    required this.onDelete,
  });

  final String type;
  final List<Contact> contacts;
  final bool official;
  final String Function(String name) initialsFor;
  final Color Function(Contact contact) officialAccent;
  final IconData Function(Contact contact) officialIcon;
  final ValueChanged<Contact> onTap;
  final ValueChanged<Contact> onCall;
  final ValueChanged<Contact> onMessage;
  final ValueChanged<Contact> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            type,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: DashboardDesign.mutedText(context),
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 700 ? 2 : 1;
            const gap = DashboardDesign.gap;
            final width =
                (constraints.maxWidth - (gap * (columns - 1))) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final contact in contacts)
                  SizedBox(
                    width: width,
                    child: official
                        ? _OfficialContactCard(
                            contact: contact,
                            accentColor: officialAccent(contact),
                            icon: officialIcon(contact),
                            onTap: () => onTap(contact),
                            onCall: () => onCall(contact),
                          )
                        : _PersonalContactCard(
                            contact: contact,
                            initials: initialsFor(contact.name),
                            onTap: () => onTap(contact),
                            onCall: () => onCall(contact),
                            onMessage: () => onMessage(contact),
                            onDelete: () => onDelete(contact),
                          ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PersonalContactCard extends StatelessWidget {
  const _PersonalContactCard({
    required this.contact,
    required this.initials,
    required this.onTap,
    required this.onCall,
    required this.onMessage,
    required this.onDelete,
  });

  final Contact contact;
  final String initials;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _ContactCardShell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: DashboardDesign.statusBackground(
              context,
              DashboardDesign.deepNavy,
            ),
            child: Text(
              initials,
              style: const TextStyle(
                color: DashboardDesign.deepNavy,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                _InfoLine(
                  icon: Icons.badge_outlined,
                  text: contact.type,
                ),
                const SizedBox(height: 4),
                _InfoLine(
                  icon: Icons.phone_outlined,
                  text: contact.phoneNumber,
                ),
                const SizedBox(height: 10),
                _ContactActionRow(
                  callColor: DashboardDesign.deepNavy,
                  onCall: onCall,
                  onMessage: onMessage,
                  onEdit: onTap,
                  onDelete: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfficialContactCard extends StatelessWidget {
  const _OfficialContactCard({
    required this.contact,
    required this.accentColor,
    required this.icon,
    required this.onTap,
    required this.onCall,
  });

  final Contact contact;
  final Color accentColor;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return _ContactCardShell(
      onTap: onTap,
      leftAccentColor: accentColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: DashboardDesign.statusBackground(context, accentColor),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        contact.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_rounded,
                      color: DashboardDesign.info,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _InfoLine(
                  icon: Icons.apartment_outlined,
                  text: contact.type,
                ),
                const SizedBox(height: 4),
                _InfoLine(
                  icon: Icons.phone_outlined,
                  text: contact.phoneNumber,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: onCall,
                      icon: const Icon(Icons.phone_outlined, size: 18),
                      label: const Text('Call'),
                      style: FilledButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(96, 42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            DashboardDesign.compactRadius,
                          ),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'View contact',
                      onPressed: onTap,
                      icon: const Icon(Icons.visibility_outlined),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCardShell extends StatelessWidget {
  const _ContactCardShell({
    required this.child,
    required this.onTap,
    this.leftAccentColor,
  });

  final Widget child;
  final VoidCallback onTap;
  final Color? leftAccentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DashboardDesign.surface(context),
        borderRadius: BorderRadius.circular(DashboardDesign.radius),
        border: Border.all(color: DashboardDesign.outline(context)),
        boxShadow: DashboardDesign.cardShadow(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DashboardDesign.radius),
          child: Stack(
            children: [
              if (leftAccentColor != null)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: leftAccentColor),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  leftAccentColor == null ? 16 : 21,
                  16,
                  16,
                  16,
                ),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: DashboardDesign.mutedText(context)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DashboardDesign.mutedText(context),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _ContactActionRow extends StatelessWidget {
  const _ContactActionRow({
    required this.callColor,
    required this.onCall,
    required this.onMessage,
    required this.onEdit,
    required this.onDelete,
  });

  final Color callColor;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        FilledButton.icon(
          onPressed: onCall,
          icon: const Icon(Icons.phone_outlined, size: 18),
          label: const Text('Call'),
          style: FilledButton.styleFrom(
            backgroundColor: callColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(92, 42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashboardDesign.compactRadius),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        IconButton(
          tooltip: 'Message contact',
          onPressed: onMessage,
          icon: const Icon(Icons.chat_bubble_outline),
        ),
        IconButton(
          tooltip: 'Edit contact',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Delete contact',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}

class _EmptyContactsCard extends StatelessWidget {
  const _EmptyContactsCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DashboardDesign.surface(context),
        borderRadius: BorderRadius.circular(DashboardDesign.radius),
        border: Border.all(color: DashboardDesign.outline(context)),
        boxShadow: DashboardDesign.cardShadow(context),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: DashboardDesign.statusBackground(
                context,
                DashboardDesign.info,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.contacts_outlined,
              color: DashboardDesign.info,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DashboardDesign.mutedText(context),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _AddContactSheet extends StatefulWidget {
  const _AddContactSheet({
    required this.repository,
    required this.createId,
  });

  final ContactRepository repository;
  final String Function() createId;

  @override
  State<_AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends State<_AddContactSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  String? _selectedType;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    var didCloseSheet = false;

    try {
      final contact = Contact(
        id: widget.createId(),
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        type: _selectedType!,
      );

      await widget.repository.addContact(contact);

      if (!mounted) {
        return;
      }

      didCloseSheet = true;
      Navigator.of(context).pop(ContactValidation.normalizeName(contact.name));
    } on ContactDuplicatePhoneException {
      if (mounted) {
        AppToast.error(
          context,
          title: 'Duplicate contact',
          message: 'A contact with this phone number already exists.',
        );
      }
    } on ContactInvalidOperationException catch (error) {
      if (mounted) {
        AppToast.error(
          context,
          title: 'Invalid contact',
          message: error.message,
        );
      }
    } catch (error) {
      if (mounted) {
        AppToast.errorFromException(
          context,
          title: 'Failed to add contact',
          error: error,
        );
      }
    } finally {
      if (!didCloseSheet && mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Contact',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  enabled: !_isSubmitting,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    final raw = value ?? '';
                    if (!ContactValidation.isValidName(raw)) {
                      return 'Enter at least 2 visible characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneController,
                  enabled: !_isSubmitting,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '09xxxxxxxxx or +63xxxxxxxxxx',
                  ),
                  validator: (value) {
                    final raw = value ?? '';
                    if (!ContactValidation.isValidPhone(raw)) {
                      return 'Use 09xxxxxxxxx or +63xxxxxxxxxx format.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ContactValidation.allowedTypes
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _selectedType = value;
                          });
                        },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Select a contact type.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isSubmitting ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: Text(_isSubmitting ? 'Saving...' : 'Add Contact'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditContactSheet extends StatefulWidget {
  const _EditContactSheet({
    required this.repository,
    required this.existingContact,
  });

  final ContactRepository repository;
  final Contact existingContact;

  @override
  State<_EditContactSheet> createState() => _EditContactSheetState();
}

class _EditContactSheetState extends State<_EditContactSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  late String? _selectedType;
  bool _isSubmitting = false;

  bool get _isReadOnly => widget.existingContact.isPreFilled;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingContact.name);
    _phoneController = TextEditingController(text: widget.existingContact.phoneNumber);
    _selectedType = widget.existingContact.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isReadOnly || _isSubmitting) {
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    var didCloseSheet = false;

    try {
      final updatedContact = Contact(
        id: widget.existingContact.id,
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        type: _selectedType!,
        isPreFilled: widget.existingContact.isPreFilled,
      );

      await widget.repository.updateContact(updatedContact);

      if (!mounted) {
        return;
      }

      didCloseSheet = true;
      Navigator.of(context).pop(ContactValidation.normalizeName(updatedContact.name));
    } on ContactDuplicatePhoneException {
      if (mounted) {
        AppToast.error(
          context,
          title: 'Duplicate contact',
          message: 'A contact with this phone number already exists.',
        );
      }
    } on ContactInvalidOperationException catch (error) {
      if (mounted) {
        AppToast.error(
          context,
          title: 'Invalid contact',
          message: error.message,
        );
      }
    } on ContactNotFoundException catch (error) {
      if (mounted) {
        AppToast.error(
          context,
          title: 'Contact missing',
          message: error.message,
        );
      }
    } catch (error) {
      if (mounted) {
        AppToast.errorFromException(
          context,
          title: 'Failed to update contact',
          error: error,
        );
      }
    } finally {
      if (!didCloseSheet && mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isReadOnly ? 'View Contact' : 'Edit Contact',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_isReadOnly) ...[
                  const SizedBox(height: 6),
                  const Text('This emergency contact is prefilled and read-only.'),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  enabled: !_isSubmitting && !_isReadOnly,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    final raw = value ?? '';
                    if (!ContactValidation.isValidName(raw)) {
                      return 'Enter at least 2 visible characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneController,
                  enabled: !_isSubmitting && !_isReadOnly,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '09xxxxxxxxx or +63xxxxxxxxxx',
                  ),
                  validator: (value) {
                    final raw = value ?? '';
                    if (!ContactValidation.isValidPhone(raw)) {
                      return 'Use 09xxxxxxxxx or +63xxxxxxxxxx format.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ContactValidation.allowedTypes
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: _isSubmitting || _isReadOnly
                      ? null
                      : (value) {
                          setState(() {
                            _selectedType = value;
                          });
                        },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Select a contact type.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isSubmitting ? null : () => Navigator.of(context).pop(),
                        child: Text(_isReadOnly ? 'Close' : 'Cancel'),
                      ),
                    ),
                    if (!_isReadOnly) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: Text(_isSubmitting ? 'Saving...' : 'Save Changes'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
