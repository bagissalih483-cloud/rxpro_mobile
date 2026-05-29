"use strict";

const BUSINESS_PLACE_INDEX_COLLECTION = "businessPlaceIndex";
const PLACE_QUERY_BUCKETS_COLLECTION = "placeQueryBuckets";
const PLACE_DIRECTORY_CACHE_DAYS = 30;
const GEOHASH_ALPHABET = "0123456789bcdefghjkmnpqrstuvwxyz";

function registerDirectoryFunctions({
  exportsTarget,
  onCall,
  HttpsError,
  admin,
  db,
  GOOGLE_PLACES_API_KEY,
  cleanText,
  safeSecretValue,
  requireCallableAuth,
  enforceFunctionRateLimit,
  enablePlacesDirectorySearch = false,
}) {
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
  
  function offsetCoordinate(latitude, longitude, distanceMeters, bearingDegrees) {
    const earthRadiusMeters = 6371000;
    const angularDistance = distanceMeters / earthRadiusMeters;
    const bearing = (bearingDegrees * Math.PI) / 180;
    const lat1 = (latitude * Math.PI) / 180;
    const lng1 = (longitude * Math.PI) / 180;
  
    const lat2 = Math.asin(
      Math.sin(lat1) * Math.cos(angularDistance) +
        Math.cos(lat1) * Math.sin(angularDistance) * Math.cos(bearing),
    );
    const lng2 =
      lng1 +
      Math.atan2(
        Math.sin(bearing) * Math.sin(angularDistance) * Math.cos(lat1),
        Math.cos(angularDistance) - Math.sin(lat1) * Math.sin(lat2),
      );
  
    const normalizedLng =
      ((((lng2 * 180) / Math.PI + 540) % 360) - 180);
  
    return {
      latitude: Math.max(-90, Math.min(90, (lat2 * 180) / Math.PI)),
      longitude: normalizedLng
    };
  }
  
  function directorySearchCenters(latitude, longitude, radiusMeters) {
    const centers = [
      {
        key: "center",
        latitude,
        longitude,
        radiusMeters
      }
    ];
  
    if (radiusMeters < 1200) return centers;
  
    const offsetMeters = Math.min(
      Math.max(radiusMeters * 0.55, 800),
      10000,
    );
    const childRadiusMeters = Math.max(
      500,
      Math.min(radiusMeters * 0.6, radiusMeters),
    );
    const bearings = radiusMeters >= 8000
      ? [0, 90, 180, 270, 45, 135, 225, 315]
      : [0, 90, 180, 270];
  
    for (const bearing of bearings) {
      const point = offsetCoordinate(latitude, longitude, offsetMeters, bearing);
      centers.push({
        key: `offset_${bearing}`,
        latitude: point.latitude,
        longitude: point.longitude,
        radiusMeters: childRadiusMeters
      });
    }
  
    return centers;
  }
  
  function planDirectorySearches({ typeQueries, centers, maxSearchCalls }) {
    const planned = [];
  
    for (const center of centers) {
      for (const query of typeQueries) {
        planned.push({ query, center });
        if (planned.length >= maxSearchCalls) return planned;
      }
    }
  
    return planned;
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
          rankPreference: "DISTANCE",
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
  
  if (enablePlacesDirectorySearch) {
    exportsTarget.searchNearbyDirectoryBusinesses = onCall(
      {
        region: "europe-west1",
        secrets: [GOOGLE_PLACES_API_KEY],
        timeoutSeconds: 30,
        memory: "256MiB"
      },
      async (request) => {
      const uid = requireCallableAuth(request, "searchNearbyDirectoryBusinesses");
      await enforceFunctionRateLimit({
        uid,
        functionName: "searchNearbyDirectoryBusinesses",
        limit: 30,
        windowSeconds: 60,
      });
  
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
      const maxResultCount = Math.round(clampNumber(data.limit, 1, 200, 120));
      const maxSearchCalls = Math.round(clampNumber(data.maxSearchCalls, 1, 40, 18));
      const categoryId = directoryCategoryId(data);
      const searchCenters = directorySearchCenters(
        latitude,
        longitude,
        radiusMeters,
      );
      const plannedQueries = planDirectorySearches({
        typeQueries: directoryTypeQueriesForCategory(categoryId),
        centers: searchCenters,
        maxSearchCalls
      });
      const debug = data.debug === true;
  
      try {
        const placesByQuery = [];
        let successfulCalls = 0;
        let skippedCalls = 0;
  
        const runQuery = async ({ query, center }) => ({
          query,
          center,
          result: await fetchNearbyPlaces({
            apiKey,
            latitude: center.latitude,
            longitude: center.longitude,
            radiusMeters: center.radiusMeters,
            maxResultCount: 20,
            includedTypes: query.includedTypes,
          })
        });
  
        const queryResults = await Promise.all(plannedQueries.map(runQuery));
  
        for (const { query, center, result } of queryResults) {
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
              includedTypes: query.includedTypes,
              center: center && center.key
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
          const fallbackResults = await Promise.all(
            planDirectorySearches({
              typeQueries: fallbackQueries,
              centers: searchCenters,
              maxSearchCalls
            }).map(runQuery),
          );
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
          .filter(
            (item) =>
              distanceKmBetween(latitude, longitude, item.lat, item.lng) <=
              radiusMeters / 1000 + 0.05,
          )
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
          searchCenterCount: searchCenters.length,
          successfulCalls,
          skippedCalls,
          rawPlaceCount: placesByQuery.length,
          uniquePlaceCount: places.length,
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
  }
  
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
  
  exportsTarget.calculateBusinessRouteInfo = onCall(
    {
      region: "europe-west1",
      secrets: [GOOGLE_PLACES_API_KEY],
      timeoutSeconds: 15,
      memory: "256MiB"
    },
    async (request) => {
      const uid = requireCallableAuth(request, "calculateBusinessRouteInfo");
      await enforceFunctionRateLimit({
        uid,
        functionName: "calculateBusinessRouteInfo",
        limit: 120,
        windowSeconds: 60,
      });
  
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
  
  
}

module.exports = {
  registerDirectoryFunctions,
};
