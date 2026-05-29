"use strict";

function registerAiGenerationFunctions({
  exportsTarget,
  onRequest,
  HttpsError,
  functions,
  OPENAI_API_KEY,
  cleanText,
  requireHttpAuth,
  requireLegacyCallableAuth,
  enforceFunctionRateLimit,
}) {
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
  
  exportsTarget.generateCampaignAiHttp = onRequest(
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
  
      try {
        const uid = await requireHttpAuth(req, "generateCampaignAiHttp");
        await enforceFunctionRateLimit({
          uid,
          functionName: "generateCampaignAiHttp",
          limit: 20,
          windowSeconds: 60,
        });
  
        const data = req.body || {};
        if (JSON.stringify(data).length > 12000) {
          throw new HttpsError("invalid-argument", "Kampanya istegi cok buyuk.");
        }
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
  
        if (error instanceof HttpsError) {
          res.status(error.code === "unauthenticated" ? 401 : 429).json({
            ok: false,
            error: error.message,
            code: error.code,
          });
          return;
        }
  
        const data = req.body || {};
        res.status(200).json(
          fallbackCampaign(data, error && error.message ? error.message : "unknown_error")
        );
      }
    }
  );
  
  exportsTarget.generateBusinessAnalysisAiHttp = functions.https.onCall(async (data, context) => {
    const uid = requireLegacyCallableAuth(context, "generateBusinessAnalysisAiHttp");
    await enforceFunctionRateLimit({
      uid,
      functionName: "generateBusinessAnalysisAiHttp",
      limit: 20,
      windowSeconds: 60,
    });
  
    const payload = data || {};
    const summary = payload.summary || {};
  
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
  
    }
  });
  
  
  
}

module.exports = {
  registerAiGenerationFunctions,
};
