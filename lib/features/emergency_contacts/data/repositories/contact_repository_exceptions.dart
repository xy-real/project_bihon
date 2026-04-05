class ContactRepositoryException implements Exception {
  final String message;

  const ContactRepositoryException(this.message);

  @override
  String toString() => message;
}

class ContactDuplicatePhoneException extends ContactRepositoryException {
  const ContactDuplicatePhoneException()
      : super('A contact with this phone number already exists.');
}

class ContactPrefilledDeleteException extends ContactRepositoryException {
  const ContactPrefilledDeleteException()
      : super('Pre-filled emergency contacts cannot be deleted.');
}

class ContactNotFoundException extends ContactRepositoryException {
  const ContactNotFoundException(String id)
      : super('Contact not found for id: $id');
}

class ContactInvalidOperationException extends ContactRepositoryException {
  const ContactInvalidOperationException(super.message);
}
