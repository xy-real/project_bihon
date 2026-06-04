import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/crisync_bottom_navigation.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/dashboard_design.dart';
import 'package:project_bihon/features/emergency_contacts/data/models/contact.dart';
import 'package:project_bihon/features/emergency_contacts/data/repositories/contact_repository.dart';
import 'package:project_bihon/features/emergency_contacts/domain/contact_validation.dart';
import 'package:project_bihon/main.dart' show getContactRepository;
import 'package:project_bihon/shared/widgets/app_toast.dart';
import 'package:url_launcher/url_launcher.dart';

enum _SafetyStatus { safe, help }

class SafetyStatusPage extends StatefulWidget {
  const SafetyStatusPage({super.key});

  @override
  State<SafetyStatusPage> createState() => _SafetyStatusPageState();
}

class _SafetyStatusPageState extends State<SafetyStatusPage> {
  static const String _messageSuffix = ' - Sent via Crisync Offline Alert.';

  static const List<String> _allowedRecipientTypes = [
    'Family',
    'Barangay Official',
  ];

  static const Map<String, String> _messageTemplates = {
    'I am safe': 'I am safe and currently at my location. No assistance needed.',
    'Need help': 'I need immediate assistance. Please contact me as soon as possible.',
    'Evacuating': 'I am evacuating to the nearest center. I will update you when I arrive.',
  };

  late final ContactRepository _repository;
  late final TextEditingController _messageController;
  final Set<String> _selectedRecipientIds = <String>{};

  _SafetyStatus _selectedStatus = _SafetyStatus.safe;
  String _selectedPreset = 'I am safe';

