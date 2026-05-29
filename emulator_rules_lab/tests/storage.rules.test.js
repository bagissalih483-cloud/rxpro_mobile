const fs = require("fs");
const path = require("path");
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");

const projectId = "rxpro-storage-rules-test";
const storageRules = fs.readFileSync(
  path.join(__dirname, "..", "storage.rules"),
  "utf8",
);
const firestoreRules = fs.readFileSync(
  path.join(__dirname, "..", "firestore.rules"),
  "utf8",
);

function imageBlob(size = 16) {
  return new Blob(["x".repeat(size)], { type: "image/jpeg" });
}

function textBlob() {
  return new Blob(["not-image"], { type: "text/plain" });
}

describe("RxPro Storage rules", () => {
  let testEnv;

  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId,
      firestore: { rules: firestoreRules },
      storage: { rules: storageRules },
    });
  });

  after(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
    await testEnv.clearStorage();
  });

  it("allows public reads only from known public asset paths", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.storage().ref("business_logos/business1/logo.jpg").put(imageBlob());
      await context.storage().ref("private_exports/user1/report.pdf").put(textBlob());
    });

    const guest = testEnv.unauthenticatedContext();
    const storage = guest.storage();

    await assertSucceeds(storage.ref("business_logos/business1/logo.jpg").getMetadata());
    await assertFails(storage.ref("private_exports/user1/report.pdf").getMetadata());
  });

  it("allows a business owner to upload small image assets to their own business path", async () => {
    const owner = testEnv.authenticatedContext("owner1");
    const storage = owner.storage();

    await assertSucceeds(
      storage.ref("business_covers/owner1/cover.jpg").put(imageBlob()),
    );
  });

  it("allows business owners to upload generated thumbnails only to their own public media paths", async () => {
    const owner = testEnv.authenticatedContext("owner1");
    const stranger = testEnv.authenticatedContext("stranger");
    const guest = testEnv.unauthenticatedContext();

    await assertSucceeds(
      owner.storage().ref("business_intro/owner1/business1/post_thumb.jpg").put(imageBlob()),
    );
    await assertSucceeds(
      owner.storage().ref("business_stories/owner1/business1/story_thumb.jpg").put(imageBlob()),
    );
    await assertFails(
      stranger.storage().ref("business_intro/owner1/business1/post_thumb.jpg").put(imageBlob()),
    );
    await assertFails(
      stranger.storage().ref("business_stories/owner1/business1/story_thumb.jpg").put(imageBlob()),
    );
    await assertSucceeds(
      guest.storage().ref("business_intro/owner1/business1/post_thumb.jpg").getMetadata(),
    );
    await assertSucceeds(
      guest.storage().ref("business_stories/owner1/business1/story_thumb.jpg").getMetadata(),
    );
  });

  it("allows owner scoped business media without Firestore cross-service lookups", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection("users").doc("owner1").set({
        ownedBusinessId: "business1",
      });
    });

    const owner = testEnv.authenticatedContext("owner1");
    const stranger = testEnv.authenticatedContext("stranger");

    await assertSucceeds(
      owner.storage().ref("business_intro/owner1/business1/post.jpg").put(imageBlob()),
    );
    await assertSucceeds(
      owner.storage().ref("business_intro/owner1/business1/post_thumb.jpg").put(imageBlob()),
    );
    await assertFails(
      stranger.storage().ref("business_intro/owner1/business1/post.jpg").put(imageBlob()),
    );
  });

  it("blocks non owner business asset uploads", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection("businesses").doc("business1").set({
        ownerUid: "owner1",
      });
    });

    const stranger = testEnv.authenticatedContext("stranger");
    const storage = stranger.storage();

    await assertFails(
      storage.ref("business_covers/business1/cover.jpg").put(imageBlob()),
    );
  });

  it("blocks non image uploads even for the owner", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection("businesses").doc("business1").set({
        ownerUid: "owner1",
      });
    });

    const owner = testEnv.authenticatedContext("owner1");
    const storage = owner.storage();

    await assertFails(
      storage.ref("business_covers/business1/cover.txt").put(textBlob()),
    );
  });

  it("allows users to upload only their own profile image", async () => {
    const alice = testEnv.authenticatedContext("alice");
    const storage = alice.storage();

    await assertSucceeds(storage.ref("user_profiles/alice/avatar.jpg").put(imageBlob()));
    await assertFails(storage.ref("user_profiles/bob/avatar.jpg").put(imageBlob()));
  });

  it("blocks oversized avatar and logo uploads at the stricter 2 MB limit", async () => {
    const oversized = imageBlob((2 * 1024 * 1024) + 1);
    const owner = testEnv.authenticatedContext("owner1");
    const storage = owner.storage();

    await assertFails(storage.ref("business_logos/owner1/logo.jpg").put(oversized));
    await assertFails(storage.ref("user_profiles/owner1/avatar.jpg").put(oversized));
  });
});
