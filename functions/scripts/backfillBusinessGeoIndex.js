"use strict";

const admin = require("firebase-admin");

const alphabet = "0123456789bcdefghjkmnpqrstuvwxyz";

function parseArgs(argv) {
  const options = {
    write: false,
    collection: "businesses",
    limit: 0,
    batchSize: 400,
  };

  for (const arg of argv) {
    if (arg === "--write") {
      options.write = true;
      continue;
    }

    const [key, value] = arg.split("=");
    if (key === "--collection" && value) {
      options.collection = value;
    } else if (key === "--limit" && value) {
      options.limit = Number.parseInt(value, 10) || 0;
    } else if (key === "--batchSize" && value) {
      options.batchSize = Math.min(Number.parseInt(value, 10) || 400, 500);
    }
  }

  return options;
}

function encodeGeoHash(latitude, longitude, precision = 9) {
  let latMin = -90;
  let latMax = 90;
  let lngMin = -180;
  let lngMax = 180;
  let evenBit = true;
  let bit = 0;
  let ch = 0;
  let hash = "";

  while (hash.length < precision) {
    if (evenBit) {
      const mid = (lngMin + lngMax) / 2;
      if (longitude >= mid) {
        ch = (ch << 1) + 1;
        lngMin = mid;
      } else {
        ch <<= 1;
        lngMax = mid;
      }
    } else {
      const mid = (latMin + latMax) / 2;
      if (latitude >= mid) {
        ch = (ch << 1) + 1;
        latMin = mid;
      } else {
        ch <<= 1;
        latMax = mid;
      }
    }

    evenBit = !evenBit;

    if (++bit === 5) {
      hash += alphabet[ch];
      bit = 0;
      ch = 0;
    }
  }

  return hash;
}

function geoPayload(latitude, longitude) {
  const geoHash = encodeGeoHash(latitude, longitude);
  return {
    geoHash,
    geoHash4: geoHash.slice(0, 4),
    geoHash5: geoHash.slice(0, 5),
    geoHash6: geoHash.slice(0, 6),
    geoHash7: geoHash.slice(0, 7),
  };
}

function toNumber(value) {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value !== "string") return null;

  const normalized = value.trim().replace(",", ".");
  if (!normalized) return null;

  const parsed = Number.parseFloat(normalized);
  return Number.isFinite(parsed) ? parsed : null;
}

function firstNumber(values) {
  for (const value of values) {
    const parsed = toNumber(value);
    if (parsed !== null) return parsed;
  }

  return null;
}

function readCoordinate(data) {
  const location = data.location;
  const geometryLocation = data.geometry && data.geometry.location;

  const latitude = firstNumber([
    data.lat,
    data.latitude,
    location && location.latitude,
    geometryLocation && geometryLocation.lat,
    geometryLocation && geometryLocation.latitude,
  ]);
  const longitude = firstNumber([
    data.lng,
    data.lon,
    data.longitude,
    location && location.longitude,
    geometryLocation && geometryLocation.lng,
    geometryLocation && geometryLocation.longitude,
  ]);

  if (latitude === null || longitude === null) return null;
  if (latitude < -90 || latitude > 90) return null;
  if (longitude < -180 || longitude > 180) return null;

  return {latitude, longitude};
}

function needsUpdate(data, payload) {
  return (
    data.geoHash !== payload.geoHash ||
    data.geoHash4 !== payload.geoHash4 ||
    data.geoHash5 !== payload.geoHash5 ||
    data.geoHash6 !== payload.geoHash6 ||
    data.geoHash7 !== payload.geoHash7
  );
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  admin.initializeApp();
  const db = admin.firestore();

  let seen = 0;
  let withCoordinate = 0;
  let missingCoordinate = 0;
  let alreadyIndexed = 0;
  let pendingUpdate = 0;
  let written = 0;
  let lastDoc = null;

  while (options.limit === 0 || seen < options.limit) {
    const remaining = options.limit === 0 ? options.batchSize : options.limit - seen;
    let query = db
      .collection(options.collection)
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
      const coordinate = readCoordinate(data);
      if (!coordinate) {
        missingCoordinate += 1;
        continue;
      }

      withCoordinate += 1;
      const payload = geoPayload(coordinate.latitude, coordinate.longitude);
      if (!needsUpdate(data, payload)) {
        alreadyIndexed += 1;
        continue;
      }

      pendingUpdate += 1;
      if (!options.write) continue;

      const update = {
        ...payload,
        lat: coordinate.latitude,
        lng: coordinate.longitude,
        latitude: coordinate.latitude,
        longitude: coordinate.longitude,
        location: new admin.firestore.GeoPoint(
          coordinate.latitude,
          coordinate.longitude,
        ),
        locationUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        geoIndexBackfilledAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      if (!data.locationSource) {
        update.locationSource = "geo_index_backfill";
      }

      batch.set(doc.ref, update, {merge: true});
      batchWrites += 1;
      written += 1;
    }

    if (options.write && batchWrites > 0) {
      await batch.commit();
      batch = db.batch();
    }

    if (snapshot.size < Math.min(options.batchSize, remaining)) break;
  }

  console.log(
    JSON.stringify(
      {
        mode: options.write ? "write" : "dry-run",
        collection: options.collection,
        seen,
        withCoordinate,
        missingCoordinate,
        alreadyIndexed,
        pendingUpdate,
        written,
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
