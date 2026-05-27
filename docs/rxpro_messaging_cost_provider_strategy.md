# RxPro Messaging Cost & Provider Strategy

## Purpose

This document records the messaging scalability decision for RxPro. It is a planning and architecture note only. It does not deploy or change application behavior.

## Current decision

Firebase/Firestore remains suitable for RxPro's primary business data:

- Authentication and user profiles
- Business profiles
- Appointment workflows
- Finance/accounting records
- Notification center records
- Storage-backed media flows
- Firestore rules/index-governed business data

Messaging/chat is treated as a separate scalability risk domain because realtime chat listeners can multiply document reads and listener-triggered read costs as active chat usage grows.

## Messaging architecture principle

Messaging must stay behind a provider boundary. UI should not directly depend on Firestore implementation details.

Current foundation names already present in the project include:

- ChatRepository
- MessagingService
- notification/message boundary foundation

Future architecture should preserve a provider-switchable contract such as:

- FirestoreChatProvider for current MVP/firestore-backed implementation
- GetStreamChatProvider or another managed chat provider if MAU/chat traffic grows
- WebSocketChatProvider for a self-hosted long-term option if justified by scale/cost

## Practical rule

Do not migrate messaging/chat blindly.

Before touching message code, run an exact audit covering:

- ChatRepository
- MessagingService
- MessagesInboxPage
- BusinessAppointmentManagementPage message entry points
- mirror write paths
- unread counter paths
- notification write boundaries
- realtime listener count and query shape
- pagination/cache behavior

## Cost-control targets

The project should avoid:

- always-open large inbox listeners
- listener-per-thread fan-out without pagination
- duplicate mirror collections that multiply reads/writes without a clear compatibility reason
- unread counters recalculated from full message collections
- notification writes tightly coupled to every chat write without a boundary service

## Migration posture

Short term:

- Keep existing working chat behavior stable.
- Continue non-chat repository/service migrations.
- Do not patch locked/high-risk message flows blindly.

Medium term:

- Define a provider interface and message domain DTOs.
- Keep UI dependent on MessagingService rather than Firestore query details.
- Add targeted unit tests for pure mapping/DTO/provider boundary logic.

Long term:

- Choose provider based on real active chat usage, not total registered users.
- Compare Firestore cost, managed chat service cost, and self-hosted WebSocket cost using active monthly chat users, average messages per user, active listeners, and unread/inbox design.
