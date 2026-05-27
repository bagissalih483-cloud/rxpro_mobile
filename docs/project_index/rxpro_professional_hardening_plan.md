# RxPro Professional Hardening Plan

Bu belge projeyi uretime yakin, surdurulebilir ve servis odakli hale getirmek icin kalan ana isleri takip eder.

## Tamamlanan Temel Adimlar

- Git takibine girmemesi gereken Flutter, Firebase, Node ve yerel ortam ciktilari `.gitignore` icine eklendi.
- Android Gradle wrapper dosyalarinin takip edilebilmesi icin `android/.gitignore` duzeltildi.
- Android uygulama etiketi `RxPro` olarak duzeltildi ve manifest bicimi toparlandi.
- Android ana manifestine production icin acik `INTERNET` izni eklendi.
- iOS kamera, fotograf arsivi ve konum izin aciklamalari eklendi.
- Yerel kalite kontrol komutu `tools/quality_check.ps1` olarak eklendi.
- Git deposu baslatildi; ancak bu sandbox `.git` icine indeks/config yazmayi engelledigi icin ilk commit normal kullanici ortaminda atilmali.
- `BusinessLiveFlowPage` Firestore okumalari repository sinirina tasindi.
- `BusinessDurationAnalyticsPage` Firestore okumalari repository sinirina tasindi.
- `HomeExplorePage` badge ve auth erisimleri repository sinirina tasindi.
- Business profile post interaction card, fix login gate, favorite feed, customer notifications, accounting permission session card, business profile edit entry and campaign AI creation now avoid direct Firebase access from UI code.
- `NotificationCenterPage` scope resolution and notification stream/filter/sort logic repository sinirina tasindi.
- `BusinessRoleResolver` legacy facade olarak korundu; Firebase rol/cozumleme isi `BusinessRoleRepository` altina tasindi.
- Mesaj, randevu, staff workspace, isletme profili, hesap girisi ve `main.dart` auth erisimleri repository/service sinirina tasindi.
- Dogrudan Firebase yuzeyi repository/service/domain disinda 29 dosyadan 8 servis/cekirdek altyapi dosyasina indirildi.
- Hedef proje agaci, katman sozlesmesi ve calisma algoritmasi `rxpro_target_architecture.md` ve `rxpro_working_algorithm.md` icinde sabitlendi.
- `tools/architecture_check.ps1` eklendi ve `tools/quality_check.ps1` icine baglandi.
- Yeni saf model testleri eklendi: urun hareketi, canli akis ve sure analizi mapping testleri.
- Kalan teknik borc `docs/project_index/rxpro_remaining_gaps.md` icinde envanterlendi.
- Kullanici ortaminda `flutter analyze` temiz dogrulandi: `No issues found`.
- CI kalite kapisi eklendi: `tools/ci_quality_check.ps1` ve `.github/workflows/flutter_quality.yml`.
- Release hazirlik kontrol listesi eklendi: `docs/project_index/rxpro_release_readiness_checklist.md`.
- README kalite, mimari ve release komutlariyla guncellendi.
- Crashlytics/global error capture ve temel Analytics app-open/screen observer bootstrap'a baglandi.
- Mojibake temizligi baslatildi: kampanya AI, isletme analizi AI ve sifre sifirlama ekrani temiz metin yoluna alindi.
- Feature mimari raporu eklendi: `tools/feature_architecture_report.ps1`.
- Auth icinde ilk `presentation/pages` kesiti olusturuldu ve sifre sifirlama ekrani bu yapıya tasindi.
- Sifre sifirlama akisi icin widget test eklendi.
- `FixLoginGatePage` auth presentation/pages altina tasindi; eski import yolu compatibility export olarak korundu.
- Auth giris/kayit aksiyonlari ve marka alani presentation/widgets altina ayrildi.
- Auth feature icinde 30KB uzeri buyuk dosya sayisi 0'a indirildi.
- `AccountEntryPage` public_home presentation/pages altina tasindi; eski import yolu compatibility export olarak korundu.
- Account entry kartlari, menu scaffold'u, hafif profil/ayar sayfalari ve context modeli presentation altinda parcalandi.
- Public home feature icinde 30KB uzeri buyuk dosya sayisi 0'a indirildi.
- `BusinessAnalysisPage` business_analysis presentation/pages altina tasindi; eski import yolu compatibility export olarak korundu.
- Business product movement page de business_analysis presentation/pages altina tasindi.
- Business analysis kartlari/modelleri presentation altina, AI callable ve analiz algoritmasi servis katmanina ayrildi.
- Business analysis feature icinde 30KB uzeri buyuk dosya sayisi 0'a indirildi.
- Business analysis hesaplama servisi icin tarih filtreleme, iptal eleme, gelir/adet ozeti ve top-list davranisini kilitleyen saf test eklendi.
- `AppointmentEntryPage` ve `CustomerAppointmentsPage` appointments presentation/pages altina tasindi; eski import yollari compatibility export olarak korundu.
- Appointment dashboard gorunumleri/modelleri ve customer appointment UI parcalari presentation altinda ayrildi.
- Appointments feature icinde 30KB uzeri buyuk dosya sayisi 0'a indirildi.
- `BusinessFinancePage` businesses presentation/pages altina tasindi; eski import yolu compatibility export olarak korundu.
- Business finance modelleri, widget'lari ve formatter yardimcilari businesses presentation altina ayrildi.
- Business finance formatter davranisi icin saf test eklendi.
- `BusinessStaffManagePage` businesses presentation/pages altina tasindi; eski import yolu compatibility export olarak korundu.
- Staff form sayfasi ve staff group/card UI parcalari businesses presentation altina ayrildi.
- `AccountingSalesPage` accounting presentation/pages altina tasindi; eski import yolu compatibility export olarak korundu.
- Accounting sales wizard widget'lari ve hafif modelleri accounting presentation altina ayrildi.
- Accounting feature icinde 30KB uzeri buyuk dosya sayisi 0'a indirildi.
- Konum kesfi icin Google Places/GeoPoint/lat-lng formatlarini normalize eden ortak parser eklendi.
- Bireysel kesfet ekraninda akilli/on yakin/puan/kategori/A-Z siralama ve yol tarifi akisi eklendi.
- Uye isletme ile directory-only Google/import kayitlari kesfet kartinda ayrildi.
- Kurumsal profil duzenleme ekranina isletme konumu alma ve GeoPoint dahil koordinat kaydi eklendi.
- Konum kesfi icin geohash prefix uretimi, konum yaziminda geohash alanlari ve kullanici konumu varken indeksli yakinlik sorgusu eklendi.
- Eski/Google-import isletmeler icin dry-run-first geohash backfill scripti eklendi.
- Google Places canli yakindaki isletme aramasi server-side callable olarak eklendi; mobil uygulama API anahtarini tasimadan uye isletmelerle directory-only kayitlari birlestiriyor.
- Buyuk sehirler icin placeId + minimum geo/category index seed scripti eklendi.
- Places callable icin health-check ve okunur runtime hata donusu eklendi.
- Google directory-only isletmeler icin kullanici sahiplenme talebi ve Firestore rule siniri eklendi.
- Business appointment management musteri mesaj sayfasi ve randevu UI parcalari presentation altina ayrildi; root page 30KB altina indi.
- Proje genelinde 30KB uzeri buyuk Dart dosyasi sayisi 2'ye indirildi.
- Test dosyasi sayisi 12'ye, `lib` Dart dosyasi sayisi 197'ye cikti.

