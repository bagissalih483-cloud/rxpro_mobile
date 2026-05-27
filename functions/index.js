const functions = require('firebase-functions');
const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");
const GOOGLE_PLACES_API_KEY = defineSecret("GOOGLE_PLACES_API_KEY");
const BUSINESS_PLACE_INDEX_COLLECTION = "businessPlaceIndex";
const PLACE_QUERY_BUCKETS_COLLECTION = "placeQueryBuckets";
const PLACE_DIRECTORY_CACHE_DAYS = 30;
const GEOHASH_ALPHABET = "0123456789bcdefghjkmnpqrstuvwxyz";

function cleanText(value, fallback = "") {
  if (value === undefined || value === null) return fallback;
  return String(value).trim() || fallback;
}

function safeSecretValue(secret, name) {
  try {
    return cleanText(secret.value() || process.env[name]);
  } catch (error) {
    console.error(`${name} secret okunamadi:`, {
      message: error && error.message ? error.message : String(error)
    });
    return cleanText(process.env[name]);
  }
}

function normalizePlacesApiKey(value) {
  const raw = cleanText(value);
  if (!raw) return "";

  const direct = raw.match(/^AIza[0-9A-Za-z_-]{20,}$/);
  if (direct) return raw;

  const embedded = raw.match(/AIza[0-9A-Za-z_-]{20,}/);
  return embedded ? embedded[0] : "";
}

const DIRECTORY_PLACE_TYPE_GROUPS = {
  beauty_care: [
    "beauty_salon",
    "hair_salon",
    "barber_shop",
    "nail_salon",
    "spa",
    "skin_care_clinic"
  ],
  health_clinic: [
    "dental_clinic",
    "dentist",
    "medical_clinic",
    "medical_center",
    "doctor",
    "physiotherapist"
  ],
  sport_fitness: [
    "gym",
    "fitness_center",
    "sports_club",
    "yoga_studio"
  ]
};

const DIRECTORY_PLACE_TYPE_FALLBACKS = {
  beauty_care: ["beauty_salon", "hair_salon", "nail_salon", "spa"],
  health_clinic: ["dental_clinic", "dentist", "doctor", "physiotherapist"],
  sport_fitness: ["gym", "fitness_center", "sports_club"]
};

const PLACES_NEARBY_FIELD_MASK = [
  "places.id",
  "places.displayName",
  "places.formattedAddress",
  "places.location",
  "places.types",
  "places.googleMapsUri",
  "places.rating",
  "places.userRatingCount",
  "places.nationalPhoneNumber",
  "places.businessStatus",
  "places.websiteUri"
].join(",");

function normalizeDirectoryText(value) {
  return cleanText(value)
    .toLowerCase()
    .replace(/ı/g, "i")
    .replace(/İ/g, "i")
    .replace(/ğ/g, "g")
    .replace(/ü/g, "u")
    .replace(/ş/g, "s")
    .replace(/ö/g, "o")
    .replace(/ç/g, "c");
}

function directoryCategoryId(data) {
  const rawId = normalizeDirectoryText(data.categoryId);
  if (DIRECTORY_PLACE_TYPE_GROUPS[rawId]) return rawId;

  const label = normalizeDirectoryText(data.categoryLabel || data.category);
  if (!label || label === "tumu" || label === "all") return "all";

  if (
    label.includes("guzellik") ||
    label.includes("bakim") ||
    label.includes("beauty") ||
    label.includes("hair") ||
    label.includes("spa")
  ) {
    return "beauty_care";
  }

  if (
    label.includes("saglik") ||
    label.includes("klinik") ||
    label.includes("dis") ||
    label.includes("dental") ||
    label.includes("doctor")
  ) {
    return "health_clinic";
  }

  if (
    label.includes("spor") ||
    label.includes("fitness") ||
    label.includes("gym") ||
    label.includes("pilates") ||
    label.includes("yoga")
  ) {
    return "sport_fitness";
  }

  return "all";
}

function directoryTypesForCategory(categoryId) {
  if (DIRECTORY_PLACE_TYPE_GROUPS[categoryId]) {
    return DIRECTORY_PLACE_TYPE_GROUPS[categoryId];
  }

  return Array.from(
    new Set(Object.values(DIRECTORY_PLACE_TYPE_GROUPS).flat()),
  );
}

function fallbackDirectoryTypesForCategory(categoryId) {
  if (DIRECTORY_PLACE_TYPE_FALLBACKS[categoryId]) {
    return DIRECTORY_PLACE_TYPE_FALLBACKS[categoryId];
  }

  return Array.from(
    new Set(Object.values(DIRECTORY_PLACE_TYPE_FALLBACKS).flat()),
  );
}

function directoryTypeQueriesForCategory(categoryId, fallback = false) {
  const groups = fallback
    ? DIRECTORY_PLACE_TYPE_FALLBACKS
    : DIRECTORY_PLACE_TYPE_GROUPS;
  const categoryIds =
    categoryId === "all" ? Object.keys(groups) : [categoryId];
  const maxLength = Math.max(
    ...categoryIds.map((id) => (groups[id] || []).length),
    0,
  );
  const queries = [];

  for (let index = 0; index < maxLength; index += 1) {
    for (const id of categoryIds) {
      const type = groups[id] && groups[id][index];
      if (!type) continue;
      queries.push({
        categoryId: id,
        includedTypes: [type]
      });
    }
  }

  return queries;
}

function uniquePlacesById(places) {
  const byId = new Map();
  for (const place of places) {
    const id = cleanText(place && (place.id || place.name));
    if (!id || byId.has(id)) continue;
    byId.set(id, place);
  }

  return Array.from(byId.values());
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
      hash += GEOHASH_ALPHABET[ch];
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

function safePlaceDocId(placeId) {
  return cleanText(placeId).replace(/[^a-zA-Z0-9_-]/g, "_");
}

function parseTurkeyAddressParts(address) {
  const text = cleanText(address);
  if (!text) {
    return { city: "", district: "", areaLabel: "" };
  }

  const parts = text
    .split(",")
    .map((part) => cleanText(part))
    .filter(Boolean);
  const withoutCountry = parts.filter((part) => {
    const normalized = normalizeDirectoryText(part);
    return normalized !== "turkiye" && normalized !== "turkey";
  });
  const joined = withoutCountry.join(", ");
  const slashMatch = joined.match(/([^,\/]+)\/([^,]+)/);

  if (slashMatch) {
    const district = cleanText(slashMatch[1]);
    const city = cleanText(slashMatch[2]);
    return {
      city,
      district,
      areaLabel: [district, city].filter(Boolean).join(" / "),
    };
  }

  const city = withoutCountry.length >= 2
    ? withoutCountry[withoutCountry.length - 1]
    : "";
  const district = withoutCountry.length >= 3
    ? withoutCountry[withoutCountry.length - 2]
    : "";

  return {
    city,
    district,
    areaLabel: [district, city].filter(Boolean).join(" / "),
  };
}

function distanceKmBetween(fromLat, fromLng, toLat, toLng) {
  if (
    !Number.isFinite(fromLat) ||
    !Number.isFinite(fromLng) ||
    !Number.isFinite(toLat) ||
    !Number.isFinite(toLng)
  ) {
    return Number.POSITIVE_INFINITY;
  }

  const toRadians = (value) => (value * Math.PI) / 180;
  const earthKm = 6371;
  const dLat = toRadians(toLat - fromLat);
  const dLng = toRadians(toLng - fromLng);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(fromLat)) *
      Math.cos(toRadians(toLat)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);

  return earthKm * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

async function fetchNearbyPlaces({
  apiKey,
  latitude,
  longitude,
  radiusMeters,
  maxResultCount,
  includedTypes,
}) {
  const response = await fetch(
    "https://places.googleapis.com/v1/places:searchNearby",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": apiKey,
        "X-Goog-FieldMask": PLACES_NEARBY_FIELD_MASK
      },
      body: JSON.stringify({
        includedTypes,
        maxResultCount,
        locationRestriction: {
          circle: {
            center: {
              latitude,
              longitude
            },
            radius: radiusMeters
          }
        }
      })
    },
  );

  const text = await response.text();
  let payload = {};
  try {
    payload = text ? JSON.parse(text) : {};
  } catch (_) {
    payload = {};
  }

  return {
    ok: response.ok,
    status: response.status,
    text,
    payload,
    message:
      payload && payload.error && payload.error.message
        ? String(payload.error.message)
        : response.ok
          ? ""
          : "Google Places istegi basarisiz."
  };
}

function categoryLabelForPlaceTypes(types) {
  const set = new Set(Array.isArray(types) ? types : []);

  if (
    DIRECTORY_PLACE_TYPE_GROUPS.beauty_care.some((type) => set.has(type))
  ) {
    return "Güzellik & Bakım";
  }

  if (
    DIRECTORY_PLACE_TYPE_GROUPS.health_clinic.some((type) => set.has(type))
  ) {
    return "Sağlık & Klinik";
  }

  if (
    DIRECTORY_PLACE_TYPE_GROUPS.sport_fitness.some((type) => set.has(type))
  ) {
    return "Spor & Fitness";
  }

  return "Diğer Hizmetler";
}

function toFiniteNumber(value, fallback = null) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function clampNumber(value, min, max, fallback) {
  const parsed = toFiniteNumber(value, fallback);
  return Math.min(Math.max(parsed, min), max);
}

function normalizeGooglePlace(place) {
  const location = place.location || {};
  const types = Array.isArray(place.types) ? place.types : [];
  const placeId = cleanText(place.id || place.name);
  const displayName = place.displayName || {};
  const name = cleanText(displayName.text, "İsimsiz işletme");
  const latitude = toFiniteNumber(location.latitude);
  const longitude = toFiniteNumber(location.longitude);
  const address = cleanText(place.formattedAddress);
  const area = parseTurkeyAddressParts(address);

  return {
    id: placeId ? `google_${placeId}` : `google_${name}`,
    name,
    businessName: name,
    displayName: { text: name },
    category: categoryLabelForPlaceTypes(types),
    categoryLabel: categoryLabelForPlaceTypes(types),
    businessCategory: categoryLabelForPlaceTypes(types),
    formattedAddress: address,
    address,
    city: area.city,
    district: area.district,
    areaLabel: area.areaLabel,
    nationalPhoneNumber: cleanText(place.nationalPhoneNumber),
    phone: cleanText(place.nationalPhoneNumber),
    googleMapsUri: cleanText(place.googleMapsUri),
    mapsUrl: cleanText(place.googleMapsUri),
    websiteUri: cleanText(place.websiteUri),
    placeId,
    googlePlaceId: placeId,
    types,
    location: {
      latitude,
      longitude
    },
    lat: latitude,
    lng: longitude,
    ratingAvg: toFiniteNumber(place.rating, 0),
    ratingCount: Math.max(0, Math.round(toFiniteNumber(place.userRatingCount, 0))),
    businessStatus: cleanText(place.businessStatus),
    isRxProMember: false,
    isClaimed: false,
    source: "google_places_live",
    provider: "google_places",
    directoryOnly: true
  };
}

