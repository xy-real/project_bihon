import 'package:hive/hive.dart';

part 'contact.g.dart';

@HiveType(typeId: 1)
class Contact extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String phoneNumber;

  @HiveField(3)
  String type;

  @HiveField(4)
  bool isPreFilled;

  Contact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.type,
    this.isPreFilled = false,
  });
}
