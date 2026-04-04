import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_bihon/features/emergency_contacts/data/models/contact.dart';
import 'package:project_bihon/features/emergency_contacts/data/repositories/contact_repository_exceptions.dart';
import 'package:project_bihon/features/emergency_contacts/domain/contact_validation.dart';

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
    final existingByPhone = _box.values
      .map((c) => ContactValidation.normalizePhone(c.phoneNumber))
      .toSet();

    for (final seed in _seedContacts) {
      final normalized = ContactValidation.normalizePhone(seed.phoneNumber);
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
    if (contact.id.trim().isEmpty) {
      throw const ContactInvalidOperationException('Contact id cannot be empty.');
    }

    final normalizedName = ContactValidation.normalizeName(contact.name);
    if (!ContactValidation.isValidName(normalizedName)) {
      throw const ContactInvalidOperationException(
        'Name is required and must have at least 2 visible characters.',
      );
    }

    final normalizedPhone = ContactValidation.normalizePhone(contact.phoneNumber);
    if (!ContactValidation.isValidPhone(normalizedPhone)) {
      throw const ContactInvalidOperationException(
        'Phone number must be in 09xxxxxxxxx or +63xxxxxxxxxx format.',
      );
    }

    final normalizedType = contact.type.trim();
    if (!ContactValidation.isAllowedType(normalizedType)) {
      throw const ContactInvalidOperationException(
        'Contact type is invalid.',
      );
    }

    final duplicate = _box.values.any(
      (existing) =>
          ContactValidation.normalizePhone(existing.phoneNumber) ==
          normalizedPhone,
    );
    if (duplicate) {
      throw const ContactDuplicatePhoneException();
    }

    contact
      ..name = normalizedName
      ..phoneNumber = normalizedPhone
      ..type = normalizedType;

    await _box.put(contact.id, contact);
  }

  Future<void> updateContact(Contact contact) async {
    if (contact.id.trim().isEmpty) {
      throw const ContactInvalidOperationException('Contact id cannot be empty.');
    }

    if (!_box.containsKey(contact.id)) {
      throw ContactNotFoundException(contact.id);
    }

    final normalizedName = ContactValidation.normalizeName(contact.name);
    if (!ContactValidation.isValidName(normalizedName)) {
      throw const ContactInvalidOperationException(
        'Name is required and must have at least 2 visible characters.',
      );
    }

    final normalizedPhone = ContactValidation.normalizePhone(contact.phoneNumber);
    if (!ContactValidation.isValidPhone(normalizedPhone)) {
      throw const ContactInvalidOperationException(
        'Phone number must be in 09xxxxxxxxx or +63xxxxxxxxxx format.',
      );
    }

    final normalizedType = contact.type.trim();
    if (!ContactValidation.isAllowedType(normalizedType)) {
      throw const ContactInvalidOperationException(
        'Contact type is invalid.',
      );
    }

    final duplicate = _box.values.any(
      (existing) =>
          existing.id != contact.id &&
          ContactValidation.normalizePhone(existing.phoneNumber) ==
              normalizedPhone,
    );
    if (duplicate) {
      throw const ContactDuplicatePhoneException();
    }

    contact
      ..name = normalizedName
      ..phoneNumber = normalizedPhone
      ..type = normalizedType;

    await _box.put(contact.id, contact);
  }

  Future<void> deleteContact(String id) async {
    if (id.trim().isEmpty) {
      throw const ContactInvalidOperationException('Contact id cannot be empty.');
    }

    final existing = _box.get(id);
    if (existing == null) {
      throw ContactNotFoundException(id);
    }
    if (existing.isPreFilled) {
      throw const ContactPrefilledDeleteException();
    }
    await _box.delete(id);
  }

  Future<void> closeBox() async {
    await _box.close();
  }
}
