import 'package:hive/hive.dart';

part 'instruction_guide.g.dart';

@HiveType(typeId: 15)
class InstructionGuide extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final List<String> contentSteps;

  @HiveField(4)
  final List<String> imageAssetPaths;

  @HiveField(5)
  final bool isRead;

  InstructionGuide({
    required this.id,
    required this.title,
    required this.category,
    required this.contentSteps,
    required this.imageAssetPaths,
    this.isRead = false,
  });

  InstructionGuide copyWith({
    String? id,
    String? title,
    String? category,
    List<String>? contentSteps,
    List<String>? imageAssetPaths,
    bool? isRead,
  }) {
    return InstructionGuide(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      contentSteps: contentSteps ?? this.contentSteps,
      imageAssetPaths: imageAssetPaths ?? this.imageAssetPaths,
      isRead: isRead ?? this.isRead,
    );
  }
}