import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_bihon/features/emergency_contacts/data/models/contact.dart';
import 'package:project_bihon/features/emergency_contacts/data/repositories/contact_repository.dart';
import 'package:project_bihon/features/emergency_contacts/domain/contact_validation.dart';
import 'package:project_bihon/main.dart' show getContactRepository;
import 'package:project_bihon/shared/widgets/app_toast.dart';
import 'package:url_launcher/url_launcher.dart';

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

  static const List<String> _messageTemplates = [
    "I'm safe and sheltering in place.",
    'I am evacuating to the nearest center.',
    'I need immediate assistance.',
  ];

  late final ContactRepository _repository;
  final Set<String> _selectedRecipientIds = <String>{};
  String? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _repository = getContactRepository();
    _selectedTemplate = _messageTemplates.first;
  }

  List<Contact> _sortContacts(List<Contact> contacts) {
    final sorted = [...contacts];
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
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

  void _toggleAll(List<Contact> contacts, {required bool selectAll}) {
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

  Future<void> _handleSend() async {
    if (_selectedRecipientIds.isEmpty || _selectedTemplate == null) {
      AppToast.error(
        context,
        title: 'No recipients selected',
        message: 'Select at least one contact before sending.',
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

    final smsUri = _buildSmsComposeUri(
      selectedContacts,
      _selectedTemplate!,
    );

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
        return;
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

  Uri _buildSmsComposeUri(List<Contact> recipients, String templateMessage) {
    final joinedRecipients = recipients
        .map((contact) => ContactValidation.normalizePhone(contact.phoneNumber))
        .join(',');
    final finalMessage = '$templateMessage$_messageSuffix';

    return Uri.parse(
      'sms:$joinedRecipients?body=${Uri.encodeComponent(finalMessage)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Status'),
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
            contacts.where((contact) => contact.type == 'Barangay Official').toList(),
          );

          final selectedCount = _selectedRecipientIds.length;
          final canSend = selectedCount > 0 && _selectedTemplate != null;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    Text(
                      'Recipients',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select Family and Barangay Official contacts.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    _RecipientSection(
                      title: 'Family',
                      contacts: familyContacts,
                      selectedIds: _selectedRecipientIds,
                      onToggle: _toggleRecipient,
                      onSelectAll: () => _toggleAll(familyContacts, selectAll: true),
                      onClearAll: () => _toggleAll(familyContacts, selectAll: false),
                    ),
                    const SizedBox(height: 12),
                    _RecipientSection(
                      title: 'Barangay Official',
                      contacts: barangayContacts,
                      selectedIds: _selectedRecipientIds,
                      onToggle: _toggleRecipient,
                      onSelectAll: () => _toggleAll(barangayContacts, selectAll: true),
                      onClearAll: () => _toggleAll(barangayContacts, selectAll: false),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Message Template',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTemplate,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Template',
                      ),
                      items: _messageTemplates
                          .map(
                            (template) => DropdownMenuItem<String>(
                              value: template,
                              child: Text(template),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTemplate = value;
                        });
                      },
                    ),
                    const SizedBox(height: 96),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: FilledButton.icon(
                    onPressed: canSend ? _handleSend : null,
                    icon: const Icon(Icons.sms_outlined),
                    label: Text('Send Safety Status ($selectedCount)'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RecipientSection extends StatelessWidget {
  const _RecipientSection({
    required this.title,
    required this.contacts,
    required this.selectedIds,
    required this.onToggle,
    required this.onSelectAll,
    required this.onClearAll,
  });

  final String title;
  final List<Contact> contacts;
  final Set<String> selectedIds;
  final void Function(Contact contact, bool isSelected) onToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final hasContacts = contacts.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (hasContacts)
                  TextButton(
                    onPressed: onSelectAll,
                    child: const Text('Select all'),
                  ),
                if (hasContacts)
                  TextButton(
                    onPressed: onClearAll,
                    child: const Text('Clear'),
                  ),
              ],
            ),
            if (!hasContacts)
              const Padding(
                padding: EdgeInsets.only(top: 4, bottom: 8),
                child: Text('No contacts available.'),
              ),
            for (final contact in contacts)
              CheckboxListTile(
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                value: selectedIds.contains(contact.id),
                title: Text(contact.name),
                subtitle: Text(contact.phoneNumber),
                onChanged: (isChecked) {
                  onToggle(contact, isChecked ?? false);
                },
              ),
          ],
        ),
      ),
    );
  }
}
