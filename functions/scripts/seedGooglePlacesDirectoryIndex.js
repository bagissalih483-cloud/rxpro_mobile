"use strict";

const admin = require("firebase-admin");

const alphabet = "0123456789bcdefghjkmnpqrstuvwxyz";

const cityCenters = {
  istanbul: { label: "Istanbul", latitude: 41.0082, longitude: 28.9784 },
  ankara: { label: "Ankara", latitude: 39.9334, longitude: 32.8597 },
  izmir: { label: "Izmir", latitude: 38.4237, longitude: 27.1428 },
  antalya: { label: "Antalya", latitude: 36.8969, longitude: 30.7133 },
  bursa: { label: "Bursa", latitude: 40.1826, longitude: 29.0665 },
  gaziantep: { label: "Gaziantep", latitude: 37.0662, longitude: 37.3833 },
  konya: { label: "Konya", latitude: 37.8746, longitude: 32.4932 },
  adana: { label: "Adana", latitude: 37.0, longitude: 35.3213 },
};

const categoryTypes = {
  beauty_care: [
    "beauty_salon",
    "hair_salon",
    "barber_shop",
    "nail_salon",
    "spa",
    "skin_care_clinic",
  ],
  health_clinic: [
    "dental_clinic",
    "dentist",
    "medical_clinic",
    "medical_center",
    "doctor",
    "physiotherapist",
  ],
  sport_fitness: [
    "gym",
    "fitness_center",
    "sports_club",
    "yoga_studio",
  ],
};

function parseArgs(argv) {
  const options = {
    write: false,
    collection: "businessPlaceIndex",
    radiusMeters: 15000,
    maxResultCount: 20,
    cities: Object.keys(cityCenters),
    categories: Object.keys(categoryTypes),
  };

  for (const arg of argv) {
    if (arg === "--write") {
      options.write = true;
      continue;
    }

    const [key, value] = arg.split("=");
    if (!value) continue;

    if (key === "--collection") {
      options.collection = value;
    } else if (key === "--radiusMeters") {
      options.radiusMeters = Math.min(
        Math.max(Number.parseInt(value, 10) || 15000, 500),
        50000,
      );
    } else if (key === "--limit") {
      options.maxResultCount = Math.min(
        Math.max(Number.parseInt(value, 10) || 20, 1),
        20,
      );
    } else if (key === "--cities") {
      options.cities = value
        .split(",")
        .map((item) => item.trim().toLowerCase())
        .filter((item) => cityCenters[item]);
    } else if (key === "--categories") {
      options.categories = value
        .split(",")
        .map((item) => item.trim().toLowerCase())
        .filter((item) => categoryTypes[item]);
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

function cleanPlaceId(value) {
  return String(value || "").trim();
}

function safeDocId(placeId) {
  return placeId.replace(/[^a-zA-Z0-9_-]/g, "_");
}

async function fetchNearby({ apiKey, city, categoryId, radiusMeters, maxResultCount }) {
  const response = await fetch(
    "https://places.googleapis.com/v1/places:searchNearby",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": apiKey,
        "X-Goog-FieldMask": [
          "places.id",
          "places.location",
          "places.types",
          "places.businessStatus",
        ].join(","),
      },
      body: JSON.stringify({
        includedTypes: categoryTypes[categoryId],
        maxResultCount,
        locationRestriction: {
          circle: {
            center: {
              latitude: city.latitude,
              longitude: city.longitude,
            },
            radius: radiusMeters,
          },
        },
      }),
    },
  );

  const text = await response.text();
  const payload = text ? JSON.parse(text) : {};

  if (!response.ok) {
    throw new Error(
      `Places error ${response.status}: ${text ? text.slice(0, 500) : ""}`,
    );
  }

  return Array.isArray(payload.places) ? payload.places : [];
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const apiKey = process.env.GOOGLE_PLACES_API_KEY;

  if (!apiKey) {
    throw new Error("GOOGLE_PLACES_API_KEY env var gerekli.");
  }

  if (options.cities.length === 0 || options.categories.length === 0) {
    throw new Error("Gecerli sehir veya kategori bulunamadi.");
  }

  admin.initializeApp();
  const db = admin.firestore();

  let scanned = 0;
  let unique = 0;
  let written = 0;
  const seen = new Set();

  for (const cityKey of options.cities) {
    const city = cityCenters[cityKey];

    for (const categoryId of options.categories) {
      const places = await fetchNearby({
        apiKey,
        city,
        categoryId,
        radiusMeters: options.radiusMeters,
        maxResultCount: options.maxResultCount,
      });

      let batch = db.batch();
      let batchWrites = 0;

      for (const place of places) {
        scanned += 1;
        const placeId = cleanPlaceId(place.id);
        const latitude = Number(place.location && place.location.latitude);
        const longitude = Number(place.location && place.location.longitude);

        if (!placeId || !Number.isFinite(latitude) || !Number.isFinite(longitude)) {
          continue;
        }

        if (seen.has(placeId)) continue;
        seen.add(placeId);
        unique += 1;

        if (!options.write) continue;

        const ref = db.collection(options.collection).doc(safeDocId(placeId));
        batch.set(
          ref,
          {
            placeId,
            provider: "google_places",
            source: "google_places_seed",
            categoryId,
            types: Array.isArray(place.types) ? place.types : [],
            businessStatus: String(place.businessStatus || ""),
            seedCityKey: cityKey,
            seedCityLabel: city.label,
            seedRadiusMeters: options.radiusMeters,
            lat: latitude,
            lng: longitude,
            latitude,
            longitude,
            location: new admin.firestore.GeoPoint(latitude, longitude),
            ...geoPayload(latitude, longitude),
            indexedAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: admin.firestore.Timestamp.fromDate(
              new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
            ),
          },
          { merge: true },
        );
        batchWrites += 1;
        written += 1;

        if (batchWrites === 400) {
          await batch.commit();
          batch = db.batch();
          batchWrites = 0;
        }
      }

      if (options.write && batchWrites > 0) {
        await batch.commit();
      }

      console.log(
        `${city.label} / ${categoryId}: ${places.length} places scanned.`,
      );
    }
  }

  console.log(
    JSON.stringify(
      {
        dryRun: !options.write,
        collection: options.collection,
        scanned,
        unique,
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
