import 'package:project_bihon/features/preparedness_instruction/repositories/instruction_guide_repository.dart';

class PreparednessService {
  const PreparednessService({
    required InstructionGuideRepository guideRepository,
  }) : _guideRepository = guideRepository;

  final InstructionGuideRepository _guideRepository;

  Map<String, dynamic> buildCompletedGuidesPayload() {
    return {
      'completed_guides': _guideRepository.getCompletedGuideIds(),
    };
  }
}
