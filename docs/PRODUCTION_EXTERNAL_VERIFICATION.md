# Production External Verification

Last updated: 2026-05-29

This file is intentionally strict. RxPro should not be called a 9+ production
release until every item below is verified on the real external systems that
Codex cannot truthfully validate from source code alone.

## Android

- [ ] `flutter pub get` completed after the latest dependency changes.
- [ ] `flutter analyze` completed with zero issues after the latest changes.
- [ ] `flutter test` completed with all tests passing after the latest changes.
- [x] `tools\release_gate_check.ps1 -SkipIos` completed with zero Android blockers.
- [ ] `tools\user_release_build.ps1` produced a release APK from normal PowerShell.
- [ ] Release APK installed on a real Android device.
- [ ] Android login/register/reset smoke passed on a real device.
- [ ] Android Discover, business detail, booking, cancellation, message, campaign, and finance smoke passed.
- [ ] Android push notification foreground/background/tap behavior passed.
- [ ] Android Crashlytics release test crash appeared in Firebase Console.
- [ ] Android Analytics DebugView showed registration, discover, booking, campaign, message, and finance events.
- [ ] Firebase App Check enforcement enabled for Android after smoke testing.

## iOS

- [ ] Apple Developer team selected for Runner target.
- [ ] `tools\release_gate_check.ps1` completed with zero iOS blockers.
- [ ] `pod install` completed on macOS.
- [ ] `flutter build ipa --release` completed on macOS.
- [ ] iOS app installed on a real device or TestFlight.
- [ ] iOS Firebase initialization, login/register/reset, booking, messaging, and push smoke passed.
- [ ] iOS Crashlytics release test crash appeared in Firebase Console.
- [ ] iOS Analytics DebugView showed the release funnel events.
- [ ] Firebase App Check enforcement enabled for iOS after smoke testing.

## Firebase, Store, And Operations

- [x] Firestore and Storage emulator rules tests passed 24/24 on 2026-05-29 before the 29-3M follow-up.
- [x] Firestore and Storage emulator rules tests passed 28/28 on 2026-05-29 after the 29-3M follow-up guards.
- [x] Firestore and Storage emulator rules tests passed 29/29 on 2026-05-29 after service pricing and finance write-permission guards.
- [ ] Firestore and Storage production rules deployed from the reviewed rules files.
- [ ] Firebase App Check enforcement enabled for Firestore, Storage, and callable Functions after device smoke testing.
- [ ] Firebase/GCP budget alerts configured for Places, Routes, Functions, Firestore, Storage, and AI usage.
- [ ] Play Store privacy policy URL is final and reachable.
- [ ] App Store privacy policy URL is final and reachable.
- [ ] Support URL is final and reachable.
- [ ] Play Store data safety answers match `docs\APP_STORE_PRIVACY_LABEL_DRAFT.md`.
- [ ] App Store privacy labels match `docs\APP_STORE_PRIVACY_LABEL_DRAFT.md`.
- [ ] Store screenshots and demo accounts prepared.
- [ ] Admin/moderation smoke passed for claim review, report review, content hide/restore, user block/unblock, and audit log.