async function upsertDirectoryCache(items, context) {
  const writableItems = items
    .filter((item) =>
      cleanText(item.placeId) &&
      Number.isFinite(item.lat) &&
      Number.isFinite(item.lng)
    )
    .slice(0, 120);

  if (writableItems.length === 0) return 0;

  const now = admin.firestore.Timestamp.now();
  const expiresAt = admin.firestore.Timestamp.fromMillis(
    Date.now() + PLACE_DIRECTORY_CACHE_DAYS * 24 * 60 * 60 * 1000,
  );
  const queryGeoHash5 = encodeGeoHash(context.latitude, context.longitude, 5);
  const batch = db.batch();

  for (const item of writableItems) {
    const docId = safePlaceDocId(item.placeId);
    if (!docId) continue;

    const geo = geoPayload(item.lat, item.lng);
    const docRef = db
      .collection(BUSINESS_PLACE_INDEX_COLLECTION)
      .doc(docId);

    batch.set(
      docRef,
      {
        ...geo,
        id: `google_${item.placeId}`,
        placeId: item.placeId,
        googlePlaceId: item.placeId,
        businessName: cleanText(item.businessName || item.name, "İşletme"),
        name: cleanText(item.name || item.businessName, "İşletme"),
        category: item.category,
        categoryLabel: item.categoryLabel,
        businessCategory: item.businessCategory,
        address: item.address,
        formattedAddress: item.formattedAddress || item.address,
        city: cleanText(item.city),
        district: cleanText(item.district),
        areaLabel: cleanText(item.areaLabel),
        lat: item.lat,
        lng: item.lng,
        location: { latitude: item.lat, longitude: item.lng },
        mapsUrl: cleanText(item.mapsUrl || item.googleMapsUri),
        googleMapsUri: cleanText(item.googleMapsUri || item.mapsUrl),
        phone: cleanText(item.phone || item.nationalPhoneNumber),
        nationalPhoneNumber: cleanText(item.nationalPhoneNumber || item.phone),
        ratingAvg: item.ratingAvg || 0,
        ratingCount: item.ratingCount || 0,
        types: item.types || [],
        businessStatus: cleanText(item.businessStatus),
        source: "google_places_cache",
        provider: "google_places",
        directoryOnly: true,
        isRxProMember: false,
        isClaimed: false,
        visible: true,
        cachePolicy: "place_directory_snapshot",
        cacheExpiresAt: expiresAt,
        firstSeenAt: now,
        lastSeenAt: now,
        lastQueryCategoryId: context.categoryId,
        lastQueryRadiusMeters: context.radiusMeters,
        queryGeoHash5,
      },
      { merge: true },
    );
  }

  const areaItem =
    writableItems.find((item) =>
      cleanText(item.city) ||
      cleanText(item.district) ||
      cleanText(item.areaLabel),
    ) || writableItems[0];
  const bucketCity = cleanText(areaItem.city, "unknown");
  const bucketDistrict = cleanText(areaItem.district, "unknown");
  const bucketCategory = cleanText(context.categoryId, "all");
  const bucketRadius = Math.round(toFiniteNumber(context.radiusMeters, 0));
  const bucketId = safePlaceDocId(
    [
      bucketCity,
      bucketDistrict,
      bucketCategory,
      bucketRadius,
      queryGeoHash5
    ].join("_"),
  );

  batch.set(
    db.collection(PLACE_QUERY_BUCKETS_COLLECTION).doc(bucketId),
    {
      city: bucketCity,
      district: bucketDistrict,
      areaLabel: cleanText(areaItem.areaLabel),
      categoryId: bucketCategory,
      radiusMeters: bucketRadius,
      center: {
        latitude: context.latitude,
        longitude: context.longitude,
      },
      queryGeoHash5,
      itemCount: writableItems.length,
      placeIds: writableItems
        .map((item) => cleanText(item.placeId))
        .filter(Boolean)
        .slice(0, 120),
      source: "google_places_cache",
      cachePolicy: "place_query_bucket",
      cacheExpiresAt: expiresAt,
      lastFetchedAt: now,
    },
    { merge: true },
  );

  await batch.commit();
  return writableItems.length;
}

exports.searchNearbyDirectoryBusinesses = onCall(
  {
    region: "europe-west1",
    secrets: [GOOGLE_PLACES_API_KEY],
    timeoutSeconds: 30,
    memory: "256MiB"
  },
  async (request) => {
    const data = request.data || {};
    const latitude = toFiniteNumber(data.latitude);
    const longitude = toFiniteNumber(data.longitude);
    const rawApiKey = safeSecretValue(
      GOOGLE_PLACES_API_KEY,
      "GOOGLE_PLACES_API_KEY",
    );
    const apiKey = normalizePlacesApiKey(rawApiKey);

    if (data.healthCheck === true) {
      return {
        ok: true,
        source: "rxpro_places_proxy",
        secretConfigured: Boolean(rawApiKey),
        secretLooksValid: Boolean(apiKey),
        supportedCategories: Object.keys(DIRECTORY_PLACE_TYPE_GROUPS),
        revision: "66D_places_directory_cache"
      };
    }

    if (latitude === null || latitude < -90 || latitude > 90) {
      throw new HttpsError("invalid-argument", "latitude gecersiz.");
    }

    if (longitude === null || longitude < -180 || longitude > 180) {
      throw new HttpsError("invalid-argument", "longitude gecersiz.");
    }

    if (!apiKey) {
      throw new HttpsError(
        "failed-precondition",
        rawApiKey
          ? "GOOGLE_PLACES_API_KEY secret gecersiz. Secret degeri sadece API key olmali."
          : "GOOGLE_PLACES_API_KEY secret tanimli degil.",
      );
    }

    const radiusMeters = clampNumber(data.radiusMeters, 500, 50000, 10000);
    const maxResultCount = Math.round(clampNumber(data.limit, 1, 80, 60));
    const maxSearchCalls = Math.round(clampNumber(data.maxSearchCalls, 1, 20, 10));
    const categoryId = directoryCategoryId(data);
    const plannedQueries = directoryTypeQueriesForCategory(categoryId)
      .slice(0, maxSearchCalls);
    const debug = data.debug === true;

    try {
      const placesByQuery = [];
      let successfulCalls = 0;
      let skippedCalls = 0;

      const runQuery = async (query) => ({
        query,
        result: await fetchNearbyPlaces({
          apiKey,
          latitude,
          longitude,
          radiusMeters,
          maxResultCount: 20,
          includedTypes: query.includedTypes,
        })
      });

      const queryResults = await Promise.all(plannedQueries.map(runQuery));

      for (const { query, result } of queryResults) {
        if (!result.ok && result.status === 400) {
          skippedCalls += 1;
          continue;
        }

        if (!result.ok) {
          const debugMessage =
            `Google Places hatasi (${result.status}): ${result.message.slice(0, 220)}`;
          console.error("searchNearbyDirectoryBusinesses Places error:", {
            status: result.status,
            message: result.message,
            body: result.text ? result.text.slice(0, 1000) : "",
            categoryId: query.categoryId,
            includedTypes: query.includedTypes
          });
          throw new HttpsError(
            "unavailable",
            debug ? debugMessage : "Google Places yakindaki isletmeleri donduremedi.",
            {
              status: result.status,
              placesMessage: result.message,
              categoryId: query.categoryId
            },
          );
        }

        successfulCalls += 1;
        const categoryPlaces = Array.isArray(result.payload.places)
          ? result.payload.places
          : [];
        placesByQuery.push(...categoryPlaces);
      }

      if (placesByQuery.length === 0 && skippedCalls > 0) {
        const fallbackQueries = directoryTypeQueriesForCategory(categoryId, true)
          .slice(0, maxSearchCalls);
        const fallbackResults = await Promise.all(fallbackQueries.map(runQuery));
        for (const { result } of fallbackResults) {
          if (!result.ok) continue;
          successfulCalls += 1;
          const categoryPlaces = Array.isArray(result.payload.places)
            ? result.payload.places
            : [];
          placesByQuery.push(...categoryPlaces);
        }
      }

      const places = uniquePlacesById(placesByQuery);
      const items = places
        .map(normalizeGooglePlace)
        .filter((item) => item.placeId && item.lat !== null && item.lng !== null)
        .filter((item) => !item.businessStatus || item.businessStatus === "OPERATIONAL")
        .sort((a, b) =>
          distanceKmBetween(latitude, longitude, a.lat, a.lng) -
          distanceKmBetween(latitude, longitude, b.lat, b.lng)
        )
        .slice(0, maxResultCount);
      const cachedItems = await upsertDirectoryCache(items, {
        latitude,
        longitude,
        categoryId,
        radiusMeters,
      });

      return {
        ok: true,
        source: "google_places_live",
        categoryId,
        radiusMeters,
        queryCount: plannedQueries.length,
        successfulCalls,
        skippedCalls,
        cachedItems,
        items
      };
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }

      const runtimeMessage = error && error.message ? error.message : String(error);
      console.error("searchNearbyDirectoryBusinesses runtime error:", {
        message: runtimeMessage,
        categoryId,
        radiusMeters
      });
      throw new HttpsError(
        "unavailable",
        debug
          ? `Places runtime hatasi: ${runtimeMessage.slice(0, 240)}`
          : "Yakindaki isletme servisi su anda yanit veremiyor.",
        {
          runtimeMessage,
          categoryId,
          radiusMeters
        },
      );
    }
  },
);

function parseGoogleDurationSeconds(value) {
  if (typeof value === "number" && Number.isFinite(value)) {
    return Math.max(0, Math.round(value));
  }

  const text = cleanText(value);
  const match = text.match(/^(\d+(?:\.\d+)?)s$/);
  if (!match) return 0;

  return Math.max(0, Math.round(Number(match[1])));
}

async function fetchBusinessRouteInfo({
  apiKey,
  originLatitude,
  originLongitude,
  destinationLatitude,
  destinationLongitude,
}) {
  const response = await fetch(
    "https://routes.googleapis.com/directions/v2:computeRoutes",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": apiKey,
        "X-Goog-FieldMask": "routes.distanceMeters,routes.duration"
      },
      body: JSON.stringify({
        origin: {
          location: {
            latLng: {
              latitude: originLatitude,
              longitude: originLongitude
            }
          }
        },
        destination: {
          location: {
            latLng: {
              latitude: destinationLatitude,
              longitude: destinationLongitude
            }
          }
        },
        travelMode: "DRIVE",
        routingPreference: "TRAFFIC_UNAWARE",
        languageCode: "tr-TR",
        units: "METRIC"
      })
    },
  );

  const text = await response.text();
  let payload = {};
  try {
    payload = text ? JSON.parse(text) : {};
  } catch (_) {
    payload = {};
  }

  return {
    ok: response.ok,
    status: response.status,
    text,
    payload,
    message:
      payload && payload.error && payload.error.message
        ? String(payload.error.message)
        : response.ok
          ? ""
          : "Google Routes istegi basarisiz."
  };
}

