# Analytics Event Contract

Last updated: 2026-05-29

This is the minimum production funnel contract for RxPro/Fix. Event names must
stay stable once a release is shipped.

## Core Funnel

| Event | Trigger | Required parameters |
| --- | --- | --- |
| `registration_completed` | Individual or corporate registration completes | `account_type` |
| `location_permission_result` | Location permission prompt resolves | `status`, `source` |
| `explore_business_open` | User opens or attempts to open a business from Discover | `business_id`, `category`, `is_member` |
| `business_claim_submitted` | Directory-only business claim is submitted | `place_id`, `category` |
| `appointment_booking_completed` | Customer booking transaction succeeds | `business_id`, `service_id`, `staff_id`, `duration_minutes` |
| `appointment_cancelled` | Customer or business cancels an appointment | `appointment_id`, `actor_role`, `reason` |
| `campaign_viewed` | Customer opens a campaign | `campaign_id`, `business_id`, `category`, `source_collection` |
| `campaign_created` | Business publishes a campaign | `campaign_id`, `business_id`, `category` |
| `campaign_report_submitted` | Customer reports a campaign | `campaign_id`, `business_id`, `reason`, `source_collection` |
| `message_sent` | User or business sends a message | `thread_id`, `sender_role`, `business_id` |
| `finance_action_completed` | Business completes a finance/accounting action | `action_type`, `business_id`, `amount_kurus` |

## Current App Wiring

- Bootstrap logs `logAppOpen` through Firebase Analytics where supported.
- Screen navigation is wired through `FirebaseAnalyticsObserver`.
- Registration completion is logged for individual and corporate accounts.
- Location service disabled, permission denied, and granted outcomes are logged
  from Discover.
- Discover business open attempts and business claim submissions are logged.
- Successful customer appointment bookings are logged after the slot-lock
  transaction and notification write succeed.
- Customer campaign opens, campaign creations, campaign report submissions, and
  message sends are logged.
- Accounting sale, payment collection, and expense write completions are logged.

## Release Verification

- Verify DebugView in Firebase Analytics on a physical Android release candidate.
- Verify DebugView in Firebase Analytics on a physical iOS release candidate.
- Confirm the first dashboard tracks: registration, discover open, claim submit,
  appointment booking, cancellation, messaging, campaign, and finance funnels.
