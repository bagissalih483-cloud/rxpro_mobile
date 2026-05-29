"use strict";

const fs = require("fs");
const readline = require("readline");

const DEFAULT_COLLECTION = "businessPlaceIndex";

function parseArgs(argv) {
  const options = {
    file: "",
    collection: DEFAULT_COLLECTION,
    respectRecordCollection: false,
    write: false,
    limit: 0,
  };

  for (const arg of argv) {
    if (arg === "--write") {
      options.write = true;
      continue;
    }
    if (arg === "--respect-record-collection") {
      options.respectRecordCollection = true;
      continue;
    }

    const [key, ...rest] = arg.split("=");
    const value = rest.join("=").trim();
    if (!value) continue;

    if (key === "--file") {
      options.file = value;
    } else if (key === "--collection") {
      options.collection = value;
    } else if (key === "--limit") {
      options.limit = Math.max(Number.parseInt(value, 10) || 0, 0);
    }
  }

  return options;
}

function ensureGeoHashPayload(data) {
  const geohash = String(data.geohash || data.geo?.geohash || "").trim();
  if (!geohash) return data;

  return {
    ...data,
    geohash,
    geoHash: data.geoHash || geohash,
    geoHash4: data.geoHash4 || geohash.slice(0, 4),
    geoHash5: data.geoHash5 || geohash.slice(0, 5),
    geoHash6: data.geoHash6 || geohash.slice(0, 6),
    geoHash7: data.geoHash7 || geohash.slice(0, 7),
  };
}

function normalizeRecord(
  payload,
  fallbackLineNumber,
  collection,
  respectRecordCollection,
) {
  const data = payload && typeof payload === "object" ? payload.data : null;
  if (!data || typeof data !== "object") {
    throw new Error(`Line ${fallbackLineNumber}: data alani yok.`);
  }

  const docId = String(
    payload.docId || data.doc_id || data.source_place_id || "",
  ).trim();
  if (!docId) {
    throw new Error(`Line ${fallbackLineNumber}: docId bulunamadi.`);
  }

  return {
    collection: respectRecordCollection
      ? String(payload.collection || collection).trim() || collection
      : collection,
    docId,
    data: ensureGeoHashPayload(data),
  };
}

async function commitBatch(db, batchItems, write) {
  if (!write || batchItems.length === 0) return;

  const batch = db.batch();
  for (const item of batchItems) {
    batch.set(db.collection(item.collection).doc(item.docId), item.data, {
      merge: true,
    });
  }
  await batch.commit();
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (!options.file) {
    throw new Error("--file=rxpro_directory_firestore_import.jsonl gerekli.");
  }
  if (!fs.existsSync(options.file)) {
    throw new Error(`Dosya bulunamadi: ${options.file}`);
  }

  let db = null;
  if (options.write) {
    const admin = require("firebase-admin");
    admin.initializeApp();
    db = admin.firestore();
  }
  const stream = fs.createReadStream(options.file, { encoding: "utf8" });
  const reader = readline.createInterface({
    input: stream,
    crlfDelay: Infinity,
  });

  let lineNumber = 0;
  let valid = 0;
  let written = 0;
  let skipped = 0;
  const cityCounts = new Map();
  const categoryCounts = new Map();
  let batchItems = [];

  for await (const line of reader) {
    lineNumber += 1;
    const trimmed = line.trim();
    if (!trimmed) continue;

    if (options.limit > 0 && valid >= options.limit) {
      skipped += 1;
      continue;
    }

    const payload = JSON.parse(trimmed);
    const record = normalizeRecord(
      payload,
      lineNumber,
      options.collection,
      options.respectRecordCollection,
    );
    valid += 1;

    const city = String(record.data.city || "Bilinmeyen").trim();
    const category = String(record.data.category_key || "unknown").trim();
    cityCounts.set(city, (cityCounts.get(city) || 0) + 1);
    categoryCounts.set(category, (categoryCounts.get(category) || 0) + 1);

    batchItems.push(record);
    if (batchItems.length >= 400) {
      await commitBatch(db, batchItems, options.write);
      written += options.write ? batchItems.length : 0;
      batchItems = [];
    }
  }

  await commitBatch(db, batchItems, options.write);
  written += options.write ? batchItems.length : 0;

  console.log(
    JSON.stringify(
      {
        mode: options.write ? "write" : "dry-run",
        file: options.file,
        valid,
        written,
        skipped,
        cities: Object.fromEntries(cityCounts),
        categories: Object.fromEntries(categoryCounts),
      },
      null,
      2,
    ),
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
