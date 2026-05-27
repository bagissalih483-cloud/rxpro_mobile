# RxPro Deep Analysis Notes - Location Discovery Scale

Date: 2026-05-26

## Current State

- The app can capture the individual user's device location.
- Business cards can compute distance from the current user.
- Google Maps directions can be opened from discovery cards.
- Google Places-style records can be normalized into the business directory model.
- Member and directory-only records are visually separated in discovery.
- Business location writes now persist geohash prefixes.
- Discovery can now use a geohash-indexed Firestore query when a user location exists.
- Discovery can now call a server-side Google Places live directory search and merge those directory-only results with RxPro member records.
- A dry-run-first large-city seed script can create a minimum place index without storing full Google business profiles.

## Main Gap

The original discovery flow was mostly client filtered. Patch 65I changed the app path to try a geohash-indexed Firestore query first when user location exists, then safely fall back to the broad cache for legacy records.

The remaining gap is operational: Google Places secret/deploy must be completed, seed/backfill scripts must be run against the real project, Firestore index configuration must be locked, and emulator tests must cover the query behavior before this is production-complete.

## Required Professional Direction

- Business location writes should persist scalar coordinates and a `GeoPoint`.
- Business location writes should also persist stable geohash prefixes.
- Discovery should first try a location-indexed Firestore query using geohash prefixes.
- The app should keep a safe fallback to the existing cache while legacy/imported records are backfilled.
- Imported Google Places records should stay directory-only until an owner/member signal claims them.
- Live Google Places discovery should stay server-side so the API key is never shipped in the mobile app.
- Large-scale production should use optional city seed indexes that store only `placeId`, category and geo index metadata until a business is claimed.
- Large-scale production should later add Firestore composite indexes, migration/backfill scripts and emulator tests for the geo query path.

## Decision For This Patch

Add the geohash/index foundation now:

- Pure geohash encoder and nearby prefix helper.
- Tests for coordinate encoding and nearby prefix coverage.
- Persist `geoHash`, `geoHash4`, `geoHash5`, `geoHash6`, `geoHash7` when a business captures its location.
- Discovery uses indexed nearby queries when user location is available, then falls back to cache for old records.

## Implemented In 65I

- Added `lib/core/businesses/business_geo_index.dart`.
- Added `test/core/businesses/business_geo_index_test.dart`.
- Business profile location saves now write `geoHash`, `geoHash4`, `geoHash5`, `geoHash6` and `geoHash7`.
- `BusinessDirectoryCacheService.getBusinessesForExplore()` now queries nearby prefixes when a user location exists.
- `HomeExplorePage` now reloads the location-indexed query after silent/manual location capture and radius changes.
- Added `functions/scripts/backfillBusinessGeoIndex.js` with dry-run-first behavior for existing/imported records.

## Still Required

- Set `GOOGLE_PLACES_API_KEY`, deploy `searchNearbyDirectoryBusinesses`, and run a device smoke test from real locations.
- Run `npm run seed:places-directory` in dry-run mode for priority cities, then with `--write` after reviewing counts.
- Run the backfill script in dry-run mode first, then with `--write` after reviewing the count.
- Add Firestore index definitions for the chosen geo prefix query fields.
- Add emulator tests for indexed nearby query, legacy fallback and member/directory-only filtering.

## Implemented In 65M

- Added `searchNearbyDirectoryBusinesses` Cloud Function.
- Added `lib/core/businesses/google_places_directory_service.dart`.
- `BusinessDirectoryCacheService` now merges local member businesses with live Google Places directory-only items.
- `HomeExplorePage` now passes selected category to the discovery loader and refreshes live results on category change.
- Added `functions/scripts/seedGooglePlacesDirectoryIndex.js` for optional Istanbul, Ankara, Izmir, Antalya, Bursa, Gaziantep, Konya and Adana seed runs.
- Added `test/core/businesses/business_directory_item_test.dart` for live Places payload parsing.
