import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_bihon/features/emergency_contacts/data/models/contact.dart';

class ContactRepository {
  static const String boxName = 'contact_box';
  late Box<Contact> _box;

  static final List<Contact> _seedContacts = [
    Contact(
      id: 'baybay_cdrrmo',
      name: 'Baybay CDRRMO',
      phoneNumber: '09171234567',
      type: 'Barangay Official',
      isPreFilled: true,
    ),
    Contact(
      id: 'baybay_police',
      name: 'Baybay City Police',
      phoneNumber: '09181234567',
      type: 'Rescue Team',
      isPreFilled: true,
    ),
    Contact(
      id: 'baybay_fire',
      name: 'Baybay Fire Station',
      phoneNumber: '09191234567',
      type: 'Rescue Team',
      isPreFilled: true,
    ),
    Contact(
      id: 'baybay_hospital',
      name: 'Baybay District Hospital',
      phoneNumber: '09201234567',
      type: 'Hospital',
      isPreFilled: true,
    ),
  ];

  Future<void> initBox() async {
    _box = await Hive.openBox<Contact>(boxName);
  }

  Future<void> seedIfNeeded() async {
    if (_box.isEmpty) {
      for (final seed in _seedContacts) {
        await _box.put(seed.id, seed);
      }
      return;
    }

    // Idempotent seeding for upgrades: no duplicates by id or normalized number.
    final existingById = _box.values.map((c) => c.id).toSet();
    final existingByPhone = _box.values.map((c) => _normalizePhone(c.phoneNumber)).toSet();

    for (final seed in _seedContacts) {
      final normalized = _normalizePhone(seed.phoneNumber);
      if (existingById.contains(seed.id) || existingByPhone.contains(normalized)) {
        continue;
      }
      await _box.put(seed.id, seed);
    }
  }

  List<Contact> getAllContacts() {
    return _box.values.toList();
  }

  List<Contact> getContactsByTypes(List<String> types) {
    final allowed = types.toSet();
    return _box.values.where((contact) => allowed.contains(contact.type)).toList();
  }

  ValueListenable<Box<Contact>> getContactsListenable() {
    return _box.listenable();
  }

  Future<void> addContact(Contact contact) async {
    final normalized = _normalizePhone(contact.phoneNumber);
    final duplicate = _box.values.any(
      (existing) => _normalizePhone(existing.phoneNumber) == normalized,
    );
    if (duplicate) {
      throw StateError('A contact with this phone number already exists.');
    }
    await _box.put(contact.id, contact);
  }

  Future<void> updateContact(Contact contact) async {
    final normalized = _normalizePhone(contact.phoneNumber);
    final duplicate = _box.values.any(
      (existing) => existing.id != contact.id && _normalizePhone(existing.phoneNumber) == normalized,
    );
    if (duplicate) {
      throw StateError('A contact with this phone number already exists.');
    }
    await _box.put(contact.id, contact);
  }

  Future<void> deleteContact(String id) async {
    final existing = _box.get(id);
    if (existing == null) {
      return;
    }
    if (existing.isPreFilled) {
      throw StateError('Pre-filled emergency contacts cannot be deleted.');
    }
    await _box.delete(id);
  }

  Future<void> closeBox() async {
    await _box.close();
  }

  String _normalizePhone(String value) {
    return value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }
}