exports.calculateBusinessRouteInfo = onCall(
  {
    region: "europe-west1",
    secrets: [GOOGLE_PLACES_API_KEY],
    timeoutSeconds: 15,
    memory: "256MiB"
  },
  async (request) => {
    const data = request.data || {};
    const originLatitude = toFiniteNumber(data.originLatitude);
    const originLongitude = toFiniteNumber(data.originLongitude);
    const destinationLatitude = toFiniteNumber(data.destinationLatitude);
    const destinationLongitude = toFiniteNumber(data.destinationLongitude);
    const rawApiKey = safeSecretValue(
      GOOGLE_PLACES_API_KEY,
      "GOOGLE_PLACES_API_KEY",
    );
    const apiKey = normalizePlacesApiKey(rawApiKey);

    if (data.healthCheck === true) {
      return {
        ok: true,
        source: "rxpro_routes_proxy",
        secretConfigured: Boolean(rawApiKey),
        secretLooksValid: Boolean(apiKey),
        revision: "66N_route_distance"
      };
    }

    if (
      originLatitude === null ||
      originLatitude < -90 ||
      originLatitude > 90 ||
      destinationLatitude === null ||
      destinationLatitude < -90 ||
      destinationLatitude > 90
    ) {
      throw new HttpsError("invalid-argument", "latitude gecersiz.");
    }

    if (
      originLongitude === null ||
      originLongitude < -180 ||
      originLongitude > 180 ||
      destinationLongitude === null ||
      destinationLongitude < -180 ||
      destinationLongitude > 180
    ) {
      throw new HttpsError("invalid-argument", "longitude gecersiz.");
    }

    if (!apiKey) {
      throw new HttpsError(
        "failed-precondition",
        rawApiKey
          ? "GOOGLE_PLACES_API_KEY secret gecersiz."
          : "GOOGLE_PLACES_API_KEY secret tanimli degil.",
      );
    }

    try {
      const result = await fetchBusinessRouteInfo({
        apiKey,
        originLatitude,
        originLongitude,
        destinationLatitude,
        destinationLongitude,
      });

      if (!result.ok) {
        console.error("calculateBusinessRouteInfo Routes error:", {
          status: result.status,
          message: result.message,
          body: result.text ? result.text.slice(0, 1000) : ""
        });
        throw new HttpsError(
          "unavailable",
          "Rota mesafesi su anda hesaplanamiyor.",
          {
            status: result.status,
            routesMessage: result.message
          },
        );
      }

      const routes = Array.isArray(result.payload.routes)
        ? result.payload.routes
        : [];
      const route = routes[0] || {};
      const distanceMeters = Math.max(
        0,
        Math.round(toFiniteNumber(route.distanceMeters, 0)),
      );
      const durationSeconds = parseGoogleDurationSeconds(route.duration);

      return {
        ok: true,
        source: "google_routes",
        travelMode: "DRIVE",
        distanceMeters,
        distanceKm: distanceMeters / 1000,
        durationSeconds
      };
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }

      const runtimeMessage = error && error.message ? error.message : String(error);
      console.error("calculateBusinessRouteInfo runtime error:", {
        message: runtimeMessage
      });
      throw new HttpsError(
        "unavailable",
        "Rota mesafesi su anda hesaplanamiyor.",
        { runtimeMessage },
      );
    }
  },
);


function makeCleanFallbackVariant(data, name, layout, palette, note) {
  const businessName = cleanText(data.businessName, "İşletmemiz");
  const serviceName = cleanText(data.serviceName, "seçili hizmet");
  const discountType = cleanText(data.discountType, "kampanya");
  const discountValue = cleanText(data.discountValue, "");
  const targetAudience = cleanText(data.targetAudience, "müşterilerimiz");
  const dateBadgeText = cleanText(data.dateBadgeText, "");

  const discountText =
    discountType.includes("Yüzde") && discountValue
      ? `%${discountValue}`
      : discountType.includes("Sabit") && discountValue
        ? `${discountValue} TL indirim`
        : "özel avantaj";

  return {
    variantName: name,
    strategyNote: note,
    title:
      name === "Premium Güven"
        ? `${serviceName} İçin Seçkin Avantaj`
        : name === "Fiyat Fırsatı"
          ? `${discountText} Fırsatını Kaçırma`
          : `${serviceName} Randevunu Planla`,
    description:
      `${businessName}, ${targetAudience} için ${serviceName} kapsamında avantajlı bir kampanya sunuyor. ` +
      `Randevunuzu oluşturarak bu fırsattan yararlanabilir, hizmeti güvenli ve planlı şekilde deneyimleyebilirsiniz.`,
    terms:
      "Kampanya sınırlı süreyle geçerlidir. Randevu uygunluğuna göre hizmet verilir.",
    cta:
      name === "Premium Güven"
        ? "Deneyimi Planla"
        : name === "Fiyat Fırsatı"
          ? "Fırsattan Yararlan"
          : "Randevunu Oluştur",
    badge: "KAMPANYA",
    dateBadgeText,
    targetAudienceLabel: targetAudience,
    layoutVariant: layout,
    cardDesignSuggestion: "Modern Gradient",
    paletteSuggestion: palette,
    fontStyleSuggestion: layout === "premiumMinimal" ? "elegant" : "modernBold",
    highlightText: discountText,
    benefitBullets: [
      "Net ve avantajlı kampanya",
      "Kolay randevu oluşturma",
      "Sınırlı süreli fırsat"
    ],
    confidenceNote: "Güvenli fallback varyantı"
  };
}

function buildCampaignCreativePrompt(data) {
  const businessName = cleanText(data.businessName, "İşletmemiz");
  const serviceName = cleanText(data.serviceName, "Seçili hizmet");
  const campaignType = cleanText(data.campaignType, "Kampanya");
  const targetAudience = cleanText(data.targetAudience, "Herkes");
  const discountType = cleanText(data.discountType, "Yüzde İndirim");
  const discountValue = cleanText(data.discountValue, "");
  const tone = cleanText(data.tone, "Profesyonel");
  const managerBrief = cleanText(data.managerBrief, "");
  const startDateText = cleanText(data.startDateText, "");
  const endDateText = cleanText(data.endDateText, "");
  const dateEmphasisType = cleanText(data.dateEmphasisType, "Tarih vurgusu kullanma");
  const dateBadgeText = cleanText(data.dateBadgeText, "");

  return `
Sadece geçerli JSON nesnesi döndür. Markdown, açıklama ve kod bloğu kullanma.

Rol:
Sen RxPro uygulamasındaki "kampanya kreatif direktörüsün".
Form dolduran bir araç değilsin. İşletme sahibinin hedefini analiz eden, müşteriyi ikna edecek reklam açısını seçen ve kartın tamamını profesyonelce kurgulayan pazarlama asistanısın.

Girdi:
İşletme adı: ${businessName}
Hizmet: ${serviceName}
Kampanya türü: ${campaignType}
Hedef müşteri: ${targetAudience}
İndirim tipi: ${discountType}
İndirim değeri: ${discountValue}
Ton: ${tone}
Yönetici isteği: ${managerBrief}
Başlangıç tarihi: ${startDateText}
Bitiş tarihi: ${endDateText}
Tarih vurgu tipi: ${dateEmphasisType}
Mevcut tarih rozeti: ${dateBadgeText}

Profesyonel kalite kuralları:
- Türkçe yaz.
- Yönetici isteğini analiz et, ama aynen kopyalama.
- Argo, kaba, alaycı, anlamsız, marka değerini düşüren veya amatör kelimeleri başlık/açıklamada aynen kullanma.
- Kullanıcı özellikle kötü kelime istese bile bunu profesyonel kampanya diline dönüştür.
- "banane", "sanane", "şok şok", "efsane patladı" gibi ifadeleri doğrudan kullanma; niyetini profesyonel hale getir.
- "hizmet hizmetinde" gibi tekrar yapma.
- Başlık en fazla 7 kelime olsun.
- Açıklama 45-75 kelime arasında olsun.
- CTA en fazla 4 kelime olsun.
- Koşullar kısa ve güvenli olsun.
- Tarih varsa dateBadgeText müşteriye anlaşılır şekilde yazılsın.
- Her alternatif gerçekten farklı stratejiye sahip olsun.
- Varyantlar birbirinin yeniden yazılmış kopyası olmasın.

Kart stratejileri:
1. Premium Güven:
   - Amaç: kalite, titizlik, güven, özen, seçkin hizmet algısı.
   - layoutVariant: premiumMinimal
   - paletteSuggestion: Siyah / Altın veya Lacivert / Gümüş
   - fontStyleSuggestion: elegant
   - CTA örnekleri: Deneyimi Planla, Randevunu Ayır

2. Fiyat Fırsatı:
   - Amaç: indirim/fırsat/vade/tarih ile hızlı karar aldırmak.
   - layoutVariant: priceFocus
   - paletteSuggestion: Turuncu / Krem veya Mor / Turkuaz
   - fontStyleSuggestion: modernBold
   - CTA örnekleri: Fırsattan Yararlan, Hemen Randevu Al

3. Fayda Odaklı:
   - Amaç: hizmetin müşteri faydasını 3 kısa maddeyle anlatmak.
   - layoutVariant: benefitList
   - paletteSuggestion: Mor / Turkuaz, Pastel Pembe veya Mint / Beyaz
   - fontStyleSuggestion: friendly veya corporateClean
   - CTA örnekleri: Randevunu Oluştur, Bakımını Planla

İzin verilen değerler:
layoutVariant: hero, priceFocus, benefitList, premiumMinimal
paletteSuggestion: Mor / Turkuaz, Siyah / Altın, Pastel Pembe, Mint / Beyaz, Lacivert / Gümüş, Turuncu / Krem, Yeşil / Doğal, Clean White
fontStyleSuggestion: modernBold, elegant, friendly, corporateClean

Zorunlu JSON formatı:
{
  "variants": [
    {
      "variantName": "Premium Güven",
      "strategyNote": "string",
      "title": "string",
      "description": "string",
      "terms": "string",
      "cta": "string",
      "badge": "string",
      "dateBadgeText": "string",
      "targetAudienceLabel": "string",
      "layoutVariant": "premiumMinimal",
      "cardDesignSuggestion": "string",
      "paletteSuggestion": "string",
      "fontStyleSuggestion": "string",
      "highlightText": "string",
      "benefitBullets": ["string", "string", "string"],
      "confidenceNote": "string"
    },
    {
      "variantName": "Fiyat Fırsatı",
      "strategyNote": "string",
      "title": "string",
      "description": "string",
      "terms": "string",
      "cta": "string",
      "badge": "string",
      "dateBadgeText": "string",
      "targetAudienceLabel": "string",
      "layoutVariant": "priceFocus",
      "cardDesignSuggestion": "string",
      "paletteSuggestion": "string",
      "fontStyleSuggestion": "string",
      "highlightText": "string",
      "benefitBullets": ["string", "string", "string"],
      "confidenceNote": "string"
    },
    {
      "variantName": "Fayda Odaklı",
      "strategyNote": "string",
      "title": "string",
      "description": "string",
      "terms": "string",
      "cta": "string",
      "badge": "string",
      "dateBadgeText": "string",
      "targetAudienceLabel": "string",
      "layoutVariant": "benefitList",
      "cardDesignSuggestion": "string",
      "paletteSuggestion": "string",
      "fontStyleSuggestion": "string",
      "highlightText": "string",
      "benefitBullets": ["string", "string", "string"],
      "confidenceNote": "string"
    }
  ]
}
`;
}

