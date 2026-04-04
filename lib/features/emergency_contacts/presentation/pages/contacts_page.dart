import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

  Future<void> _callContact(Contact contact) async {
    final normalizedPhone = ContactValidation.normalizePhone(contact.phoneNumber);
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

  Widget _buildContactTile(Contact contact) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => _showEditContactModal(contact),
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Call contact',
            onPressed: () => _callContact(contact),
            icon: const Icon(Icons.phone_outlined),
          ),
          IconButton(
            tooltip: contact.isPreFilled ? 'View contact' : 'Edit contact',
            onPressed: () => _showEditContactModal(contact),
            icon: Icon(contact.isPreFilled ? Icons.visibility_outlined : Icons.edit_outlined),
          ),
          if (!contact.isPreFilled)
            IconButton(
              tooltip: 'Delete contact',
              onPressed: () => _deleteContact(contact),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
    );
  }

  Future<void> _showEditContactModal(Contact existingContact) async {
    final updatedContactName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
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
      isDismissible: false,
      enableDrag: false,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddContactModal,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Contact'),
      ),
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
