# Firestore rules tests

Install once:

```powershell
cd emulator_rules_lab
npm install
```

Run with the Firestore emulator test environment:

```powershell
npm run test:firestore
```

The first P0 scenarios cover:

- private `users/{uid}` access,
- public `publicProfiles/{uid}` access,
- `businessStaff.inviteCode` no longer granting reads,
- customer-owned `appointmentSlots`,
- self-only account deletion requests.