function buildBusinessAnalysisPrompt(payload, summary) {
  const periodType = String(payload.periodType || "Dönem");
  const periodTitle = String(payload.periodTitle || "");
  const topHours = JSON.stringify(payload.topHours || []);
  const topServices = JSON.stringify(payload.topServices || []);
  const topProducts = JSON.stringify(payload.topProducts || []);
  const topStaff = JSON.stringify(payload.topStaff || []);
  const customerProfiles = JSON.stringify(payload.customerProfiles || []);

  const serviceCount = Number(summary.serviceCount || 0);
  const productSoldQuantity = Number(summary.productSoldQuantity || 0);
  const productPurchasedQuantity = Number(summary.productPurchasedQuantity || 0);
  const serviceRevenue = Number(summary.serviceRevenue || 0);
  const productRevenue = Number(summary.productRevenue || 0);
  const totalRevenue = Number(summary.totalRevenue || 0);
  const averageRevenuePerService = Number(summary.averageRevenuePerService || 0);

  return `
Sen bir güzellik/sağlık/hizmet işletmesi için çalışan profesyonel işletme analizi danışmanısın.
Türkçe, net ve uygulanabilir bir analiz üret.

Dönem: ${periodType}
Tarih aralığı: ${periodTitle}

Özet:
- Yapılan hizmet sayısı: ${serviceCount}
- Satılan ürün adedi: ${productSoldQuantity}
- Alınan/stoklanan ürün adedi: ${productPurchasedQuantity}
- Hizmet hasılatı: ${serviceRevenue}
- Ürün hasılatı: ${productRevenue}
- Toplam hasılat: ${totalRevenue}
- Hizmet başı ortalama hasılat: ${averageRevenuePerService}

Yoğun saatler: ${topHours}
Hizmet talebi: ${topServices}
Ürün satışı: ${topProducts}
Personel yoğunluğu: ${topStaff}
Müşteri profili: ${customerProfiles}

Lütfen şu formatta yanıt ver:
1) Kısa genel değerlendirme
2) Hasılat ve yoğun saat yorumu
3) Hizmet ve ürün satış yorumu
4) Müşteri profili yorumu
5) İşletme sahibine 3 uygulanabilir öneri

Yanıtı 180 kelimeyi geçirmeden ver.
`;
}

function fallbackCampaign(data, reason) {
  return {
    ok: true,
    usedFallback: true,
    variants: [
      makeCleanFallbackVariant(data, "Premium Güven", "premiumMinimal", "Siyah / Altın", "Kalite, güven ve seçkin hizmet algısı"),
      makeCleanFallbackVariant(data, "Fiyat Fırsatı", "priceFocus", "Turuncu / Krem", "İndirim ve hızlı karar motivasyonu"),
      makeCleanFallbackVariant(data, "Fayda Odaklı", "benefitList", "Mor / Turkuaz", "Hizmet faydalarını ve randevu motivasyonunu öne çıkarır")
    ],
    aiProvider: "fallback",
    aiModel: "local-safe-fallback",
    revision: "64X_clean_fallback",
    confidenceNote: `Fallback kullanıldı: ${reason}`
  };
}

function extractOutputText(responseJson) {
  if (responseJson.output_text) {
    return String(responseJson.output_text);
  }

  if (Array.isArray(responseJson.output)) {
    const parts = [];

    for (const item of responseJson.output) {
      if (Array.isArray(item.content)) {
        for (const content of item.content) {
          if (content.text) parts.push(String(content.text));
        }
      }
    }

    return parts.join("\n").trim();
  }

  return "";
}

function safeJsonParse(text) {
  const raw = String(text || "").trim();

  if (!raw) {
    throw new Error("OpenAI bos cevap dondu.");
  }

  try {
    return JSON.parse(raw);
  } catch (_) {
    const start = raw.indexOf("{");
    const end = raw.lastIndexOf("}");

    if (start >= 0 && end > start) {
      return JSON.parse(raw.slice(start, end + 1));
    }

    throw new Error("OpenAI JSON parse edilemedi: " + raw.slice(0, 500));
  }
}

exports.generateCampaignAiHttp = onRequest(
  {
    region: "europe-west1",
    invoker: "public",
    secrets: [OPENAI_API_KEY],
    timeoutSeconds: 60,
    memory: "512MiB"
  },
  async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).json({ ok: false, error: "POST gerekli." });
      return;
    }

    const data = req.body || {};

    try {
      const businessName = cleanText(data.businessName, "Ä°ÅŸletmemiz");
      const serviceName = cleanText(data.serviceName, "SeÃ§ili hizmet");
      const campaignType = cleanText(data.campaignType, "Kampanya");
      const targetAudience = cleanText(data.targetAudience, "Herkes");
      const discountType = cleanText(data.discountType, "YÃ¼zde Ä°ndirim");
      const discountValue = cleanText(data.discountValue, "");
      const tone = cleanText(data.tone, "Profesyonel");
      const managerBrief = cleanText(data.managerBrief, "");
      const startDateText = cleanText(data.startDateText, "");
      const endDateText = cleanText(data.endDateText, "");
      const dateEmphasisType = cleanText(data.dateEmphasisType, "Tarih vurgusu kullanma");
      const dateBadgeText = cleanText(data.dateBadgeText, "");

      const prompt = `
Sadece geÃ§erli JSON nesnesi dÃ¶ndÃ¼r. Markdown, aÃ§Ä±klama ve kod bloÄŸu kullanma.

Rol:
Sen RxPro uygulamasÄ±ndaki "kampanya kreatif direktÃ¶rÃ¼sÃ¼n".
Form dolduran bir araÃ§ deÄŸilsin. Ä°ÅŸletme sahibinin hedefini analiz eden, mÃ¼ÅŸteriyi ikna edecek reklam aÃ§Ä±sÄ±nÄ± seÃ§en ve kartÄ±n tamamÄ±nÄ± profesyonelce kurgulayan pazarlama asistanÄ±sÄ±n.

Girdi:
Ä°ÅŸletme adÄ±: ${businessName}
Hizmet: ${serviceName}
Kampanya tÃ¼rÃ¼: ${campaignType}
Hedef mÃ¼ÅŸteri: ${targetAudience}
Ä°ndirim tipi: ${discountType}
Ä°ndirim deÄŸeri: ${discountValue}
Ton: ${tone}
YÃ¶netici isteÄŸi: ${managerBrief}
BaÅŸlangÄ±Ã§ tarihi: ${startDateText}
BitiÅŸ tarihi: ${endDateText}
Tarih vurgu tipi: ${dateEmphasisType}
Mevcut tarih rozeti: ${dateBadgeText}

Profesyonel kalite kurallarÄ±:
- TÃ¼rkÃ§e yaz.
- YÃ¶netici isteÄŸini analiz et, ama aynen kopyalama.
- Argo, kaba, alaycÄ±, anlamsÄ±z, marka deÄŸerini dÃ¼ÅŸÃ¼ren veya amatÃ¶r kelimeleri baÅŸlÄ±k/aÃ§Ä±klamada aynen kullanma.
- KullanÄ±cÄ± Ã¶zellikle kÃ¶tÃ¼ kelime istese bile bunu profesyonel kampanya diline dÃ¶nÃ¼ÅŸtÃ¼r.
- "banane", "sanane", "ÅŸok ÅŸok", "efsane patladÄ±" gibi ifadeleri doÄŸrudan kullanma; niyetini profesyonel hale getir.
- "hizmet hizmetinde" gibi tekrar yapma.
- BaÅŸlÄ±k en fazla 7 kelime olsun.
- AÃ§Ä±klama 45-75 kelime arasÄ±nda olsun.
- CTA en fazla 4 kelime olsun.
- KoÅŸullar kÄ±sa ve gÃ¼venli olsun.
- Tarih varsa dateBadgeText mÃ¼ÅŸteriye anlaÅŸÄ±lÄ±r ÅŸekilde yazÄ±lsÄ±n.
- Her alternatif gerÃ§ekten farklÄ± stratejiye sahip olsun.
- Varyantlar birbirinin yeniden yazÄ±lmÄ±ÅŸ kopyasÄ± olmasÄ±n.

Kart stratejileri:
1. Premium GÃ¼ven:
   - AmaÃ§: kalite, titizlik, gÃ¼ven, Ã¶zen, seÃ§kin hizmet algÄ±sÄ±.
   - layoutVariant: premiumMinimal
   - paletteSuggestion: Siyah / AltÄ±n veya Lacivert / GÃ¼mÃ¼ÅŸ
   - fontStyleSuggestion: elegant
   - CTA Ã¶rnekleri: Deneyimi Planla, Randevunu AyÄ±r

2. Fiyat FÄ±rsatÄ±:
   - AmaÃ§: indirim/fÄ±rsat/vade/tarih ile hÄ±zlÄ± karar aldÄ±rmak.
   - layoutVariant: priceFocus
   - paletteSuggestion: Turuncu / Krem veya Mor / Turkuaz
   - fontStyleSuggestion: modernBold
   - CTA Ã¶rnekleri: FÄ±rsattan Yararlan, Hemen Randevu Al

3. Fayda OdaklÄ±:
   - AmaÃ§: hizmetin mÃ¼ÅŸteri faydasÄ±nÄ± 3 kÄ±sa maddeyle anlatmak.
   - layoutVariant: benefitList
   - paletteSuggestion: Mor / Turkuaz, Pastel Pembe veya Mint / Beyaz
   - fontStyleSuggestion: friendly veya corporateClean
   - CTA Ã¶rnekleri: Randevunu OluÅŸtur, BakÄ±mÄ±nÄ± Planla

Ä°zin verilen deÄŸerler:
layoutVariant: hero, priceFocus, benefitList, premiumMinimal
paletteSuggestion: Mor / Turkuaz, Siyah / AltÄ±n, Pastel Pembe, Mint / Beyaz, Lacivert / GÃ¼mÃ¼ÅŸ, Turuncu / Krem, YeÅŸil / DoÄŸal, Clean White
fontStyleSuggestion: modernBold, elegant, friendly, corporateClean

Zorunlu JSON formatÄ±:
{
  "variants": [
    {
      "variantName": "Premium GÃ¼ven",
      "strategyNote": "string",
      "title": "string",
      "description": "string",
      "terms": "string",
      "cta": "string",
      "badge": "string",
      "dateBadgeText": "string",
      "targetAudienceLabel": "string",
      "layoutVariant": "premiumMinimal",
      "cardDesignSuggestion": "string",
      "paletteSuggestion": "string",
      "fontStyleSuggestion": "string",
      "highlightText": "string",
      "benefitBullets": ["string", "string", "string"],
      "confidenceNote": "string"
    },
    {
      "variantName": "Fiyat FÄ±rsatÄ±",
      "strategyNote": "string",
      "title": "string",
      "description": "string",
      "terms": "string",
      "cta": "string",
      "badge": "string",
      "dateBadgeText": "string",
      "targetAudienceLabel": "string",
      "layoutVariant": "priceFocus",
      "cardDesignSuggestion": "string",
      "paletteSuggestion": "string",
      "fontStyleSuggestion": "string",
      "highlightText": "string",
      "benefitBullets": ["string", "string", "string"],
      "confidenceNote": "string"
    },
    {
      "variantName": "Fayda OdaklÄ±",
      "strategyNote": "string",
      "title": "string",
      "description": "string",
      "terms": "string",
      "cta": "string",
      "badge": "string",
      "dateBadgeText": "string",
      "targetAudienceLabel": "string",
      "layoutVariant": "benefitList",
      "cardDesignSuggestion": "string",
      "paletteSuggestion": "string",
      "fontStyleSuggestion": "string",
      "highlightText": "string",
      "benefitBullets": ["string", "string", "string"],
      "confidenceNote": "string"
    }
  ]
}
`;

      const cleanPrompt = buildCampaignCreativePrompt(data);

      const openAiResponse = await fetch("https://api.openai.com/v1/responses", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${OPENAI_API_KEY.value()}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          model: "gpt-4.1-mini",
          input: cleanPrompt,
          text: {
            format: {
              type: "json_object"
            }
          }
        })
      });

      const responseBody = await openAiResponse.text();

      if (!openAiResponse.ok) {
        throw new Error(`OpenAI HTTP ${openAiResponse.status}: ${responseBody.slice(0, 600)}`);
      }

      const responseJson = JSON.parse(responseBody);
      const outputText = extractOutputText(responseJson);
      const parsed = safeJsonParse(outputText);

      const variants = Array.isArray(parsed.variants)
        ? parsed.variants.slice(0, 3)
        : [];

      if (variants.length === 0) {
        throw new Error("AI variants bos dondu.");
      }

      res.status(200).json({
        ok: true,
        usedFallback: false,
        variants,
        aiProvider: "openai",
        aiModel: "gpt-4.1-mini",
        revision: "34B_creative_quality_success"
      });
    } catch (error) {
      console.error("generateCampaignAiHttp 34B error:", {
        message: error && error.message ? error.message : String(error),
        code: error && error.code ? error.code : null,
        type: error && error.type ? error.type : null
      });

      res.status(200).json(
        fallbackCampaign(data, error && error.message ? error.message : "unknown_error")
      );
    }
  }
);

