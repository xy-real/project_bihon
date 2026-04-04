import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_bihon/features/emergency_contacts/data/models/contact.dart';
import 'package:project_bihon/features/emergency_contacts/data/repositories/contact_repository.dart';
import 'package:project_bihon/features/emergency_contacts/domain/contact_validation.dart';
import 'package:project_bihon/main.dart' show getContactRepository;

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
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
      return name.contains(query) || phone.contains(query) || type.contains(query);
    }).toList();
  }

  Map<String, List<Contact>> _groupByType(List<Contact> contacts) {
    final grouped = <String, List<Contact>>{};
    for (final contact in contacts) {
      grouped.putIfAbsent(contact.type, () => []).add(contact);
    }

    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    return grouped;
  }

  List<String> _orderedTypes(Map<String, List<Contact>> grouped) {
    final knownOrder = ContactValidation.allowedTypes;
    final inKnownOrder = knownOrder.where(grouped.containsKey).toList();
    final unknown = grouped.keys.where((type) => !knownOrder.contains(type)).toList()..sort();
    return [...inKnownOrder, ...unknown];
  }

  Widget _buildContactTile(Contact contact) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Expanded(child: Text(contact.name)),
          if (contact.isPreFilled)
            const Icon(
              Icons.lock_outline,
              size: 16,
              color: Colors.grey,
            ),
        ],
      ),
      subtitle: Text(contact.phoneNumber),
      leading: const Icon(Icons.person_outline),
      trailing: const Icon(Icons.phone_outlined),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      body: ValueListenableBuilder<Box<Contact>>(
        valueListenable: _repository.getContactsListenable(),
        builder: (context, box, _) {
          final allContacts = box.values.toList();
          final filtered = _applySearch(allContacts);
          final grouped = _groupByType(filtered);
          final types = _orderedTypes(grouped);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, number, or type',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _query = '';
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _query = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: types.isEmpty
                    ? const Center(child: Text('No contacts found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: types.length,
                        itemBuilder: (context, index) {
                          final type = types[index];
                          final contacts = grouped[type] ?? const <Contact>[];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  for (final contact in contacts) _buildContactTile(contact),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
