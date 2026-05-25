# Privacy & Compliance

FlyHUD's data collection practices, privacy manifest, and permission requirements.

## Data Collection

FlyHUD does **not** collect, store, transmit, or share any user data. The library operates
entirely on-device with no network access.

### Summary

| Category | Collected | Details |
| -------- | --------- | ------- |
| Personal Data | No | No PII collected |
| Usage Data | No | No analytics or telemetry |
| Device Data | No | No device identifiers accessed |
| Location Data | No | No location services used |
| Network Access | No | No HTTP/HTTPS requests made |
| File System | No | No file read/write operations |
| Keychain | No | No keychain access |
| Pasteboard | No | No clipboard access |

## Privacy Manifest

FlyHUD includes an Apple Privacy Manifest (`PrivacyInfo.xcprivacy`) in each module target,
as required by Apple starting Spring 2024.

### Manifest Contents

Each module's `PrivacyInfo.xcprivacy` declares:

- **NSPrivacyTracking**: `false` — No tracking
- **NSPrivacyTrackingDomains**: Empty — No tracking domains
- **NSPrivacyCollectedDataTypes**: Empty — No data collected
- **NSPrivacyAccessedAPITypes**: Empty — No required reason APIs used

### File Locations

```text
Sources/
├── HUD/PrivacyInfo.xcprivacy
├── IndicatorHUD/PrivacyInfo.xcprivacy
└── ProgressHUD/PrivacyInfo.xcprivacy
```

## Required Permissions

FlyHUD requires **no** runtime permissions. It does not use:

- Camera or microphone
- Photo library
- Location services
- Contacts or calendars
- Health data
- Bluetooth
- Local network
- Push notifications
- App Tracking Transparency

## Third-Party Dependencies

FlyHUD has **zero** third-party dependencies. It relies solely on:

- UIKit (Apple system framework)
- Foundation (Apple system framework)
- CoreAnimation (Apple system framework, via UIKit)

## Required Reason APIs

FlyHUD does not use any APIs that require a "required reason" declaration under
Apple's privacy requirements, including:

- `UserDefaults` — Not used
- `NSFileManager` (file timestamp APIs) — Not used
- `systemUptime` / `mach_absolute_time` — Not used directly
- `NSURLSession` — Not used
- Disk space APIs — Not used

## App Store Compliance

When submitting your app to the App Store:

1. FlyHUD's privacy manifest is automatically bundled via SPM/CocoaPods
2. No additional privacy declarations are needed for FlyHUD specifically
3. Your app's overall privacy nutrition label should reflect your app's behavior, not FlyHUD's

## GDPR / CCPA

Since FlyHUD collects no data:

- No Data Processing Agreement (DPA) is required
- No data subject access requests apply to FlyHUD data
- No consent management is needed for FlyHUD
- FlyHUD is fully compliant with GDPR, CCPA, and similar privacy regulations