exports.generateBusinessAnalysisAiHttp = functions.https.onCall(async (data, context) => {
  const payload = data || {};
  const summary = payload.summary || {};

  const periodType = String(payload.periodType || "DÃ¶nem");
  const periodTitle = String(payload.periodTitle || "");
  const topHours = JSON.stringify(payload.topHours || []);
  const topServices = JSON.stringify(payload.topServices || []);
  const topProducts = JSON.stringify(payload.topProducts || []);
  const topStaff = JSON.stringify(payload.topStaff || []);
  const customerProfiles = JSON.stringify(payload.customerProfiles || []);

  const serviceCount = Number(summary.serviceCount || 0);
  const productSoldQuantity = Number(summary.productSoldQuantity || 0);
  const productPurchasedQuantity = Number(summary.productPurchasedQuantity || 0);
  const serviceRevenue = Number(summary.serviceRevenue || 0);
  const productRevenue = Number(summary.productRevenue || 0);
  const totalRevenue = Number(summary.totalRevenue || 0);
  const averageRevenuePerService = Number(summary.averageRevenuePerService || 0);

  const prompt = `
Sen bir gÃ¼zellik/saÄŸlÄ±k/hizmet iÅŸletmesi iÃ§in Ã§alÄ±ÅŸan profesyonel iÅŸletme analizi danÄ±ÅŸmanÄ±sÄ±n.
TÃ¼rkÃ§e, net ve uygulanabilir bir analiz Ã¼ret.

DÃ¶nem: ${periodType}
Tarih aralÄ±ÄŸÄ±: ${periodTitle}

Ã–zet:
- YapÄ±lan hizmet sayÄ±sÄ±: ${serviceCount}
- SatÄ±lan Ã¼rÃ¼n adedi: ${productSoldQuantity}
- AlÄ±nan/stoklanan Ã¼rÃ¼n adedi: ${productPurchasedQuantity}
- Hizmet hasÄ±latÄ±: ${serviceRevenue}
- ÃœrÃ¼n hasÄ±latÄ±: ${productRevenue}
- Toplam hasÄ±lat: ${totalRevenue}
- Hizmet baÅŸÄ± ortalama hasÄ±lat: ${averageRevenuePerService}

YoÄŸun saatler: ${topHours}
Hizmet talebi: ${topServices}
ÃœrÃ¼n satÄ±ÅŸÄ±: ${topProducts}
Personel yoÄŸunluÄŸu: ${topStaff}
MÃ¼ÅŸteri profili: ${customerProfiles}

LÃ¼tfen ÅŸu formatta yanÄ±t ver:
1) KÄ±sa genel deÄŸerlendirme
2) HasÄ±lat ve yoÄŸun saat yorumu
3) Hizmet ve Ã¼rÃ¼n satÄ±ÅŸ yorumu
4) MÃ¼ÅŸteri profili yorumu
5) Ä°ÅŸletme sahibine 3 uygulanabilir Ã¶neri

YanÄ±tÄ± 180 kelimeyi geÃ§irmeden ver.
`;

  const cleanPrompt = buildBusinessAnalysisPrompt(payload, summary);

  try {
    const apiKey =
      process.env.OPENAI_API_KEY ||
      (functions.config().openai && functions.config().openai.key);

    if (!apiKey) {
      return {
        report:
          "AI anahtarı Firebase Functions ortamında tanımlı değil. Analiz verisi alındı ancak gerçek AI raporu üretilemedi.",
      };

      return {
        report:
          "AI anahtarÄ± Firebase Functions ortamÄ±nda tanÄ±mlÄ± deÄŸil. Analiz verisi alÄ±ndÄ± ancak gerÃ§ek AI raporu Ã¼retilemedi.",
      };
    }

    const response = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4.1-mini",
        input: cleanPrompt,
      }),
    });

    const json = await response.json();

    if (!response.ok) {
      console.error("OpenAI business analysis error", json);
      return {
        report:
          "AI servisi şu an rapor üretemedi. Veriler kaydedildi; daha sonra tekrar deneyebilirsiniz.",
      };

      return {
        report:
          "AI servisi ÅŸu an rapor Ã¼retemedi. Veriler kaydedildi; daha sonra tekrar deneyebilirsiniz.",
      };
    }

    const report =
      json.output_text ||
      (json.output && json.output[0] && json.output[0].content && json.output[0].content[0] && json.output[0].content[0].text) ||
      "";

    return {
      report: String(report || "").trim(),
    };
  } catch (err) {
    console.error("generateBusinessAnalysisAiHttp failed", err);
    return {
      report:
        "AI analiz bağlantısı kurulamadı. Veriler hazır; bağlantı düzeldikten sonra tekrar analiz alınabilir.",
    };

    return {
      report:
        "AI analiz baÄŸlantÄ±sÄ± kurulamadÄ±. Veriler hazÄ±r; baÄŸlantÄ± dÃ¼zeldikten sonra tekrar analiz alÄ±nabilir.",
    };
  }
});



function rxClean(value, fallback = "") {
  if (value === undefined || value === null) return fallback;
  return String(value).trim() || fallback;
}

function rxStatusIsCancelled(data) {
  const status = rxClean(
    data.status || data.appointmentStatus || data.state || data.bookingStatus
  ).toLowerCase();

  return status.includes("cancel") ||
    status.includes("iptal") ||
    data.isCancelled === true;
}

function rxShortPushBody(type, body) {
  const t = rxClean(type).toLowerCase();

  if (t.includes("postpone") || t.includes("ertele")) {
    return "Randevunuz için yeni saat önerildi.";
  }

  if (t.includes("cancel") || t.includes("iptal")) {
    return "Detay için dokunun.";
  }

  if (t.includes("reminder")) {
    return "Gelecek misiniz?";
  }

  const cleanBody = rxClean(body, "Detay için dokunun.");
  return cleanBody.length > 90 ? cleanBody.slice(0, 87) + "..." : cleanBody;
}

async function rxResolveBusinessTargetUids(data) {
  const uids = new Set();

  const rawBusinessId = rxClean(data.businessId);
  if (!rawBusinessId) return [];

  const businessIdCandidates = new Set();
  businessIdCandidates.add(rawBusinessId);

  let strippedBusinessUid = "";
  if (rawBusinessId.startsWith("business_")) {
    strippedBusinessUid = rxClean(rawBusinessId.replace(/^business_/, ""));
    if (strippedBusinessUid) {
      businessIdCandidates.add(strippedBusinessUid);
      uids.add(strippedBusinessUid);
    }
  }

  // Bazı projelerde businessId doğrudan işletme kullanıcısının UID'si gibi tutuluyor.
  if (!rawBusinessId.startsWith("business_") && rawBusinessId.length >= 12) {
    uids.add(rawBusinessId);
  }

  // businesses/{businessId} dokümanlarından owner alanlarını çöz.
  for (const bid of Array.from(businessIdCandidates)) {
    try {
      const businessDoc = await db.collection("businesses").doc(bid).get();
      if (businessDoc.exists) {
        const b = businessDoc.data() || {};
        [
          b.ownerUid,
          b.ownerId,
          b.businessOwnerUid,
          b.userId,
          b.uid,
          b.createdBy,
          b.adminUid,
          b.managerUid
        ].forEach((v) => {
          const uid = rxClean(v);
          if (uid) uids.add(uid);
        });
      }
    } catch (err) {
      console.error("RX_41I_D2_BUSINESS_DOC_LOOKUP_ERROR", {
        businessId: bid,
        error: err && err.message ? err.message : String(err)
      });
    }
  }

  // users koleksiyonunda işletme id alanlarına göre ara.
  const fields = [
    "businessId",
    "ownedBusinessId",
    "activeBusinessId",
    "selectedBusinessId"
  ];

  for (const bid of Array.from(businessIdCandidates)) {
    for (const field of fields) {
      try {
        const snap = await db.collection("users")
          .where(field, "==", bid)
          .limit(10)
          .get();

        snap.forEach((doc) => {
          if (doc.id) uids.add(doc.id);
          const u = doc.data() || {};
          [
            u.uid,
            u.ownerUid,
            u.userId
          ].forEach((v) => {
            const uid = rxClean(v);
            if (uid) uids.add(uid);
          });
        });
      } catch (err) {
        console.error("RX_41I_D2_USER_BUSINESS_LOOKUP_ERROR", {
          field,
          businessId: bid,
          error: err && err.message ? err.message : String(err)
        });
      }
    }
  }

  return Array.from(uids).filter(Boolean);
}

