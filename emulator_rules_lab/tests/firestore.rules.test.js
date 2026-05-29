const fs = require("fs");
const path = require("path");
const assert = require("assert");
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");

const projectId = "rxpro-rules-test";
const rules = fs.readFileSync(
  path.join(__dirname, "..", "firestore.rules"),
  "utf8",
);

describe("RxPro Firestore rules", () => {
  let testEnv;

  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId,
      firestore: { rules },
    });
  });

  after(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  it("allows a user to read and write only their own private user document", async () => {
    const alice = testEnv.authenticatedContext("alice").firestore();
    const bob = testEnv.authenticatedContext("bob").firestore();

    await assertSucceeds(alice.collection("users").doc("alice").set({
      uid: "alice",
      displayName: "Alice",
    }));

    await assertSucceeds(alice.collection("users").doc("alice").get());
    await assertFails(bob.collection("users").doc("alice").get());
  });

  it("allows public profile reads without exposing private user documents", async () => {
    const alice = testEnv.authenticatedContext("alice").firestore();

    await assertSucceeds(alice.collection("publicProfiles").doc("alice").set({
      uid: "alice",
      displayName: "Alice",
    }));
    await assertSucceeds(alice.collection("users").doc("alice").set({
      uid: "alice",
      email: "alice@example.com",
    }));

    const guest = testEnv.unauthenticatedContext().firestore();

    await assertSucceeds(guest.collection("publicProfiles").doc("alice").get());
    await assertFails(guest.collection("users").doc("alice").get());
  });

  it("blocks private fields from public documents", async () => {
    const alice = testEnv.authenticatedContext("alice").firestore();

    await assertFails(alice.collection("publicProfiles").doc("alice").set({
      uid: "alice",
      displayName: "Alice",
      ownerPhone: "+905551112233",
    }));

    await assertFails(alice.collection("businesses").doc("business1").set({
      ownerUid: "alice",
      name: "Alice Dental",
      ownerEmail: "alice@example.com",
    }));

    await assertSucceeds(alice.collection("businesses").doc("business1").set({
      ownerUid: "alice",
      name: "Alice Dental",
      publicPhone: "+902121112233",
    }));
  });

  it("prevents self role escalation with affectedKeys field guards", async () => {
    const alice = testEnv.authenticatedContext("alice").firestore();
    const adminDb = testEnv.authenticatedContext("admin1").firestore();

    await assertSucceeds(alice.collection("users").doc("alice").set({
      uid: "alice",
      displayName: "Alice",
    }));
    await assertSucceeds(adminDb.collection("users").doc("admin1").set({
      uid: "admin1",
      role: "admin",
    }));

    await assertSucceeds(alice.collection("users").doc("alice").update({
      displayName: "Alice Updated",
    }));
    await assertFails(alice.collection("users").doc("alice").update({
      role: "admin",
    }));
    await assertSucceeds(adminDb.collection("users").doc("alice").update({
      role: "business",
    }));
  });

  it("prevents public business ownership field changes", async () => {
    const alice = testEnv.authenticatedContext("alice").firestore();

    await assertSucceeds(alice.collection("businesses").doc("business1").set({
      ownerUid: "alice",
      name: "Alice Dental",
    }));
    await assertSucceeds(alice.collection("businesses").doc("business1").update({
      name: "Alice Dental Clinic",
    }));
    await assertFails(alice.collection("businesses").doc("business1").update({
      ownerUid: "bob",
    }));
  });

  it("does not allow invite-code based businessStaff public reads", async () => {
    const alice = testEnv.authenticatedContext("alice").firestore();

    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection("businessStaff").doc("staff1").set({
        businessId: "business1",
        inviteCode: "VISIBLE-CODE",
        linkedUid: "staff-user",
      });
    });

    await assertFails(alice.collection("businessStaff").doc("staff1").get());
  });

  it("allows a customer to create their own appointment slot lock", async () => {
    const alice = testEnv.authenticatedContext("alice").firestore();

    await assertSucceeds(alice.collection("appointmentSlots").doc("slot1").set({
      businessId: "business1",
      businessStaffId: "staff1",
      customerUid: "alice",
      status: "active",
    }));
  });

  it("blocks a customer from creating another user's deletion request", async () => {
    const alice = testEnv.authenticatedContext("alice").firestore();

    await assertSucceeds(alice.collection("accountDeletionRequests").doc("alice").set({
      uid: "alice",
      status: "pending",
    }));
    await assertFails(alice.collection("accountDeletionRequests").doc("bob").set({
      uid: "bob",
      status: "pending",
    }));
  });

  it("blocks client access to function rate-limit and abuse log collections", async () => {
    const alice = testEnv.authenticatedContext("alice").firestore();

    await assertFails(alice.collection("functionRateLimits").doc("rl1").get());
    await assertFails(alice.collection("functionRateLimits").doc("rl1").set({
      uid: "alice",
      count: 1,
    }));
    await assertFails(alice.collection("functionAbuseLogs").doc("log1").get());
    await assertFails(alice.collection("functionAbuseLogs").doc("log1").set({
      uid: "alice",
      reason: "test",
    }));
  });

  it("allows users to manage only their own notification preferences", async () => {
    const alice = testEnv.authenticatedContext("alice").firestore();
    const bob = testEnv.authenticatedContext("bob").firestore();

    const preferences = {
      uid: "alice",
      pushEnabled: true,
      appointmentReminders: true,
      messages: true,
      campaigns: false,
      system: true,
    };

    await assertSucceeds(
      alice.collection("notificationPreferences").doc("alice").set(preferences),
    );
    await assertSucceeds(
      alice.collection("notificationPreferences").doc("alice").update({
        ...preferences,
        campaigns: true,
      }),
    );
    await assertFails(
      bob.collection("notificationPreferences").doc("alice").get(),
    );
    await assertFails(
      bob.collection("notificationPreferences").doc("alice").set({
        ...preferences,
        uid: "bob",
      }),
    );
    await assertFails(
      alice.collection("notificationPreferences").doc("alice").set({
        ...preferences,
        admin: true,
      }),
    );
  });

  it("allows platform admins to review claim requests and abuse logs", async () => {
    const adminDb = testEnv.authenticatedContext("admin1").firestore();
    const alice = testEnv.authenticatedContext("alice").firestore();

    await assertSucceeds(adminDb.collection("users").doc("admin1").set({
      uid: "admin1",
      role: "admin",
    }));
    await assertSucceeds(alice.collection("businessClaimRequests").doc("claim1").set({
      uid: "alice",
      placeId: "place1",
      status: "pending",
    }));

    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection("functionAbuseLogs").doc("log1").set({
        uid: "alice",
        reason: "rate_limit_exceeded",
      });
    });

    await assertSucceeds(adminDb.collection("businessClaimRequests").doc("claim1").get());
    await assertSucceeds(adminDb.collection("businessClaimRequests").doc("claim1").update({
      status: "approved",
      reviewedBy: "admin1",
    }));
    await assertSucceeds(adminDb.collection("functionAbuseLogs").doc("log1").get());
    await assertFails(adminDb.collection("functionAbuseLogs").doc("log1").set({
      uid: "admin1",
      reason: "client_write_attempt",
    }));
  });

  it("protects post reports while allowing admin moderation and audit logging", async () => {
    const alice = testEnv.authenticatedContext("alice").firestore();
    const bob = testEnv.authenticatedContext("bob").firestore();
    const adminDb = testEnv.authenticatedContext("admin1").firestore();

    await assertSucceeds(adminDb.collection("users").doc("admin1").set({
      uid: "admin1",
      platformAdmin: true,
    }));
    await assertSucceeds(alice.collection("businessProfilePostReports").doc("report1").set({
      uid: "alice",
      postId: "post1",
      reason: "spam",
      status: "open",
    }));

    await assertSucceeds(alice.collection("businessProfilePostReports").doc("report1").get());
    await assertFails(bob.collection("businessProfilePostReports").doc("report1").get());
    await assertSucceeds(adminDb.collection("businessProfilePostReports").doc("report1").get());
    await assertSucceeds(adminDb.collection("businessProfilePostReports").doc("report1").update({
      uid: "alice",
      postId: "post1",
      reason: "spam",
      status: "resolved",
      reviewedBy: "admin1",
    }));
    await assertSucceeds(adminDb.collection("adminAuditLogs").doc("audit1").set({
      action: "post_report_resolved",
      actorUid: "admin1",
      targetCollection: "businessProfilePostReports",
      targetId: "report1",
    }));
    await assertFails(bob.collection("adminAuditLogs").doc("audit1").get());
    await assertFails(bob.collection("adminAuditLogs").doc("audit2").set({
      action: "forged",
      actorUid: "bob",
    }));
  });

  it("allows only platform admins to create moderation blocks", async () => {
    const alice = testEnv.authenticatedContext("alice").firestore();
    const adminDb = testEnv.authenticatedContext("admin1").firestore();

    await assertSucceeds(adminDb.collection("users").doc("admin1").set({
      uid: "admin1",
      role: "admin",
    }));
    await assertSucceeds(alice.collection("users").doc("alice").set({
      uid: "alice",
      accountStatus: "active",
    }));

    await assertFails(alice.collection("moderationBlocks").doc("user_alice").set({
      targetType: "user",
      targetId: "alice",
      status: "active",
    }));
    await assertSucceeds(adminDb.collection("moderationBlocks").doc("user_alice").set({
      targetType: "user",
      targetId: "alice",
      status: "active",
      reason: "abuse",
      createdBy: "admin1",
    }));
    await assertSucceeds(adminDb.collection("moderationBlocks").doc("user_alice").update({
      status: "inactive",
      updatedBy: "admin1",
    }));
    await assertSucceeds(adminDb.collection("users").doc("alice").update({
      accountStatus: "blocked",
      blocked: true,
    }));
    await assertFails(alice.collection("moderationBlocks").doc("user_alice").get());
  });

  it("protects review reports while allowing admin review hiding", async () => {
    const alice = testEnv.authenticatedContext("alice").firestore();
    const bob = testEnv.authenticatedContext("bob").firestore();
    const adminDb = testEnv.authenticatedContext("admin1").firestore();

    await assertSucceeds(adminDb.collection("users").doc("admin1").set({
      uid: "admin1",
      role: "admin",
    }));
    await assertSucceeds(alice.collection("businessReviewReports").doc("report1").set({
      uid: "alice",
      reviewId: "review1",
      businessId: "business1",
      reason: "spam",
      status: "open",
    }));
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection("businessReviews").doc("review1").set({
        uid: "reviewer1",
        businessId: "business1",
        rating: 1,
        comment: "spam",
        moderationStatus: "active",
      });
    });

    await assertSucceeds(alice.collection("businessReviewReports").doc("report1").get());
    await assertFails(bob.collection("businessReviewReports").doc("report1").get());
    await assertSucceeds(adminDb.collection("businessReviewReports").doc("report1").update({
      uid: "alice",
      reviewId: "review1",
      businessId: "business1",
      reason: "spam",
      status: "resolved",
      reviewedBy: "admin1",
    }));
    await assertSucceeds(adminDb.collection("businessReviews").doc("review1").update({
      moderationStatus: "hidden",
      moderatedBy: "admin1",
    }));
    await assertFails(bob.collection("businessReviews").doc("review1").update({
      moderationStatus: "hidden",
    }));
  });

  it("protects campaign reports while allowing admin campaign hiding", async () => {
    const alice = testEnv.authenticatedContext("alice").firestore();
    const bob = testEnv.authenticatedContext("bob").firestore();
    const adminDb = testEnv.authenticatedContext("admin1").firestore();

    await assertSucceeds(adminDb.collection("users").doc("admin1").set({
      uid: "admin1",
      role: "admin",
    }));
    await assertSucceeds(alice.collection("campaignReports").doc("report1").set({
      uid: "alice",
      campaignId: "campaign1",
      sourceCollection: "businessCampaigns",
      businessId: "business1",
      reason: "spam",
      status: "open",
    }));
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection("businessCampaigns").doc("campaign1").set({
        uid: "owner1",
        businessId: "business1",
        title: "Deal",
        moderationStatus: "active",
      });
    });

    await assertSucceeds(alice.collection("campaignReports").doc("report1").get());
    await assertFails(bob.collection("campaignReports").doc("report1").get());
    await assertSucceeds(adminDb.collection("campaignReports").doc("report1").update({
      uid: "alice",
      campaignId: "campaign1",
      sourceCollection: "businessCampaigns",
      businessId: "business1",
      reason: "spam",
      status: "resolved",
      reviewedBy: "admin1",
    }));
    await assertSucceeds(adminDb.collection("businessCampaigns").doc("campaign1").update({
      moderationStatus: "hidden",
      hidden: true,
      moderatedBy: "admin1",
    }));
    await assertFails(bob.collection("businessCampaigns").doc("campaign1").update({
      moderationStatus: "hidden",
      hidden: true,
    }));
  });

  it("keeps the test harness active", () => {
    assert.ok(testEnv);
  });
});
