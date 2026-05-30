# Security Public Data and App Check Plan

Last updated: 2026-05-29

## Public Firestore Collections

The enforceable source-of-truth is now `docs/PUBLIC_DATA_MATRIX.md`.
`tools/public_data_matrix_check.ps1` fails CI if a public rules surface is not
documented in that matrix.

Only these Firestore surfaces are intended for unauthenticated/public reads:

- `businesses/{businessId}`: public business discovery/profile fields only. Private owner contact, finance, staff invite, internal notes, and audit fields must not be stored here unless intended for public display.
- `publicProfiles/{uid}`: limited display profile fields: `uid`, `displayName`, `city`, `district`, `accountKind`, optional `businessId`, optional `businessName`, `updatedAt`.
- `businessServices/{serviceId}`: public service catalog fields needed for booking and profile display.
- `businessReviews/{reviewId}` and rating summary collections: public review display data only.
- Imported/legacy directory collections such as `businessPlaceIndex`,
  `directory_pois_google_cache`, and `placeQueryBuckets`: public directory data,
  not user private data. The mobile app uses the imported `businessPlaceIndex`
  strategy; live Google Places discovery remains disabled.

Private user data belongs in:

- `users/{uid}`: self-only.
- `users_private/{uid}`: self-only sensitive/private extensions.
- `accountDeletionRequests/{uid}`: self-only deletion request status.
- Finance, appointment, message, notification, staff, and audit collections: authenticated and role-scoped only.

## Public Storage Paths

Only these Storage paths are public-readable:

- `business_logos/{businessId}/{fileName}`
- `business_logos/{ownerUid}/{businessId}/{fileName}`
- `business_covers/{businessId}/{fileName}`
- `business_covers/{ownerUid}/{businessId}/{fileName}`
- `business_intro/{businessId}/{fileName}`
- `business_intro/{ownerUid}/{businessId}/{fileName}`
- `user_profiles/{uid}/{fileName}`
- `business_stories/{businessId}/{fileName}`
- `business_stories/{ownerUid}/{businessId}/{fileName}`
- `business_campaigns/{businessId}/{fileName}`
- `business_campaigns/{ownerUid}/{businessId}/{fileName}`

All unknown Storage paths are denied for read and write. New app uploads use the
owner-scoped business paths so writes can be checked directly against
`request.auth.uid` without relying on cross-service Firestore lookups. Legacy
two-segment business paths remain public-readable and still have guarded write
rules for backward compatibility.

## Firebase Config and API Key Risk

Firebase client config files are not treated as server secrets, but they must be protected by:

- Firestore and Storage security rules.
- App Check enforcement in production.
- API key restrictions in Google Cloud Console.
- Monitoring for quota spikes and abuse.

Server-side secrets such as OpenAI keys, Places keys used by Cloud Functions, signing keys, and service account credentials must not be committed.

## App Check Production Plan

1. `firebase_app_check` is a Flutter dependency and the app now activates App Check during Firebase bootstrap.
2. Debug builds use the debug provider on Android/iOS/macOS.
3. Release Android builds use Play Integrity.
4. Release Apple builds use App Attest with DeviceCheck fallback.
5. Register Android app `com.fix.mobile` in Firebase App Check.
6. Register iOS app `com.fix.mobile` in Firebase App Check.
7. Add debug tokens only for development devices and remove unused tokens before release.
8. Turn on App Check enforcement for Firestore, Storage, and callable/onRequest Cloud Functions after smoke tests pass.
9. Monitor rejected App Check requests during the pilot window.

## Verified Rules Tests

The emulator test suite covers:

- Private `users/{uid}` self-only reads/writes.
- Public profile reads without exposing private user docs.
- `businessStaff.inviteCode` not granting public reads.
- Appointment slot lock creation ownership.
- Account deletion request ownership.
- Storage known public paths.
- Storage unknown private paths denied.
- Storage owner/non-owner upload behavior.
- Storage owner-scoped business media paths and generated thumbnail uploads.
- Storage image content type and profile ownership.
- Imported directory collections stay public-readable and deny client writes.
- Appointment identity field update rejection.
- Staff self role/permission escalation rejection.
- Finance record business-scope mutation rejection and finance-write permission gating.
- Service pricing edits limited to the owner or explicit service/finance write permission.
- Parent document guard coverage for `users/{uid}` and `businesses/{businessId}` so recursive subdocument rules cannot bypass protected field checks.