async function rxResolveNotificationTargetUids(data) {
  const uids = new Set();

  const directUid = rxClean(
    data.recipientUid ||
    data.targetUid ||
    data.userId ||
    data.customerUid ||
    data.receiverUid ||
    data.clientUid
  );

  if (directUid) {
    uids.add(directUid);
    return Array.from(uids).filter(Boolean);
  }

  const targetScope = rxClean(data.targetScope).toLowerCase();
  const businessId = rxClean(data.businessId);

  if (businessId && (targetScope === "business" || !targetScope)) {
    const businessUids = await rxResolveBusinessTargetUids(data);
    businessUids.forEach((uid) => {
      if (uid) uids.add(uid);
    });
  }

  return Array.from(uids).filter(Boolean);
}

async function rxCollectFcmTokensForUids(uids) {
  const db = admin.firestore();
  const tokens = new Set();

  for (const uid of uids) {
    try {
      const userDoc = await db.collection("users").doc(uid).get();

      if (userDoc.exists) {
        const userData = userDoc.data() || {};
        const legacyToken = rxClean(userData.fcmToken);
        if (legacyToken && userData.fcmTokenActive !== false && (!userData.fcmTokenOwnerUid || userData.fcmTokenOwnerUid === uid)) {
          tokens.add(legacyToken);
        }
      }

      const tokenSnap = await db.collection("users")
        .doc(uid)
        .collection("fcmTokens")
        .where("active", "==", true)
        .get();

      tokenSnap.forEach((doc) => {
        const t = doc.data() || {};
        const token = rxClean(t.token || doc.id);
        if (token && t.active === true && (!t.ownerUid || t.ownerUid === uid)) tokens.add(token);
      });
    } catch (error) {
      console.error("token collect failed", uid, error);
    }
  }

  return Array.from(tokens);
}

function rxPushData(notificationId, data) {
  const innerData = data.data && typeof data.data === "object" ? data.data : {};

  return {
    notificationId: String(notificationId),
    title: rxClean(data.title, "RxPro"),
    body: rxShortPushBody(data.type, data.body),
    type: rxClean(data.type, "general"),
    route: rxClean(data.route),
    businessId: rxClean(data.businessId),
    businessName: rxClean(data.businessName),
    targetScope: rxClean(data.targetScope),
    recipientUid: rxClean(data.recipientUid),
    targetUid: rxClean(data.targetUid),
    userId: rxClean(data.userId),
    customerUid: rxClean(data.customerUid),
    receiverUid: rxClean(data.receiverUid),
    appointmentId: rxClean(innerData.appointmentId || data.appointmentId),
    payload: JSON.stringify(innerData).slice(0, 3500)
  };
}


