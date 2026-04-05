# Project Bihon

Project Bihon is an Android application designed to help families prepare for and respond to natural disasters, with a primary focus on typhoons. The app serves as a trusted companion, providing essential guidance, checklists, and resources to ensure families are ready when disaster strikes. It includes an inventory tracker to help families monitor and manage their emergency supplies and preparedness items.

| Internal Release Code | Date Released |
|:-----------------|:--------------|
| PB.010.001       | 2026-04-05    |
| PB.010.000       | 2026-03-01    |

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