  @override
  void initState() {
    super.initState();
    _repository = getContactRepository();
    _messageController = TextEditingController(
      text: _messageTemplates[_selectedPreset],
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  List<Contact> _sortContacts(List<Contact> contacts) {
    final sorted = [...contacts];
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
  }

  void _setStatus(_SafetyStatus status) {
    final preset = status == _SafetyStatus.safe ? 'I am safe' : 'Need help';
    setState(() {
      _selectedStatus = status;
      _selectedPreset = preset;
      _messageController.text = _messageTemplates[preset]!;
    });
  }

  void _setPreset(String preset) {
    setState(() {
      _selectedPreset = preset;
      _messageController.text = _messageTemplates[preset]!;
      if (preset == 'Need help') {
        _selectedStatus = _SafetyStatus.help;
      } else if (preset == 'I am safe') {
        _selectedStatus = _SafetyStatus.safe;
      }
    });
  }

  void _toggleRecipient(Contact contact, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedRecipientIds.add(contact.id);
      } else {
        _selectedRecipientIds.remove(contact.id);
      }
    });
  }

  void _toggleGroup(List<Contact> contacts, {required bool selectAll}) {
    setState(() {
      for (final contact in contacts) {
        if (selectAll) {
          _selectedRecipientIds.add(contact.id);
        } else {
          _selectedRecipientIds.remove(contact.id);
        }
      }
    });
  }

  void _toggleAllRecipients(List<Contact> contacts) {
    final selectableIds = contacts.map((contact) => contact.id).toSet();
    final allSelected = selectableIds.isNotEmpty &&
        selectableIds.every(_selectedRecipientIds.contains);

    setState(() {
      if (allSelected) {
        _selectedRecipientIds.removeAll(selectableIds);
      } else {
        _selectedRecipientIds.addAll(selectableIds);
      }
    });
  }

  Future<void> _handleSend() async {
    final message = _messageController.text.trim();
    if (_selectedRecipientIds.isEmpty || message.isEmpty) {
      AppToast.error(
        context,
        title: 'Broadcast incomplete',
        message: 'Select at least one recipient and enter a message.',
      );
      return;
    }

    final selectedContacts = _repository
        .getAllContacts()
        .where((contact) => _selectedRecipientIds.contains(contact.id))
        .toList();

    if (selectedContacts.isEmpty) {
      AppToast.error(
        context,
        title: 'No recipients selected',
        message: 'Selected contacts are no longer available. Please select again.',
      );
      return;
    }

    final smsUri = _buildSmsComposeUri(selectedContacts, message);

    try {
      final canLaunch = await canLaunchUrl(smsUri);
      if (!canLaunch) {
        if (mounted) {
          AppToast.error(
            context,
            title: 'Launcher unavailable',
            message: 'No SMS app is available to open compose.',
          );
        }
        return;
      }

      final launched = await launchUrl(
        smsUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        AppToast.error(
          context,
          title: 'SMS compose canceled',
          message: 'SMS compose was not opened. Please try again.',
        );
      }
    } catch (error) {
      if (mounted) {
        AppToast.errorFromException(
          context,
          title: 'Failed to launch SMS compose',
          error: error,
        );
      }
    }
  }

  Uri _buildSmsComposeUri(List<Contact> recipients, String message) {
    final joinedRecipients = recipients
        .map((contact) => ContactValidation.normalizePhone(contact.phoneNumber))
        .join(',');
    final finalMessage = '$message$_messageSuffix';

    return Uri.parse(
      'sms:$joinedRecipients?body=${Uri.encodeComponent(finalMessage)}',
    );
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
      4 => '/contacts',
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

  Widget _buildLogoAvatar() {
    return CircleAvatar(
      radius: 18,
      backgroundColor: DashboardDesign.deepNavy,
      child: ClipOval(
        child: Image.asset(
          'assets/logo.png',
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 20,
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: DashboardDesign.statusBackground(context, DashboardDesign.info),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.campaign_outlined,
                color: DashboardDesign.info,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Status Broadcast',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: DashboardDesign.info,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Are you safe?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Quickly broadcast your current status to your trusted network and local officials.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DashboardDesign.mutedText(context),
                height: 1.4,
              ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    final accent = _selectedStatus == _SafetyStatus.safe
        ? DashboardDesign.success
        : DashboardDesign.danger;

    return _BroadcastCard(
      leftAccentColor: accent,
      child: Column(
        children: [
          _StatusOptionTile(
            title: 'I am safe',
            subtitle: 'Positive check-in',
            icon: Icons.check_circle_outline,
            color: DashboardDesign.success,
            selected: _selectedStatus == _SafetyStatus.safe,
            onTap: () => _setStatus(_SafetyStatus.safe),
          ),
          const SizedBox(height: 12),
          _StatusOptionTile(
            title: 'Need help',
            subtitle: 'Request assistance',
            icon: Icons.warning_amber_rounded,
            color: DashboardDesign.danger,
            selected: _selectedStatus == _SafetyStatus.help,
            onTap: () => _setStatus(_SafetyStatus.help),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientsSection({
    required List<Contact> allRecipients,
    required List<Contact> familyContacts,
    required List<Contact> barangayContacts,
  }) {
    final selectableIds = allRecipients.map((contact) => contact.id).toSet();
    final allSelected = selectableIds.isNotEmpty &&
        selectableIds.every(_selectedRecipientIds.contains);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recipients',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            TextButton(
              onPressed: allRecipients.isEmpty
                  ? null
                  : () => _toggleAllRecipients(allRecipients),
              child: Text(allSelected ? 'Deselect All' : 'Select All'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 680 ? 2 : 1;
            const gap = DashboardDesign.gap;
            final width =
                (constraints.maxWidth - (gap * (columns - 1))) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(
                  width: width,
                  child: _RecipientGroupCard(
                    title: 'Family Network',
                    subtitle: '${familyContacts.length} ${familyContacts.length == 1 ? 'Contact' : 'Contacts'}',
                    icon: Icons.family_restroom_outlined,
                    contacts: familyContacts,
                    selectedIds: _selectedRecipientIds,
                    onToggle: _toggleRecipient,
                    onToggleGroup: _toggleGroup,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _RecipientGroupCard(
                    title: 'Local Officials',
                    subtitle: barangayContacts.isEmpty
                        ? 'No contacts'
                        : '${barangayContacts.length} Command Center ${barangayContacts.length == 1 ? 'Contact' : 'Contacts'}',
                    icon: Icons.local_police_outlined,
                    contacts: barangayContacts,
                    selectedIds: _selectedRecipientIds,
                    onToggle: _toggleRecipient,
                    onToggleGroup: _toggleGroup,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMessageSection() {
    return _BroadcastCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Message',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final preset in _messageTemplates.keys) ...[
                  _PresetChip(
                    label: preset,
                    selected: _selectedPreset == preset,
                    onTap: () => _setPreset(preset),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _messageController,
            minLines: 4,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              filled: true,
              fillColor: DashboardDesign.surface(context),
              hintText: 'Enter your status update',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DashboardDesign.radius),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DashboardDesign.radius),
                borderSide: BorderSide(color: DashboardDesign.outline(context)),
              ),
            ),
            onChanged: (_) {
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton(int selectedCount) {
    final canSend = selectedCount > 0 && _messageController.text.trim().isNotEmpty;

    return Column(
      children: [
        FilledButton.icon(
          onPressed: canSend ? _handleSend : null,
          icon: const Icon(Icons.send_outlined),
          label: Text('SEND via SMS ($selectedCount)'),
          style: FilledButton.styleFrom(
            backgroundColor: DashboardDesign.deepNavy,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                DashboardDesign.deepNavy.withValues(alpha: 0.36),
            disabledForegroundColor: Colors.white70,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashboardDesign.radius),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 16,
              color: DashboardDesign.mutedText(context),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Opens your native SMS app before sending',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DashboardDesign.mutedText(context),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLogoAvatar(),
            const SizedBox(width: 10),
            const Text(
              'Crisync',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
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
        selectedIndex: null,
        onDestinationSelected: _openTab,
      ),
      body: ValueListenableBuilder<Box<Contact>>(
        valueListenable: _repository.getContactsListenable(),
        builder: (context, box, _) {
          final contacts = box.values
              .where((contact) => _allowedRecipientTypes.contains(contact.type))
              .toList();

          final familyContacts = _sortContacts(
            contacts.where((contact) => contact.type == 'Family').toList(),
          );
          final barangayContacts = _sortContacts(
            contacts
                .where((contact) => contact.type == 'Barangay Official')
                .toList(),
          );

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
                  constraints: const BoxConstraints(maxWidth: 768),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeroHeader(),
                      const SizedBox(height: DashboardDesign.sectionGap),
                      _buildStatusCard(),
                      const SizedBox(height: DashboardDesign.sectionGap),
                      _buildRecipientsSection(
                        allRecipients: contacts,
                        familyContacts: familyContacts,
                        barangayContacts: barangayContacts,
                      ),
                      const SizedBox(height: DashboardDesign.sectionGap),
                      _buildMessageSection(),
                      const SizedBox(height: DashboardDesign.gap),
                      _buildSendButton(_selectedRecipientIds.length),
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

class _BroadcastCard extends StatelessWidget {
  const _BroadcastCard({
    required this.child,
    this.leftAccentColor,
  });

  final Widget child;
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
    );
  }
}

class _StatusOptionTile extends StatelessWidget {
  const _StatusOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DashboardDesign.compactRadius),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? DashboardDesign.statusBackground(context, color)
                : DashboardDesign.surface(context),
            borderRadius: BorderRadius.circular(DashboardDesign.compactRadius),
            border: Border.all(
              color: selected ? color : DashboardDesign.outline(context),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DashboardDesign.mutedText(context),
                          ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: color, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipientGroupCard extends StatelessWidget {
  const _RecipientGroupCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.contacts,
    required this.selectedIds,
    required this.onToggle,
    required this.onToggleGroup,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Contact> contacts;
  final Set<String> selectedIds;
  final void Function(Contact contact, bool isSelected) onToggle;
  final void Function(List<Contact> contacts, {required bool selectAll})
      onToggleGroup;

  @override
  Widget build(BuildContext context) {
    final hasContacts = contacts.isNotEmpty;
    final selectedCount =
        contacts.where((contact) => selectedIds.contains(contact.id)).length;
    final allSelected = hasContacts && selectedCount == contacts.length;
    final isPartial = selectedCount > 0 && selectedCount < contacts.length;

    return _BroadcastCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                tristate: true,
                value: isPartial ? null : allSelected,
                onChanged: hasContacts
                    ? (value) {
                        onToggleGroup(contacts, selectAll: value ?? false);
                      }
                    : null,
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: DashboardDesign.statusBackground(
                    context,
                    DashboardDesign.info,
                  ),
                  borderRadius:
                      BorderRadius.circular(DashboardDesign.compactRadius),
                ),
                child: Icon(icon, color: DashboardDesign.info, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DashboardDesign.mutedText(context),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!hasContacts) ...[
            const SizedBox(height: 10),
            Text(
              'No contacts available.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DashboardDesign.mutedText(context),
                  ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            for (final contact in contacts)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: selectedIds.contains(contact.id),
                title: Text(
                  contact.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  contact.phoneNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onChanged: (isChecked) {
                  onToggle(contact, isChecked ?? false);
                },
              ),
          ],
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: DashboardDesign.info,
      backgroundColor: DashboardDesign.surface(context),
      side: BorderSide(
        color: selected ? DashboardDesign.info : DashboardDesign.outline(context),
      ),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
      showCheckmark: false,
    );
  }
}