async function rxDisableDeadFcmTokenForUids(uids, badToken, reason) {
  const db = admin.firestore();
  const token = rxClean(badToken);
  if (!token) return;

  for (const uid of uids || []) {
    const cleanUid = rxClean(uid);
    if (!cleanUid) continue;

    try {
      const userRef = db.collection("users").doc(cleanUid);
      const userDoc = await userRef.get();

      if (userDoc.exists) {
        const userData = userDoc.data() || {};
        if (rxClean(userData.fcmToken) === token) {
          await userRef.set({
            fcmTokenActive: false,
            fcmTokenDisabledReason: reason || "invalid",
            fcmTokenDisabledAt: admin.firestore.FieldValue.serverTimestamp()
          }, { merge: true });
        }
      }

      const tokenSnap = await userRef.collection("fcmTokens")
        .where("active", "==", true)
        .get();
      const batch = db.batch();
      let count = 0;

      tokenSnap.forEach((doc) => {
        const data = doc.data() || {};
        const storedToken = rxClean(data.token || doc.id);

        if (storedToken === token) {
          batch.set(doc.ref, {
            active: false,
            disabledReason: reason || "invalid",
            disabledAt: admin.firestore.FieldValue.serverTimestamp()
          }, { merge: true });
          count++;
        }
      });

      if (count > 0) {
        await batch.commit();
        console.log("FCM_DEAD_TOKEN_DISABLED_41H3", {
          uid: cleanUid,
          count,
          reason: reason || "invalid"
        });
      }
    } catch (error) {
      console.error("FCM_DEAD_TOKEN_DISABLE_FAILED_41H3", cleanUid, error);
    }
  }
}
exports.sendPushOnNotificationCreated = onDocumentCreated(
  {
    document: "notifications/{notificationId}",
    region: "europe-west1"
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data() || {};
    const notificationId = event.params.notificationId;

    const title = rxClean(data.title, "RxPro");
    const body = rxShortPushBody(data.type, data.body);

    try {
      const targetUids = await rxResolveNotificationTargetUids(data);
      const tokens = await rxCollectFcmTokensForUids(targetUids);
    console.log("RX_41I_D2_TOKEN_COLLECT_SUMMARY", {
      targetUids,
      tokenCount: tokens.length
    });

      console.log("sendPushOnNotificationCreated target", {
        notificationId,
        type: data.type,
        recipientUid: data.recipientUid || data.targetUid || data.userId || data.customerUid || data.receiverUid || data.clientUid || "",
        targetScope: data.targetScope || "",
        businessId: data.businessId || "",
        targetUidCount: targetUids.length,
      targetUids: targetUids,
        tokenCount: tokens.length
      });

      if (tokens.length === 0) {
        await snap.ref.set({
          pushStatus: "no-token",
          pushtargetUidCount: targetUids.length,
      targetUids: targetUids,
          pushTokenCount: 0,
          pushCheckedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
        return;
      }

      let successCount = 0;
      let failureCount = 0;

      for (let i = 0; i < tokens.length; i += 500) {
        const chunk = tokens.slice(i, i + 500);

        const response = await admin.messaging().sendEachForMulticast({
          tokens: chunk,
          notification: { title, body },
          data: rxPushData(notificationId, data),
          android: {
            priority: "high",
            notification: {
              channelId: "rxpro_high_importance",
              clickAction: "FLUTTER_NOTIFICATION_CLICK"
            }
          },
          apns: {
            payload: {
              aps: { sound: "default" }
            }
          }
        });

        successCount += response.successCount;
        failureCount += response.failureCount;

        if (response.failureCount > 0 && Array.isArray(response.responses)) {
          for (let j = 0; j < response.responses.length; j++) {
            const r = response.responses[j];
            if (!r.success) {
              const code = r.error && r.error.code ? r.error.code : "";
              const message = r.error && r.error.message ? r.error.message : "";
              const badToken = chunk[j] || "";

              console.log("FCM_DELIVERY_ERROR_DETAIL_41H2", {
                index: j,
                code,
                message,
                tokenTail: badToken ? badToken.slice(-10) : ""
              });

              if (
                code === "messaging/registration-token-not-registered" ||
                code === "messaging/invalid-registration-token"
              ) {
                await rxDisableDeadFcmTokenForUids(targetUids, badToken, code);
              }
            }
          }
        }
      }

      await snap.ref.set({
        pushStatus: failureCount === 0 ? "sent" : "partial",
        pushtargetUidCount: targetUids.length,
      targetUids: targetUids,
        pushTokenCount: tokens.length,
        pushSuccessCount: successCount,
        pushFailureCount: failureCount,
        pushSentAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      console.log("sendPushOnNotificationCreated result", {
        notificationId,
        successCount,
        failureCount
      });
    } catch (error) {
      console.error("sendPushOnNotificationCreated failed", error);

      await snap.ref.set({
        pushStatus: "error",
        pushError: error && error.message ? error.message : String(error),
        pushErrorAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
    }
  }
);

exports.sendAppointmentReminderOneHour = onSchedule(
  {
    schedule: "every 5 minutes",
    region: "europe-west1",
    timeZone: "Europe/Istanbul"
  },
  async () => {
    const db = admin.firestore();
    const now = Date.now();
    const lower = new Date(now + 55 * 60 * 1000);
    const upper = new Date(now + 65 * 60 * 1000);

    const snap = await db.collection("appointments")
      .where("startAt", ">=", admin.firestore.Timestamp.fromDate(lower))
      .where("startAt", "<=", admin.firestore.Timestamp.fromDate(upper))
      .limit(100)
      .get();

    const batch = db.batch();
    let count = 0;

    for (const doc of snap.docs) {
      const data = doc.data() || {};

      if (data.reminder1hSent === true) continue;
      if (rxStatusIsCancelled(data)) continue;

      const customerUid = rxClean(
        data.customerUid || data.customerId || data.userId || data.uid || data.clientUid
      );
      if (!customerUid) continue;

      const businessId = rxClean(data.businessId);
      const businessName = rxClean(data.businessName, "İşletme");
      const serviceName = rxClean(data.serviceName, "Randevu");
      const dateText = rxClean(data.dateText || data.appointmentDate);
      const timeText = rxClean(data.timeText || data.appointmentTime);

      const notificationRef = db.collection("notifications").doc();

      batch.set(notificationRef, {
        recipientUid: customerUid,
        targetScope: "user",
        targetUid: customerUid,
        customerUid,
        businessId,
        businessName,
        type: "appointment_reminder_1h",
        title: "Randevunuza 1 saat kaldı",
        body: "Gelecek misiniz?",
        route: "customerAppointments",
        data: {
          appointmentId: doc.id,
          requiresArrivalConfirmation: true,
          serviceName,
          dateText,
          timeText
        },
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdAtIso: new Date().toISOString(),
        source: "scheduled_appointment_reminder_1h"
      });

      batch.set(doc.ref, {
        reminder1hSent: true,
        reminder1hSentAt: admin.firestore.FieldValue.serverTimestamp(),
        arrivalQuestionSent: true,
        customerArrivalStatus: "pending",
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      count++;
    }

    if (count > 0) {
      await batch.commit();
    }

    console.log("sendAppointmentReminderOneHour completed", { count });
  }
);

function bulkClean(value, fallback = "") {
  if (value === undefined || value === null) return fallback;
  const text = String(value).trim();
  return text || fallback;
}

function bulkSafeDocId(value) {
  return bulkClean(value).replace(/[^a-zA-Z0-9_-]/g, "_").slice(0, 420);
}

function bulkDateValue(value) {
  if (!value) return null;
  if (typeof value.toDate === "function") return value.toDate();
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function bulkSendingIsStale(draftData) {
  const startedAt = bulkDateValue(draftData.sendStartedAt);
  if (!startedAt) return false;
  return Date.now() - startedAt.getTime() > 10 * 60 * 1000;
}

function bulkCanSendDraft(draftData) {
  const status = bulkClean(draftData.status, "draft").toLowerCase();
  const sendStatus = bulkClean(draftData.sendStatus, "draft_ready").toLowerCase();

  return (
    status === "draft" &&
    ["draft_ready", "ready", "scheduled", "send_failed"].includes(sendStatus)
  );
}

function bulkConsentAllowed(data, consentOnly) {
  if (!consentOnly) return false;

  if (
    data.bulkMessageOptOut === true ||
    data.marketingOptOut === true ||
    data.notificationOptOut === true ||
    data.campaignOptOut === true
  ) {
    return false;
  }

  return (
    data.bulkMessageConsent === true ||
    data.marketingConsent === true ||
    data.notificationConsent === true ||
    data.campaignConsent === true ||
    data.campaignPermission === true ||
    data.allowCampaignMessages === true
  );
}

async function bulkAssertDraftOwner(uid, draftData) {
  const ownerUid = bulkClean(draftData.ownerUid || draftData.createdBy);
  if (ownerUid && ownerUid === uid) return;

  const businessId = bulkClean(draftData.businessId);
  if (!businessId) {
    throw new HttpsError("permission-denied", "Taslak işletme bilgisi eksik.");
  }

  const businessDoc = await db.collection("businesses").doc(businessId).get();
  const business = businessDoc.exists ? businessDoc.data() || {} : {};
  const ownerCandidates = [
    business.ownerUid,
    business.ownerId,
    business.businessOwnerUid,
    business.userId,
    business.uid,
    business.createdBy,
    business.createdByUid,
    business.adminUid,
    business.managerUid,
  ].map((value) => bulkClean(value));

  const ownerLists = [
    business.ownerUids,
    business.adminUids,
    business.managerUids,
    business.authorizedUids,
  ].filter(Array.isArray);

  if (
    ownerCandidates.includes(uid) ||
    ownerLists.some((list) => list.map((value) => bulkClean(value)).includes(uid))
  ) {
    return;
  }

  throw new HttpsError("permission-denied", "Bu toplu mesaj taslağı için yetkiniz yok.");
}

async function bulkCollectTargetCustomers(draftData) {
  const businessId = bulkClean(draftData.businessId);
  const metadata =
    draftData.audienceMetadata && typeof draftData.audienceMetadata === "object"
      ? draftData.audienceMetadata
      : {};
  const segmentId = bulkClean(metadata.segmentId || draftData.segmentId || "all");

  if (!businessId) return [];

  const query = db
    .collection("businessCustomers")
    .where("businessId", "==", businessId)
    .limit(500);

  const snap = await query.get();
  const byUid = new Map();
  const consentOnly = draftData.consentOnly !== false;

  snap.forEach((doc) => {
    const data = doc.data() || {};
    const customerUid = bulkClean(
      data.customerUid || data.customerId || data.userId || data.uid || data.clientUid
    );

    if (!customerUid || customerUid === "-") return;
    const customerSegmentId = bulkClean(data.segmentId || "manual");
    if (segmentId && segmentId !== "all" && customerSegmentId !== segmentId) return;
    if (!bulkConsentAllowed(data, consentOnly)) return;
    if (byUid.has(customerUid)) return;

    byUid.set(customerUid, {
      customerUid,
      customerName: bulkClean(data.customerName || data.name || data.displayName),
      customerPhone: bulkClean(data.customerPhone || data.phone),
      segmentId: customerSegmentId,
      sourceDocId: doc.id,
    });
  });

  return Array.from(byUid.values());
}

exports.sendBulkMessageDraft = onCall(
  {
    region: "europe-west1",
  },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Oturum bulunamadı.");
    }

    const draftId = bulkClean(request.data && request.data.draftId);
    if (!draftId) {
      throw new HttpsError("invalid-argument", "draftId zorunludur.");
    }

    const draftRef = db.collection("bulkMessageDrafts").doc(draftId);
    const draftSnap = await draftRef.get();

    if (!draftSnap.exists) {
      throw new HttpsError("not-found", "Toplu mesaj taslağı bulunamadı.");
    }

    const draft = draftSnap.data() || {};
    await bulkAssertDraftOwner(uid, draft);

    const attemptId =
      bulkSafeDocId(request.data && request.data.clientRequestId) ||
      db.collection("_bulkAttemptIds").doc().id;

    const claim = await db.runTransaction(async (transaction) => {
      const freshSnap = await transaction.get(draftRef);
      if (!freshSnap.exists) {
        throw new HttpsError("not-found", "Toplu mesaj taslağı bulunamadı.");
      }

      const freshDraft = freshSnap.data() || {};
      const status = bulkClean(freshDraft.status, "draft").toLowerCase();
      const sendStatus = bulkClean(freshDraft.sendStatus, "draft_ready").toLowerCase();

      if (status === "sent" || sendStatus === "sent") {
        return {
          state: "sent",
          draft: freshDraft,
          targetCount: Number(freshDraft.targetCount || 0),
          deliveredNotificationCount: Number(freshDraft.deliveredNotificationCount || 0),
        };
      }

      if (sendStatus === "sending" && !bulkSendingIsStale(freshDraft)) {
        return {
          state: "sending",
          draft: freshDraft,
          targetCount: Number(freshDraft.targetCount || 0),
          deliveredNotificationCount: Number(freshDraft.deliveredNotificationCount || 0),
        };
      }

      if (!bulkCanSendDraft(freshDraft) && sendStatus !== "sending") {
        throw new HttpsError("failed-precondition", "Bu taslak gönderime hazır değil.");
      }

      if (freshDraft.consentOnly !== true) {
        throw new HttpsError("failed-precondition", "Toplu mesaj için izin kuralı zorunludur.");
      }

      const title = bulkClean(freshDraft.title);
      const body = bulkClean(freshDraft.message || freshDraft.body);
      if (!title || !body) {
        throw new HttpsError("failed-precondition", "Başlık ve mesaj içeriği zorunludur.");
      }

      transaction.set(draftRef, {
        sendStatus: "sending",
        sendAttemptId: attemptId,
        lastSendAttemptId: attemptId,
        sendStartedAt: admin.firestore.FieldValue.serverTimestamp(),
        sendStartedAtLocalIso: new Date().toISOString(),
        sendStartedBy: uid,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      return {
        state: "claimed",
        draft: freshDraft,
        targetCount: 0,
        deliveredNotificationCount: 0,
      };
    });

    if (claim.state === "sent") {
      const sentDraft = claim.draft || {};
      return {
        ok: true,
        draftId,
        attemptId: bulkClean(sentDraft.sendAttemptId || sentDraft.lastSendAttemptId),
        sendStatus: "sent",
        alreadySent: true,
        targetCount: claim.targetCount,
        deliveredNotificationCount: claim.deliveredNotificationCount,
      };
    }

    if (claim.state === "sending") {
      const sendingDraft = claim.draft || {};
      return {
        ok: true,
        draftId,
        attemptId: bulkClean(sendingDraft.sendAttemptId || sendingDraft.lastSendAttemptId),
        sendStatus: "sending",
        alreadySending: true,
        targetCount: claim.targetCount,
        deliveredNotificationCount: claim.deliveredNotificationCount,
      };
    }

    const claimedDraft = claim.draft || {};
    if (claimedDraft.consentOnly !== true) {
      throw new HttpsError("failed-precondition", "Toplu mesaj için izin kuralı zorunludur.");
    }

    const title = bulkClean(claimedDraft.title);
    const body = bulkClean(claimedDraft.message || claimedDraft.body);
    if (!title || !body) {
      throw new HttpsError("failed-precondition", "Başlık ve mesaj içeriği zorunludur.");
    }

    const businessId = bulkClean(claimedDraft.businessId);
    const businessName = bulkClean(claimedDraft.businessName, "İşletme");
    const nowIso = new Date().toISOString();
    const sendLogRef = db.collection("bulkMessageSendLogs").doc(attemptId);

    await sendLogRef.set({
      attemptId,
      draftId,
      businessId,
      businessName,
      status: "sending",
      senderUid: uid,
      title,
      targetCount: 0,
      deliveredNotificationCount: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAtLocalIso: nowIso,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      source: "send_bulk_message_draft",
    }, { merge: true });

    try {
      const targets = await bulkCollectTargetCustomers(claimedDraft);
    if (targets.length === 0) {
      await draftRef.set({
        sendStatus: "no_eligible_recipients",
        sendAttemptId: attemptId,
        lastSendAttemptId: attemptId,
        targetCount: 0,
        deliveredNotificationCount: 0,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        sentAtLocalIso: nowIso,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      await sendLogRef.set({
        status: "no_eligible_recipients",
        targetCount: 0,
        deliveredNotificationCount: 0,
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        completedAtLocalIso: nowIso,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      return {
        ok: true,
        draftId,
        attemptId,
        sendStatus: "no_eligible_recipients",
        alreadySent: false,
        alreadySending: false,
        targetCount: 0,
        deliveredNotificationCount: 0,
      };
    }

    let written = 0;
    let batch = db.batch();
    let opCount = 0;

    async function flush() {
      if (opCount === 0) return;
      await batch.commit();
      batch = db.batch();
      opCount = 0;
    }

    for (const target of targets) {
      const notificationId = `bulk_${bulkSafeDocId(draftId)}_${bulkSafeDocId(target.customerUid)}`;
      const notificationRef = db.collection("notifications").doc(notificationId);
      batch.set(notificationRef, {
        recipientUid: target.customerUid,
        targetUid: target.customerUid,
        customerUid: target.customerUid,
        userId: target.customerUid,
        targetScope: "user",
        businessId,
        businessName,
        type: "bulkMessage",
        notificationType: "bulkMessage",
        title,
        body,
        route: "customerNotifications",
        data: {
          bulkMessageDraftId: draftId,
          attemptId,
          audience: bulkClean(claimedDraft.audience || claimedDraft.target),
          channel: bulkClean(claimedDraft.channel),
          customerSegmentId: target.segmentId,
          sourceCustomerDocId: target.sourceDocId,
        },
        isRead: false,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdAtLocalIso: nowIso,
        source: "send_bulk_message_draft",
      });

      written++;
      opCount++;
      if (opCount >= 450) {
        await flush();
      }
    }

    await flush();

    await draftRef.set({
      sendStatus: "sent",
      status: "sent",
      sendAttemptId: attemptId,
      lastSendAttemptId: attemptId,
      targetCount: targets.length,
      deliveredNotificationCount: written,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      sentAtLocalIso: nowIso,
      sentBy: uid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    await sendLogRef.set({
      status: "sent",
      targetCount: targets.length,
      deliveredNotificationCount: written,
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      completedAtLocalIso: nowIso,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    return {
      ok: true,
      draftId,
      attemptId,
      sendStatus: "sent",
      alreadySent: false,
      alreadySending: false,
      targetCount: targets.length,
      deliveredNotificationCount: written,
    };
    } catch (error) {
      const message = error && error.message ? error.message : String(error);
      await draftRef.set({
        sendStatus: "send_failed",
        sendAttemptId: attemptId,
        lastSendAttemptId: attemptId,
        lastSendError: message.slice(0, 500),
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
        failedAtLocalIso: new Date().toISOString(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      await sendLogRef.set({
        status: "failed",
        errorMessage: message.slice(0, 500),
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
        failedAtLocalIso: new Date().toISOString(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      console.error("sendBulkMessageDraft failed:", {
        draftId,
        attemptId,
        message,
      });

      throw new HttpsError(
        "unavailable",
        "Toplu mesaj gönderimi tamamlanamadı. Daha sonra tekrar deneyin.",
      );
    }
  }
);

function accountingSignedInUid(context) {
  const uid = context && context.auth && context.auth.uid;
  if (!uid) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Oturum bulunamadi."
    );
  }
  return uid;
}

function accountingText(value, fallback = "") {
  if (value === undefined || value === null) return fallback;
  const text = String(value).trim();
  return text || fallback;
}

function accountingRequiredString(value, field) {
  const text = accountingText(value);
  if (!text) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${field} zorunludur.`
    );
  }
  return text;
}

function accountingPositiveKurus(value, field) {
  const amount = Number(value);
  if (!Number.isFinite(amount) || amount <= 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${field} sifirdan buyuk olmalidir.`
    );
  }
  return Math.round(amount);
}

function accountingNonNegativeKurus(value) {
  const amount = Number(value || 0);
  if (!Number.isFinite(amount) || amount < 0) return 0;
  return Math.round(amount);
}

function accountingNormalizePhone(input) {
  const raw = accountingText(input);
  if (!raw) return null;

  let digits = raw.replace(/[^0-9]/g, "");
  if (digits.startsWith("0090")) {
    digits = digits.substring(4);
  } else if (digits.startsWith("90") && digits.length === 12) {
    digits = digits.substring(2);
  } else if (digits.startsWith("0") && digits.length === 11) {
    digits = digits.substring(1);
  }

  if (digits.length === 10 && digits.startsWith("5")) {
    return `+90${digits}`;
  }

  return raw;
}

function accountingNormalizeSaleItems(items) {
  if (!Array.isArray(items) || items.length === 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "En az bir satis kalemi gerekir."
    );
  }

  return items.map((item, index) => {
    const source = item || {};
    return {
      ...source,
      itemType: accountingRequiredString(
        source.itemType || "manual",
        `items[${index}].itemType`
      ),
      name: accountingRequiredString(source.name, `items[${index}].name`),
      quantity: accountingPositiveKurus(
        source.quantity,
        `items[${index}].quantity`
      ),
      unitPriceKurus: accountingNonNegativeKurus(source.unitPriceKurus),
      lineTotalKurus: accountingPositiveKurus(
        source.lineTotalKurus,
        `items[${index}].lineTotalKurus`
      )
    };
  });
}

function validateAccountingCreateManualSale(data) {
  const payload = data || {};
  const businessId = accountingRequiredString(payload.businessId, "businessId");
  const saleType = accountingRequiredString(payload.saleType, "saleType");
  const source = accountingRequiredString(payload.source || "manual", "source");
  const totalAmountKurus = accountingPositiveKurus(
    payload.totalAmountKurus,
    "totalAmountKurus"
  );
  const paidAmountKurus = accountingNonNegativeKurus(payload.paidAmountKurus);
  const remainingAmountKurus = accountingNonNegativeKurus(
    payload.remainingAmountKurus
  );

  if (paidAmountKurus > totalAmountKurus && remainingAmountKurus > 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Tahsil edilen tutar satis tutarindan buyuk olamaz."
    );
  }

  return {
    ...payload,
    businessId,
    source,
    saleType,
    totalAmountKurus,
    paidAmountKurus,
    remainingAmountKurus,
    customerPhone: accountingNormalizePhone(payload.customerPhone),
    items: accountingNormalizeSaleItems(payload.items),
    schemaVersion: 1
  };
}

function validateAccountingCollectPayment(data) {
  const payload = data || {};
  return {
    ...payload,
    businessId: accountingRequiredString(payload.businessId, "businessId"),
    saleId: accountingRequiredString(payload.saleId, "saleId"),
    amountKurus: accountingPositiveKurus(payload.amountKurus, "amountKurus"),
    method: accountingRequiredString(payload.method, "method"),
    schemaVersion: 1
  };
}

function validateAccountingCreateExpense(data) {
  const payload = data || {};
  return {
    ...payload,
    businessId: accountingRequiredString(payload.businessId, "businessId"),
    category: accountingRequiredString(payload.category, "category"),
    title: accountingRequiredString(payload.title, "title"),
    amountKurus: accountingPositiveKurus(payload.amountKurus, "amountKurus"),
    paymentMethod: accountingRequiredString(payload.paymentMethod, "paymentMethod"),
    status: accountingText(payload.status, "pending"),
    schemaVersion: 1
  };
}

function accountingValueMatchesUid(value, uid) {
  if (Array.isArray(value)) {
    return value.some((item) => accountingValueMatchesUid(item, uid));
  }

  return accountingText(value).toLowerCase() === accountingText(uid).toLowerCase();
}

async function assertAccountingBusinessPermission(uid, businessId, permissionKey) {
  const businessRef = db.doc(`businesses/${businessId}`);
  const businessSnap = await businessRef.get();

  if (!businessSnap.exists) {
    throw new functions.https.HttpsError(
      "not-found",
      "Kurumsal hesap bulunamadi."
    );
  }

  const business = businessSnap.data() || {};
  const ownerFields = [
    business.ownerUid,
    business.ownerId,
    business.businessOwnerUid,
    business.userId,
    business.uid,
    business.createdBy,
    business.createdByUid,
    business.adminUid,
    business.managerUid,
    business.ownerUids,
    business.adminUids,
    business.managerUids,
    business.authorizedUids
  ];

  if (ownerFields.some((value) => accountingValueMatchesUid(value, uid))) {
    return;
  }

  const staffQuery = await db
    .collection("businessStaff")
    .where("businessId", "==", businessId)
    .limit(100)
    .get();

  const staffDoc = staffQuery.docs.find((doc) => {
    const staff = doc.data() || {};
    if (staff.isActive === false) return false;

    return [
      staff.linkedUid,
      staff.staffUid,
      staff.userId,
      staff.uid,
      staff.userUid
    ].some((value) => accountingValueMatchesUid(value, uid));
  });

  if (!staffDoc) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Bu kurumsal hesap icin yetkiniz yok."
    );
  }

  const staff = staffDoc.data() || {};
  const permissions = staff.permissions || {};

  if (
    permissions[permissionKey] === true ||
    permissions.financeAdmin === true ||
    staff[permissionKey] === true
  ) {
    return;
  }

  throw new functions.https.HttpsError(
    "permission-denied",
    "Bu muhasebe islemi icin yetkiniz yok."
  );
}

exports.accountingCreateManualSale = functions.https.onCall(async (data, context) => {
    const uid = accountingSignedInUid(context);
    const input = validateAccountingCreateManualSale(data);
    await assertAccountingBusinessPermission(uid, input.businessId, "financeWrite");

    const now = admin.firestore.FieldValue.serverTimestamp();
    const saleRef = db
      .collection(`businesses/${input.businessId}/accountingSales`)
      .doc();
    const batch = db.batch();

    batch.set(saleRef, {
      ...input,
      saleId: saleRef.id,
      createdByUid: uid,
      createdAt: now,
      updatedAt: now
    });

    if (input.paidAmountKurus > 0) {
      const paymentRef = db
        .collection(`businesses/${input.businessId}/accountingPayments`)
        .doc();

      batch.set(paymentRef, {
        paymentId: paymentRef.id,
        saleId: saleRef.id,
        businessId: input.businessId,
        customerId: input.customerId || null,
        amountKurus: input.paidAmountKurus,
        method: input.paymentMethod,
        collectedAt: now,
        collectedByUid: uid,
        source: "manualSale",
        createdAt: now,
        schemaVersion: 1
      });
    }

    if (input.remainingAmountKurus > 0) {
      const receivableRef = db
        .collection(`businesses/${input.businessId}/accountingReceivables`)
        .doc();

      batch.set(receivableRef, {
        receivableId: receivableRef.id,
        saleId: saleRef.id,
        businessId: input.businessId,
        customerId: input.customerId || null,
        customerName: input.customerName || null,
        customerPhone: input.customerPhone || null,
        amountKurus: input.remainingAmountKurus,
        dueDate: input.dueDate || null,
        status: "open",
        createdAt: now,
        updatedAt: now,
        schemaVersion: 1
      });
    }

    await batch.commit();

    return {
      ok: true,
      saleId: saleRef.id
    };
});

exports.accountingCollectPayment = functions.https.onCall(async (data, context) => {
    const uid = accountingSignedInUid(context);
    const input = validateAccountingCollectPayment(data);
    await assertAccountingBusinessPermission(uid, input.businessId, "financeWrite");

    const now = admin.firestore.FieldValue.serverTimestamp();
    const paymentRef = db
      .collection(`businesses/${input.businessId}/accountingPayments`)
      .doc();

    await paymentRef.set({
      ...input,
      paymentId: paymentRef.id,
      collectedByUid: uid,
      collectedAt: now,
      createdAt: now
    });

    return {
      ok: true,
      paymentId: paymentRef.id
    };
});

exports.accountingCreateExpense = functions.https.onCall(async (data, context) => {
    const uid = accountingSignedInUid(context);
    const input = validateAccountingCreateExpense(data);
    await assertAccountingBusinessPermission(uid, input.businessId, "expenseWrite");

    const now = admin.firestore.FieldValue.serverTimestamp();
    const expenseRef = db
      .collection(`businesses/${input.businessId}/accountingExpenses`)
      .doc();
    const batch = db.batch();

    batch.set(expenseRef, {
      ...input,
      expenseId: expenseRef.id,
      createdByUid: uid,
      createdAt: now,
      updatedAt: now
    });

    if (input.recurring === true) {
      const recurringRef = db
        .collection(`businesses/${input.businessId}/accountingRecurringExpenses`)
        .doc();

      batch.set(recurringRef, {
        recurringExpenseId: recurringRef.id,
        sourceExpenseId: expenseRef.id,
        businessId: input.businessId,
        category: input.category,
        title: input.title,
        amountKurus: input.amountKurus,
        paymentMethod: input.paymentMethod,
        recurrencePeriod: input.recurrencePeriod || "monthly",
        nextDate: input.nextDate || null,
        active: true,
        createdByUid: uid,
        createdAt: now,
        updatedAt: now,
        schemaVersion: 1
      });
    }

    await batch.commit();

    return {
      ok: true,
      expenseId: expenseRef.id
    };
});
