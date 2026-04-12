# Project Bihon

Project Bihon is an Android application designed to help families prepare for and respond to natural disasters, with a primary focus on typhoons. The app serves as a trusted companion, providing essential guidance, checklists, and resources to ensure families are ready when disaster strikes. It includes an inventory tracker to help families monitor and manage their emergency supplies and preparedness items.

| Internal Release Code | Date Released |
|:-----------------|:--------------|
| PB.010.002       | 2026-04-13    |
| PB.010.001       | 2026-04-05    |
| PB.010.000       | 2026-03-01    |

## PB.010.002 Release Notes
### Implemented Features
- Location-Specific Alert Prioritization
	- Tailors warning prioritization based on household location risk profile
	- Fully implemented through 5 development steps and validated for production
- Data Models and Normalization
	- Added household location risk classification support using canonical values:
		coastal, flood_prone, landslide_prone, unknown
	- Added cached alert risk-tag mapping for household-targeted classification
	- Added normalization utilities for risk tags (trim, lowercase, underscore normalization, deduplication)
- Threat Classification and Sorting
	- Added ThreatBand classification (direct, general)
	- Added pure classification and deterministic sorting logic
	- Ordering now enforces:
		1. Direct threats first
		2. Severity priority (high to medium to low)
		3. Newest published alerts first
		4. General advisories after direct threats
- Household Profile Experience
	- Added local household persistence with validation
	- Added risk-classification picker with user-friendly labels and feedback
	- Added guided household onboarding flow with skip option
	- Added profile settings support for post-onboarding updates
- Alert Card Variants and Visual Priority
	- Added dedicated direct-threat alert card with high-contrast warning styling
	- Added general-advisory alert card for standard notices
	- Added deterministic alert card factory for consistent rendering
	- Added adaptive styling support for light and dark mode
- Alerts Screen Integration
	- Added local alerts repository for render-path cache reads
	- Added alerts list page integration for classification and deterministic sorting
	- Added reactive refresh behavior through Hive listeners
	- Added empty-state handling with safe fallback behavior

### Key Guarantees
- Offline resilience
	- Safe fallback behavior when household profile is null, unknown, or empty
	- Safe fallback behavior when risk tags are missing or empty
	- Empty cached alerts render an empty state without errors
	- Mounted checks prevent setState-after-dispose issues
- Zero network dependency in alert rendering
	- Alerts and household reads are local-only in render path
	- Classification and sorting functions are pure and deterministic
	- Fully usable in airplane mode

### Testing and Validation
- Added/verified broad unit and widget coverage, including new integration scenarios
- Verified dynamic reprioritization when household risk profile changes
- Verified fallback behavior for empty and unknown data paths
- Verified stable behavior in offline and cache-only conditions
- No compilation errors reported

### Architecture Additions
- Data layer
	- Household and cached alert model support with Hive adapters
	- Local repositories for household profile and cached alerts
- Domain layer
	- Pure threat-classification logic
	- Risk-tag normalization utilities
- Presentation layer
	- Alerts list screen and settings/onboarding profile screens
	- Direct/general alert card variants and classification picker

### Compatibility
- Breaking changes: none (feature is additive)

## PB.010.001 Release Notes
### Implemented Features
- Emergency Supply Tracker
	- Add, edit, and remove supply items
	- Track quantity, category, and expiration date
	- Use either card view or table view based on preference
	- Get local reminders for items nearing expiration
- Emergency Contacts Manager
	- Add and update emergency contacts with validation
	- View contacts grouped by type for faster access
	- Use prefilled Baybay emergency contacts with safety protection rules
	- Start direct calls from the app using the phone dialer
- SMS Safety Status
	- Select recipients from Family and Barangay Official groups
	- Choose from predefined safety status templates
	- Open native SMS compose screen with recipients and message prefilled
	- Show clear feedback when sending cannot proceed

### App Integration
- Integrated Contacts and Safety Status into the main app flow
- Preserved existing splash and home experience
- Added Android SMS intent query support required for compose flow
- Kept release-safe permission policy (no direct SMS or phone-state permissions)

### Quality and Stability Updates
- Verified offline persistence and seeded-contact consistency
- Verified validation, deduplication, and protected-contact behavior
- Stabilized contact modal behavior and improved interaction reliability
- Refined contact list spacing and action visibility for better usability

### Known Issues
- SMS sending depends on the device's installed SMS app, and behavior may vary by device brand.
- The app currently opens the SMS compose screen, but it does not track final delivery status.
- PAGASA Global Alerts and Evacuation Centers sync are documented and planned, but not part of this release.
- Main navigation in this branch is route-based from the home app bar while bottom navigation is handled separately.

## PB.010.000 Release Notes
- Setup repository README with tracking table and documentation
- Initialize new Flutter project

### Important Links:
- Design Specs: https://github.com/xy-real/bihon-docportal
