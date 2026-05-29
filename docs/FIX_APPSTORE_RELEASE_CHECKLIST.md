# fix App Store Release Checklist

## App identity

- App display name: `fix`
- iOS bundle identifier: `com.fix.mobile`
- Version source: `pubspec.yaml` -> `version: 1.0.0+1`
- Minimum iOS deployment target: `13.0`

## Firebase

Create or verify an iOS app in Firebase with bundle id:

```text
com.fix.mobile
```

Then download `GoogleService-Info.plist` and place it at:

```text
ios/Runner/GoogleService-Info.plist
```

After adding the file, verify that `lib/firebase_options.dart` also uses:

```text
iosBundleId: 'com.fix.mobile'
```

## Apple Developer

- Create App ID / Bundle ID: `com.fix.mobile`
- Enable Push Notifications capability.
- Enable automatic signing in Xcode or select the correct provisioning profile.
- Set `DEVELOPMENT_TEAM` in Xcode for the Runner target.
- Confirm the app icon is present in `ios/Runner/Assets.xcassets/AppIcon.appiconset`.

## App Store Connect metadata

- App name: `fix`
- Category: choose the closest service marketplace/business category.
- Privacy Policy URL: required before submission.
- Support URL: required before submission.
- App Privacy labels: disclose account data, contact info, approximate/precise location, user content/photos, identifiers, diagnostics, and Firebase analytics/crash reporting as applicable.
- Screenshots: prepare required iPhone sizes from a real or simulator build.
- Demo account: provide an individual and business/staff test account if login is required to review core flows.

## Mac release commands

Run on macOS with Xcode and CocoaPods installed:

```sh
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter build ipa --release --build-name 1.0.0 --build-number 1
```

If the archive succeeds, upload through Xcode Organizer or Transporter.
