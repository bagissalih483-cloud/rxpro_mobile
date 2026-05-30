# RxPro Public Data Matrix

Last updated: 2026-05-29

This matrix is the source of truth for intentionally public Firestore and
Storage surfaces. New public reads must be added here and covered by rules
tests before release.

## Forbidden In Public Documents

The following data must not be stored in public-readable documents:

- Direct private contact fields: `ownerEmail`, `customerEmail`, `ownerPhone`,
  `customerPhone`, `privatePhone`, `personalPhone`.
- Private identity fields: `identityNumber`, `tcKimlikNo`, private customer
  identifiers, internal customer lists.
- Finance fields: `balance`, `walletBalance`, `revenue`, `totalRevenue`,
  `expense`, `expenses`, `profit`, `iban`, `taxNumber`.
- Internal moderation or operational fields: `notes`, `internalNotes`,
  `privateNotes`, staff invite codes, admin-only audit notes.

## Firestore Public Reads

| Collection | Public purpose | Allowed public fields | Forbidden fields | Rules evidence |
| --- | --- | --- | --- | --- |
| `publicProfiles` | Public display identity. | `uid`, `displayName`, `city`, `district`, `accountKind`, `businessId`, `businessName`, `photoUrl`, `updatedAt`. | Private contact, role/admin claims, finance, internal notes. | `hasNoPublicPrivateFields`, `keepsFieldsUnchanged(["uid"])`, rules test blocks private fields. |
| `businesses` | Discover and business profile cards. | Name, category, public description, city/district/neighborhood, public phone, public map/address text, logo/cover URLs, rating summary, coordinates, visibility/status. | Owner private contact, staff/customer lists, finance, private notes, ownership changes. | `hasNoPublicPrivateFields`, ownership field guard, rules test blocks private fields and owner changes. |
| `businessProfiles` | Profile details for listed businesses. | Public profile copy, public media, service highlights, public contact/display fields. | Owner private contact, finance, staff/customer lists, private notes. | `hasNoPublicPrivateFields`, ownership field guard. |
| `registeredBusinesses` | Legacy/compatibility business listing surface. | Same as `businesses`. | Same as `businesses`. | `hasNoPublicPrivateFields`, ownership field guard. |
| `businessPlaceIndex` | Imported Sanliurfa/Mardin directory data for discovery. | Place id, name, category, city/district/neighborhood, coordinates, public address, public rating metadata. | User ids, owner private contact, finance, staff/customer data. | Read-only public; client writes denied. |
| `directory_pois_google_cache` | Legacy read-only directory cache kept only for backward compatibility. | Non-user place metadata only. | User ids, owner private contact, finance, staff/customer data. | Read-only public; client writes denied. App no longer reads this path for live Places. |
| `placeQueryBuckets` | Legacy read-only query bucket metadata. | Non-user query/cache metadata only. | User ids, private contact, finance, staff/customer data. | Read-only public; client writes denied. |
| `businessServices` | Public service catalog for booking/profile screens. | Business id, service name, duration, public price/display text, category/status. | Staff private notes, internal cost/margin, finance ledger fields. | Listed in `publicReadCollection`; business-scoped write checks. |
| `businessProfilePosts` | Public business profile posts. | Business id, media, caption, created display metadata, moderation display status. | Private notes, private user contact, customer lists. | Listed in `publicReadCollection`; business-scoped write checks. |
| `businessStories` | Public story rail. | Business id, media/thumbnail URLs, public business display metadata, expiry/status. | Private user contact, customer lists, finance. | Listed in `publicReadCollection`; business-scoped write checks. |
| `businessCampaigns` | Public campaign listings. | Campaign title/body, business id/name, public dates, public media, public status. | Finance ledger data, private user contact, internal notes. | Explicit public read, private field guard, owner/business id guard. |
| `campaigns` | Legacy/public campaign listings. | Same as `businessCampaigns`. | Same as `businessCampaigns`. | Explicit public read, private field guard, owner/business id guard. |
| `businessReviews` | Public review display. | Business id, rating, review body, public reviewer display name, moderation display state. | Private user contact, customer lists, finance, internal notes. | Explicit public read, private field guard on creates/updates, identity field guard. |
| `businessRatings` | Public aggregate rating display. | Business id, rating averages/counts. | Private user contact, customer lists, finance. | Listed in `publicReadCollection`; business-scoped write checks. |

## Firestore Private Reads

These collections must stay authenticated or role-scoped:

- `users`, `users_private`, `accountDeletionRequests`
- `appointments`, `appointmentSlots`
- `messageThreads` and nested `messages`
- `notifications`, `customerNotifications`, `notificationPreferences`
- `businessStaff`, staff invite data, finance records, audit logs, moderation
  blocks, report queues, rate-limit and abuse-log collections

## Storage Public Reads

Only public media paths are readable without authentication:

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

All other Storage paths must deny public reads and writes. Public write rules
must require authentication, image content type, size limits, and owner/business
scope checks.

## Enforcement

- `tools/public_data_matrix_check.ps1` fails when a public Firestore/Storage
  surface exists in rules but is not documented here.
- `tools/secret_scan.ps1` fails if signing keys or local secret files are found
  in tracked source files.
- Rules tests must cover private field rejection, ownership/role escalation
  rejection, and read-only directory cache behavior.
