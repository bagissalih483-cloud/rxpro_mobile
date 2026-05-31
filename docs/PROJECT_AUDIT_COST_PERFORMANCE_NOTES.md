# Project Audit, Cost and Performance Notes

Date: 2026-05-31

## Scope

This audit focused on low-risk improvements that can be applied without a broad refactor or production deploy. The working tree already contains many unrelated changes, so this document avoids recommending destructive cleanup.

## Applied Safely

- Message thread read marking now runs only when there is an unread incoming message.
- Message read marking now queries only unread messages with a small limit instead of reading the whole message subcollection.
- Message thread live history now listens to the newest 120 messages instead of the entire message subcollection.
- Explore location flow now applies the current position silently before the location reload, reducing the visible two-step refresh.
- Explore location query marker no longer notifies the UI because it is internal bookkeeping.
- Nearby explore now runs member and directory geo queries in parallel.
- Nearby explore skips the broader fallback scan when geo queries already return enough local results.
- Header badge streams now cap unread message/notification reads at 100 because the UI displays `99+`.
- Explore header badge streams are cached by user/business scope to avoid re-subscribing on normal UI rebuilds.

## Cost Risks Found

- Message read receipts were previously expensive for long threads because opening a thread could read every message and write many read flags.
- Explore location refresh can trigger both geo/local lookup and fallback lookup. This is useful, but should stay behind query budget limits.
- Admin moderation screens open multiple live streams. Keep these pages admin-only and avoid opening them in normal user shells.
- Explore header badges are live streams. They are capped to match the visible `99+` UI, but should not be duplicated in nested widgets.
- Business/customer/accounting screens include several live Firestore streams. They should remain scoped by `businessId` and limited where possible.
- Push token cleanup uses several reads on sign-out and auth changes. It is acceptable as best-effort cleanup, but should remain timeout guarded.
- `assets/images/fix_login_hero_banner.png` is about 1.2 MB. It is acceptable for a first launch visual, but should be compressed or served as a smaller mobile-optimized asset before release.

## Larger Follow-Ups

- Split very large UI files gradually:
  - `lib/features/accounting/presentation/pages/accounting_sales_page.dart`
  - `lib/features/auth/presentation/pages/fix_login_gate_page.dart`
  - `lib/features/messages/messages_inbox_page.dart`
  - `lib/features/businesses/business_appointment_management_page.dart`
- Keep Firestore queries behind repository classes and query-budget policy objects.
- Add dedicated repository tests for message read receipts and explore location reload behavior.
- Replace placeholder/manual demo text in accounting sales entry once the live catalog/customer lookup is fully connected.
- Review screens using `snapshots(includeMetadataChanges: true)` and keep that option only where metadata-only UI updates are genuinely useful.
- Consider a paged message history after the first release. Current live message window is capped at 120 messages; older history should be loaded on demand.

## Do Not Do Blindly

- Do not delete large files just because they are long; many are active screens.
- Do not remove unknown untracked files while the working tree is dirty.
- Do not broaden Firestore queries to solve UI state issues.
- Do not move appointment grid logic during performance cleanup.
