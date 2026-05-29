"use strict";

const admin = require("firebase-admin");

const DEFAULT_COLLECTIONS = [
  "businessProfilePosts",
  "businessStories",
  "businessCampaigns",
  "campaigns",
];

const MEDIA_FIELDS = ["thumbnailUrl", "thumbUrl", "imageUrl", "mediaUrl", "photoUrl"];

function parseArgs(argv) {
  const options = {
    write: false,
    limit: 0,
    batchSize: 400,
    collections: DEFAULT_COLLECTIONS,
  };

  for (const arg of argv) {
    if (arg === "--write") {
      options.write = true;
      continue;
    }

    const [key, value] = arg.split("=");
    if (key === "--collection" && value) {
      options.collections = value
        .split(",")
        .map((item) => item.trim())
        .filter(Boolean);
    } else if (key === "--limit" && value) {
      options.limit = Number.parseInt(value, 10) || 0;
    } else if (key === "--batchSize" && value) {
      options.batchSize = Math.min(Number.parseInt(value, 10) || 400, 500);
    }
  }

  return options;
}

function cleanText(value) {
  if (value === undefined || value === null) return "";
  return String(value).trim();
}

function firstMediaUrl(data) {
  for (const field of ["imageUrl", "mediaUrl", "photoUrl"]) {
    const value = cleanText(data[field]);
    if (value) return {field, url: value};
  }

  return null;
}

function hasThumbnail(data) {
  return cleanText(data.thumbnailUrl) !== "" || cleanText(data.thumbUrl) !== "";
}

function summarizeDoc(doc) {
  const data = doc.data();
  const media = firstMediaUrl(data);
  if (!media || hasThumbnail(data)) return null;

  return {
    id: doc.id,
    mediaField: media.field,
    mediaUrl: media.url,
    businessId: cleanText(data.businessId),
    createdAt: data.createdAt && data.createdAt.toDate
      ? data.createdAt.toDate().toISOString()
      : cleanText(data.createdAt),
  };
}

async function auditCollection({db, collection, options}) {
  let seen = 0;
  let withMedia = 0;
  let withThumbnail = 0;
  let missingThumbnail = 0;
  let marked = 0;
  let lastDoc = null;
  const sample = [];

  while (options.limit === 0 || seen < options.limit) {
    const remaining = options.limit === 0 ? options.batchSize : options.limit - seen;
    let query = db
      .collection(collection)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(Math.min(options.batchSize, remaining));

    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snapshot = await query.get();
    if (snapshot.empty) break;

    let batch = db.batch();
    let batchWrites = 0;

    for (const doc of snapshot.docs) {
      seen += 1;
      lastDoc = doc;

      const data = doc.data();
      const media = firstMediaUrl(data);
      if (!media) continue;

      withMedia += 1;
      if (hasThumbnail(data)) {
        withThumbnail += 1;
        continue;
      }

      missingThumbnail += 1;
      const summary = summarizeDoc(doc);
      if (summary && sample.length < 20) sample.push(summary);

      if (!options.write) continue;

      batch.set(
        doc.ref,
        {
          needsThumbnailBackfill: true,
          thumbnailBackfillSourceField: media.field,
          thumbnailBackfillQueuedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
      batchWrites += 1;
      marked += 1;
    }

    if (options.write && batchWrites > 0) {
      await batch.commit();
      batch = db.batch();
    }

    if (snapshot.size < Math.min(options.batchSize, remaining)) break;
  }

  return {
    collection,
    seen,
    withMedia,
    withThumbnail,
    missingThumbnail,
    marked,
    sample,
  };
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  admin.initializeApp();
  const db = admin.firestore();

  const collections = [];
  for (const collection of options.collections) {
    collections.push(await auditCollection({db, collection, options}));
  }

  const totals = collections.reduce(
    (sum, item) => ({
      seen: sum.seen + item.seen,
      withMedia: sum.withMedia + item.withMedia,
      withThumbnail: sum.withThumbnail + item.withThumbnail,
      missingThumbnail: sum.missingThumbnail + item.missingThumbnail,
      marked: sum.marked + item.marked,
    }),
    {
      seen: 0,
      withMedia: 0,
      withThumbnail: 0,
      missingThumbnail: 0,
      marked: 0,
    },
  );

  console.log(
    JSON.stringify(
      {
        mode: options.write ? "write" : "dry-run",
        mediaFields: MEDIA_FIELDS,
        totals,
        collections,
      },
      null,
      2,
    ),
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
