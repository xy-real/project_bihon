import 'package:project_bihon/features/emergency_contacts/data/models/contact.dart';

class BaybayEmergencyContactSeeds {
  const BaybayEmergencyContactSeeds._();

  static List<Contact> build() {
    return [
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
  }
}
