# Project Bihon

Project Bihon is an Android application designed to help families prepare for and respond to natural disasters, with a primary focus on typhoons. The app serves as a trusted companion, providing essential guidance, checklists, and resources to ensure families are ready when disaster strikes. It includes an inventory tracker to help families monitor and manage their emergency supplies and preparedness items.

| Internal Release Code | Date Released |
|:-----------------|:--------------|
| PB.010.001       | 2026-04-05    |
| PB.010.000       | 2026-03-01    |

## PB.010.001 Release Notes
- Added Emergency Contacts Manager (offline-first local storage)
	- Grouped contacts dashboard by type
	- Add/Edit contact flows with validation and duplicate prevention
	- Prefilled Baybay emergency contacts with protection rules
	- Direct dial action via native phone launcher (`tel:`)
- Added SMS Safety Status flow
	- Recipient selection for Family and Barangay Official groups
	- Predefined safety message templates
	- Native SMS compose integration via `sms:` launcher
	- User feedback for no recipient, unavailable launcher, canceled compose, and launch errors
- Improved app integration and navigation entry points
	- Contacts and Safety Status pages are accessible from the main app flow
	- Existing splash and home behavior retained
- Implemented Android SMS intent visibility configuration for compose flow
	- Added `SENDTO` + `sms` query support in Android manifest
	- Kept release-safe policy with no dangerous SMS permissions (`SEND_SMS`, `READ_PHONE_STATE`)
- Completed feature QA checks for contacts and SMS safety flow on physical device
	- Offline persistence and seed idempotency verified
	- Validation, dedupe, and prefilled delete guard behavior verified

- Internal technical improvements
	- Stabilized contact modal lifecycle behavior and UI interactions
	- Added shared toast-based user feedback patterns for success/error states
	- Refined list spacing and action visibility for better usability

### Known Issues
- SMS Safety Status relies on the device SMS app (`sms:` compose flow). Delivery status is not tracked inside the app.
- SMS behavior may vary by OEM/device SMS app, and standard emulators cannot fully validate carrier send flow.
- PAGASA Global Alerts and Evacuation Centers cloud-to-local sync are documented but not yet implemented in this release.
- Navigation is currently route-based from the home app bar (bottom navigation is intentionally disabled in this branch).

## PB.010.000 Release Notes
- Setup repository README with tracking table and documentation
- Initialize new Flutter project

### Important Links:
- Design Specs: https://github.com/xy-real/bihon-docportal
