import 'package:project_bihon/features/supply_tracker/data/models/supply_item.dart';
import 'package:project_bihon/shared/models/household.dart';

const String _unknownHouseholdSize = 'Not provided';
const String _unknownRiskClassification = 'unknown';

final RegExp _phoneLikeValue = RegExp(
  r'\+?\d(?:[\s().-]*\d){6,}',
);

final RegExp _coordinatePair = RegExp(
  r'-?\d{1,3}\.\d{3,}\s*,\s*-?\d{1,3}\.\d{3,}',
);

final RegExp _whitespace = RegExp(r'\s+');

String buildSanitizedPrompt(
  Household household,
  List<SupplyItem> supplies,
) {
  final validSupplies = supplies.where((item) => !item.isExpired).toList();

  final inventory = validSupplies
      .map(
        (item) =>
            '${item.quantity}x ${_sanitize(item.name)} '
            '(${_sanitize(item.category)})',
      )
      .join(', ');

  final inventorySummary =
      inventory.isEmpty ? 'No valid supplies.' : inventory;

  final sanitizedRisk = _sanitize(household.risk_classification);
  final riskClassification =
      sanitizedRisk.isEmpty ? _unknownRiskClassification : sanitizedRisk;

  return '''
You are a disaster preparedness expert advising a household in Baybay City, Leyte, Philippines.

Household Details:
- Size: $_unknownHouseholdSize
- Location Risk: $riskClassification

Current Unexpired Inventory:
$inventorySummary

Analyze this inventory against standard 3-day survival requirements for this household size and risk profile.

Respond strictly in JSON format with this structure and no additional text:
{
  "score": <integer from 0 to 100>,
  "status": "<Needs Improvement | Prepared | Highly Prepared>",
  "missing_items": ["<item 1>", "<item 2>"],
  "advice": "<short localized advice>"
}''';
}

String _sanitize(String value) {
  return value
      .replaceAll(_coordinatePair, '[redacted]')
      .replaceAll(_phoneLikeValue, '[redacted]')
      .replaceAll(_whitespace, ' ')
      .trim();
}