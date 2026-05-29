# App privacy label draft

This is a release-prep draft for App Store / Play Store privacy declarations.
It must be reviewed before submission.

## Data linked to user identity

- Account identifiers: Firebase UID, email, phone number.
- Contact info: name, email, phone.
- User content: profile images, business images, stories, campaign media,
  messages, reviews and reports.
- App activity: discovery, appointment, campaign, notification and messaging
  events when analytics is enabled.
- Diagnostics: crash logs, performance and error metadata.

## Location

- Approximate or precise location may be used when the user grants permission.
- Purpose: nearby businesses, distance, route estimate and localized discovery.
- Location access should be limited to while-in-use behavior.

## Business and staff data

- Business profile, services, staff permissions, appointments, customer records,
  finance/accounting records and campaign data are processed for business
  operations.

## Data deletion

- The app must expose an account deletion request flow.
- Some transaction, appointment, invoice/accounting or dispute records may be
  retained for legal obligations and then deleted or anonymized.

## Tracking

- No cross-app tracking is declared by default.
- If advertising SDKs or tracking domains are added later, this document and
  platform privacy declarations must be updated.

