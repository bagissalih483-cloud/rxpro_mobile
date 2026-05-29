import 'legal_document.dart';

class LegalDocumentsRepository {
  const LegalDocumentsRepository();

  static final DateTime _releaseDate = DateTime(2026, 5, 29);

  List<LegalDocument> list() => [
    LegalDocument(
      id: 'privacy_policy',
      title: 'Gizlilik Politikası',
      version: '2026.05.29-1',
      lastUpdated: _releaseDate,
      audience: LegalAudience.all,
      summary:
          'RxPro hesap, konum, randevu, mesaj, işletme ve kullanım verilerini hizmeti sunmak, güvenliği sağlamak ve deneyimi iyileştirmek için işler.',
      sections: const [
        LegalSection(
          title: 'Toplanan veriler',
          body:
              'Hesap bilgileri, iletişim bilgileri, randevu kayıtları, işletme profili, personel yetkileri, mesaj ve bildirim kayıtları, konum izni verilirse yaklaşık/cihaz konumu, görsel içerikler ve teknik kullanım kayıtları işlenebilir.',
        ),
        LegalSection(
          title: 'Kullanım amaçları',
          body:
              'Veriler; hesap oluşturma, işletme keşfi, randevu yönetimi, bildirim gönderimi, mesajlaşma, kampanya gösterimi, güvenlik, hata analizi, dolandırıcılık ve kötüye kullanım önleme amaçlarıyla kullanılır.',
        ),
        LegalSection(
          title: 'Paylaşım',
          body:
              'Randevu ve işlem için gerekli bilgiler ilgili müşteri, işletme ve yetkili personel arasında paylaşılır. Yasal zorunluluklar, güvenlik incelemeleri ve hizmet sağlayıcı altyapıları dışında üçüncü kişilerle amaç dışı paylaşım yapılmaz.',
        ),
        LegalSection(
          title: 'Saklama ve silme',
          body:
              'Veriler hizmet ilişkisi, yasal yükümlülükler ve uyuşmazlık güvenliği için gerekli süre boyunca saklanır. Hesap silme talebiyle kişisel veriler silinir veya anonimleştirilir; mevzuat gereği saklanması gereken kayıtlar sınırlı süre korunabilir.',
        ),
      ],
    ),
    LegalDocument(
      id: 'kvkk_notice',
      title: 'KVKK Aydınlatma Metni',
      version: '2026.05.29-1',
      lastUpdated: _releaseDate,
      audience: LegalAudience.all,
      summary:
          'Bu metin, RxPro içinde kişisel verilerin hangi kapsamda işlendiğini kullanıcı ve işletmelere açıklar.',
      sections: const [
        LegalSection(
          title: 'Veri sorumlusu ve kapsam',
          body:
              'RxPro, uygulama üzerinden sunulan keşif, randevu, mesajlaşma, işletme yönetimi, kampanya ve bildirim hizmetleri kapsamında kişisel verileri işler. Nihai şirket bilgileri yayın öncesi bu metne eklenmelidir.',
        ),
        LegalSection(
          title: 'Hukuki sebepler',
          body:
              'Veriler sözleşmenin kurulması ve ifası, meşru menfaat, hukuki yükümlülük, açık rıza ve kullanıcı tarafından alenileştirme sebeplerine dayanarak işlenebilir.',
        ),
        LegalSection(
          title: 'Haklarınız',
          body:
              'Kişisel verilerinizin işlenip işlenmediğini öğrenme, düzeltme, silme, işlemeyi kısıtlama, itiraz etme ve mevzuattaki diğer haklarınızı destek kanalı üzerinden talep edebilirsiniz.',
        ),
      ],
    ),
    LegalDocument(
      id: 'user_terms',
      title: 'Kullanıcı Sözleşmesi',
      version: '2026.05.29-1',
      lastUpdated: _releaseDate,
      audience: LegalAudience.customer,
      summary:
          'Bireysel kullanıcıların keşif, randevu, mesajlaşma, kampanya ve bildirim özelliklerini hangi kurallarla kullanacağını açıklar.',
      sections: const [
        LegalSection(
          title: 'Hizmetin niteliği',
          body:
              'RxPro; kullanıcıların işletmeleri keşfetmesine, randevu talebi oluşturmasına, bildirim almasına ve işletmelerle uygulama içi iletişim kurmasına aracılık eden dijital bir platformdur.',
        ),
        LegalSection(
          title: 'Kullanıcı sorumluluğu',
          body:
              'Kullanıcı doğru bilgi vermek, başkasının hesabını kullanmamak, randevu saatlerine uymak ve platformu kötüye kullanmamakla yükümlüdür.',
        ),
        LegalSection(
          title: 'Randevu ve iptal',
          body:
              'Randevu uygunluğu işletme ve personel takvimine bağlıdır. İptal, erteleme, gecikme ve gelmeme durumları işletmenin yayınladığı politika ve platform kurallarına göre işlenir.',
        ),
      ],
    ),
    LegalDocument(
      id: 'business_terms',
      title: 'İşletme Kullanım Şartları',
      version: '2026.05.29-1',
      lastUpdated: _releaseDate,
      audience: LegalAudience.business,
      summary:
          'İşletme sahipleri ve yetkili personelin profil, hizmet, randevu, kampanya, mesaj ve muhasebe alanlarını kullanım koşullarını açıklar.',
      sections: const [
        LegalSection(
          title: 'Doğru profil yükümlülüğü',
          body:
              'İşletme; unvan, adres, iletişim, hizmet, fiyat, çalışma saati, personel ve kampanya bilgilerinin doğru, güncel ve yanıltıcı olmamasından sorumludur.',
        ),
        LegalSection(
          title: 'Personel yetkileri',
          body:
              'İşletme sahibi, personel davetleri ve yetkilerinin doğru atanmasından sorumludur. Yetkisiz erişim fark edildiğinde yetkiler derhal kaldırılmalıdır.',
        ),
        LegalSection(
          title: 'Kampanya ve iletişim',
          body:
              'İşletme kampanya, toplu mesaj ve bildirim içeriklerinde hukuka, dürüst ticari uygulamalara ve kullanıcı iletişim izinlerine uygun davranmalıdır.',
        ),
      ],
    ),
    LegalDocument(
      id: 'consent_notice',
      title: 'Açık Rıza ve İletişim Onayı',
      version: '2026.05.29-1',
      lastUpdated: _releaseDate,
      audience: LegalAudience.all,
      summary:
          'Konum, kampanya bildirimi, pazarlama iletişimi ve isteğe bağlı veri işleme izinlerini açıklar.',
      sections: const [
        LegalSection(
          title: 'Konum izni',
          body:
              'Konum izni, yakındaki işletmeleri ve rota/mesafe bilgisini göstermek için kullanılır. İzin cihaz ayarlarından kapatılabilir; kapatıldığında konuma bağlı özellikler sınırlanabilir.',
        ),
        LegalSection(
          title: 'Kampanya iletişimi',
          body:
              'Kampanya ve toplu mesaj bildirimleri yalnızca izinli ve ilgili kullanıcı kitlelerine gönderilmelidir. Kullanıcı bildirim tercihlerini uygulama içinden yönetebilir.',
        ),
      ],
    ),
    LegalDocument(
      id: 'moderation_policy',
      title: 'Şikayet ve Moderasyon Politikası',
      version: '2026.05.29-1',
      lastUpdated: _releaseDate,
      audience: LegalAudience.all,
      summary:
          'Yorum, kampanya, mesaj ve işletme içeriklerinde kötüye kullanımın nasıl ele alınacağını açıklar.',
      sections: const [
        LegalSection(
          title: 'Yasak içerikler',
          body:
              'Hakaret, tehdit, ayrımcılık, yanıltıcı reklam, sahte yorum, spam, kişisel veri ifşası ve hukuka aykırı içerikler platformda yasaktır.',
        ),
        LegalSection(
          title: 'İnceleme ve yaptırım',
          body:
              'Şikayet edilen içerikler incelenebilir; içerik kaldırma, görünürlüğü sınırlama, işletme doğrulamasını askıya alma veya hesap kısıtlama uygulanabilir.',
        ),
      ],
    ),
  ];

  LegalDocument? byId(String id) {
    for (final document in list()) {
      if (document.id == id) return document;
    }
    return null;
  }
}

