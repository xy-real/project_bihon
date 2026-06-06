import 'package:project_bihon/features/preparedness_instruction/models/instruction_guide.dart';

List<InstructionGuide> getSeedGuides() {
  return [
    InstructionGuide(
      id: 'typhoon_01',
      title: 'Before a Typhoon',
      category: 'Typhoon',
      contentSteps: const [
        'Check weather advisories from trusted local authorities and identify your safest room at home.',
        'Charge phones, power banks, radios, and lights while electricity is still available.',
        'Move important documents, medicines, and emergency supplies into a waterproof container.',
      ],
      imageAssetPaths: const [
        'assets/images/guides/typhoon_1.png',
        'assets/images/guides/typhoon_2.png',
        'assets/images/guides/typhoon_3.png',
      ],
    ),
    InstructionGuide(
      id: 'flood_01',
      title: 'Flood Safety Basics',
      category: 'Flood',
      contentSteps: const [
        'Place valuables and electrical items above likely flood height before water enters the home.',
        'Avoid walking or driving through floodwater because depth and current can change quickly.',
        'Move to higher ground early and bring only essential supplies if evacuation becomes necessary.',
      ],
      imageAssetPaths: const [
        'assets/images/guides/flood_1.png',
        'assets/images/guides/flood_2.png',
        'assets/images/guides/flood_1.png',
      ],
    ),
    InstructionGuide(
      id: 'earthquake_01',
      title: 'Earthquake Response',
      category: 'Earthquake',
      contentSteps: const [
        'Drop, cover, and hold under sturdy furniture or against an interior wall.',
        'Stay away from windows, shelves, hanging objects, and damaged electrical lines.',
        'After shaking stops, check for injuries and move calmly to an open safe area.',
      ],
      imageAssetPaths: const [
        'assets/images/guides/drop-cover-hold.png',
        'assets/images/guides/windows.png',
        'assets/images/guides/buildings.png',
      ],
    ),
    InstructionGuide(
      id: 'go_bag_01',
      title: 'Prepare a Go Bag',
      category: 'Family Readiness',
      contentSteps: const [
        'Pack drinking water, ready-to-eat food, medicines, first aid supplies, flashlight, and whistle.',
        'Add copies of IDs, emergency contact numbers, cash, and basic hygiene items.',
        'Review the bag every month and replace expired food, water, batteries, and medicines.',
      ],
      imageAssetPaths: const [
        'assets/images/guides/go_bag_1.png',
        'assets/images/guides/go_bag_2.png',
        'assets/images/guides/go_bag_1.png',
      ],
    ),
  ];
}