## Kalan Kritik Isler

- Full kalite kapisi kullanici ortaminda ve GitHub Actions uzerinde calistirilmali.
- Ilk Git commit normal kullanici ortaminda olusturulmali.
- Firebase CLI ile Firestore/Storage rules emulator testleri kurulup deploy oncesi zorunlu hale getirilmeli.
- iOS icin gercek `GoogleService-Info.plist` Firebase Console uzerinden eklenmeli.
- Kalan 8 cekirdek servis dosyasinda adapter/facade siniri ve emulator destekli testler tamamlanmali.
- Yeni Places callable patchi deploy edilmeli, `tools/check_places_function.ps1` ile secret/runtime sagligi dogrulanmali, buyuk sehir seed scripti once dry-run sonra write olarak calistirilmali.
- Sahiplenme talepleri icin admin/onay paneli ve onaylaninca RxPro tam profile donusturen backend is akisi tamamlanmali.
- Mevcut/Google-import isletme kayitlari icin geohash backfill scripti dry-run/write sirasi ile calistirilmali ve Firestore index konfigurasyonu dogrulanmali.
- Cloud Functions tarafindaki TypeScript accounting taslaklari ile canli `index.js` uygulamasi tek kaynak olacak sekilde birlestirilmeli.
- Test kapsami servis, repository, rules ve Cloud Functions ekseninde genisletilmeli.
- Android/iOS paket kimlikleri `com.example.*` olmaktan cikarilmali ve production kimlige tasinmali.
- Android release signing debug key yerine production keystore ile yapilandirilmali.
- Analytics event sozlesmesi auth, discovery, booking, campaign, message ve finance akislari icin genisletilmeli.
- CI workflow ilk commit sonrasi uzak repoda yesil calistirilmali.
- Kalan mojibake/encoding bozuk metinler moduller halinde temizlenmeli.
- Kalan 11 feature icin presentation siniri kademeli olusturulmali.
- Kalan 2 adet 30KB uzeri buyuk page dosyasi kademeli parcalanmali.
- Feed, media, moderation, block/report ve notification preference akislari sosyal olcek icin tamamlanmali.

## Oncelik Sirasi

1. Ilk Git commit ve CI sonucunu kilitleme.
2. Platform izinleri ve Firebase konfigurasyon dogrulamasi.
3. Konum kesfi icin Places secret/deploy, seed/backfill dry-run/write, Firestore index kontrolu ve emulator testi.
4. Rules emulator testleri.
5. Kilitli olmayan ekranlarda servislesme.
6. Kilitli alanlarda exact audit sonrasi kontrollu servislesme.
7. Tam build, smoke test ve release checklist.

## 2026-05-26 Audit Baglantisi

Profesyonel urun/release/security/codebase audit kaydi:

- `docs/project_index/rxpro_professional_audit_20260526.md`
