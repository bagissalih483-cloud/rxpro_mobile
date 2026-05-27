# RxPro Remaining Gaps

Bu belge 64F-64Q servislesme sprinti sonrasinda kalan profesyonel tamamlama borcunu netlestirir.

## Kalan Dogrudan Firebase Yuzeyi

Repository/service/domain klasorleri haric tutuldugunda dogrudan Firebase veya Firestore izi 8 dosyaya indi. Onceki oncelikli ekranlar temizlendi:

- `lib/features/messages/messages_inbox_page.dart`
- `lib/features/businesses/business_appointment_management_page.dart`
- `lib/features/businesses/staff_workspace_page.dart`
- `lib/features/businesses/business_profile_page.dart`
- `lib/features/appointments/customer_appointments_page.dart`
- `lib/features/appointments/appointment_entry_page.dart`
- `lib/features/public_home/account_entry_page.dart`
- `lib/features/businesses/staff_tasks_entry_page.dart`
- `lib/features/businesses/business_staff_manage_page.dart`
- `lib/main.dart`

Kalan 8 dosya artik ekran degil, servis/cekirdek altyapi yuzeyi olarak ele alinmali:

- `lib/core/app_state/current_user_state_service.dart`
- `lib/core/app_state/follow_cache_warmup_service.dart`
- `lib/core/businesses/business_directory_cache_service.dart`
- `lib/core/realtime/rx_notification_service.dart`
- `lib/core/realtime/rx_push_notification_service.dart`
- `lib/core/session/app_session_controller.dart`
- `lib/features/staff_invites/staff_invite_service.dart`
- `lib/features/stories/business_story_service.dart`

Bu kalan 8 dosya icin hedef, Firebase erisimini tamamen yok etmek degil; servis sorumluluklarini daraltmak, test edilebilir adapter/facade sinirlari eklemek ve emulator testleriyle davranisi kilitlemektir.

## Kalan Urun Ozellikleri

- Toplu mesaj taslagi var; musteri defteri segmentlerinden isletme id'siyle bagli taslak aciliyor. Gercek FCM/push gonderim backend akisi hala tamamlanmali.
- SMS ile sifre sifirlama ekrani hazir; gercek dogrulama ve sifre guncelleme baglanmali.
- Muhasebe PDF/Excel export akisi hazirlik seviyesinde.
- Muhasebe gider duzenleme ve tekrarlayan gider planlama tam backend akisi istiyor.
- Profil tanitim videosu secme/yukleme/yayinlama henuz aktif degil.
- Ayarlar, bildirim tercihleri ve devamlik modulleri gercek hedef ekranlara baglanmali.
- Konum kesfi icin istemci tarafinda siralama, mesafe, yol tarifi, geohash tabanli yakindaki isletme sorgusu ve Google Places canli directory-only arama eklendi.
- Konum kesfinde kalan borc: yeni Places health-check patchini deploy edip dogrulama, buyuk sehir seed scriptini dry-run/write olarak calistirma, geohash backfill, Firestore index konfigurasyonu ve emulator testleri.
- Google directory-only isletmeler icin kullanici tarafindan sahiplenme talebi olusturma eklendi; admin/onay paneli ve claim-to-member donusum fonksiyonu hala eksik.

## Kalan Metin/Encoding Borcu

- Kampanya AI, isletme analizi AI ve sifre sifirlama ekrani icin temiz metin yolu eklendi.
- Kod tabaninda baska mojibake kalintilari bulunuyor; bunlar feature feature temizlenmeli.
- Ozellikle auth, appointment, notification, business profile ve docs metinleri sonraki temizlik sirasi icin aday.

## Platform ve Release Eksikleri

- iOS icin `GoogleService-Info.plist` dosyasi yok; Firebase Console'dan alinip `ios/Runner/` altina eklenmeli.
- Firebase CLI bu ortamda bulunamadi; rules emulator ve deploy oncesi validation calistirilmali.
- Flutter analyze kullanici ortaminda temiz dogrulandi; full CI kalite kapisi yine de kullanici ortaminda ve GitHub Actions uzerinde calistirilmali.
- CI workflow ve giris betigi eklendi; ilk commit sonrasi uzak repoda yesil sonuc alinmali.
- Git repository baslatildi, ancak sandbox `.git` indeks/config yazimini engelledi; ilk commit kullanici ortaminda atilmali.

## Kalan Test Borcu

- Test dosyasi sayisi 15'e cikti; bu hala buyuk uygulama icin dusuk.
- Auth sifre sifirlama akisi icin ilk presentation widget testi eklendi.
- Auth giris/kayit sayfasi presentation/pages altina tasindi ve auth feature icinde 30KB uzeri dosya kalmadi.
- Public home account entry presentation/pages altina tasindi ve public_home feature icinde 30KB uzeri dosya kalmadi.
- Business analysis presentation/pages altina tasindi; AI callable ve analiz algoritmasi servis katmanina ayrildi.
- Business analysis computation servisi icin saf test eklendi.
- Appointments feature presentation/pages altina tasindi ve appointments feature icinde 30KB uzeri dosya kalmadi.
- Business finance presentation/pages altina tasindi; formatter yardimcilari saf testle kilitlendi.
- Business staff management presentation/pages altina tasindi; staff form ve staff group/card UI parcalari ayrildi.
- Accounting sales presentation/pages altina tasindi; wizard widget'lari ve hafif modelleri ayrildi.
- Konum parser, mesafe hesabi ve geohash prefix algoritmasi icin saf testler eklendi.
- Business appointment management musteri mesaj sayfasi ve tekrar kullanilabilir randevu UI parcalari presentation altina ayrildi; root page 30KB altina indi.
- Kurumsal musteri defteri icin randevu gecmisi + manuel kayit birlestirme ve segment algoritmasi saf testlerle kilitlendi.
- Firebase emulator destekli repository testleri eksik.
- Cloud Functions callable testleri eksik.
- Firestore/Storage rules testleri eksik.
- Kritik ekranlar icin smoke/widget testleri eksik.

## 2026-05-26 PDF Audit Sonrasi Guncel Oncelik

- PDF raporlarindaki en guncel ve dogru P0/P1 maddeler: AppSession tek kaynak, Kesfet performans controller/cache akisi, Firestore query/pagination standardi, Cloud Functions modul ayrimi, emulator testleri ve release hazirligi.
- PDF raporlarindaki `test yok` bulgusu artik stale: projede 15 Dart test dosyasi var; yine de kapsam dusuk oldugu icin test borcu devam ediyor.
- PDF raporlarindaki `HomeExplorePage CurrentUserStateService kullanıyor` bulgusu 65Z ile kapatildi: Kesfet artik gorunur user context icin `AppSessionScope` okuyor.
- PDF raporlarindaki `SharedPreferences.getInstance her seferinde cagriliyor` bulgusu AppCacheService icin kapatildi: cache servisinde tek future reuse ediliyor.
- Kalan legacy state riski: `CurrentUserStateService` cekirdek legacy adapter olarak duruyor; diger ekranlarda dogrudan kullanimi su an gorunmuyor, fakat tamamen kaldirma icin SessionRoleGate fallback ve cache/role gecisleri ayrica audit edilmeli.

## 2026-05-26 UI Aksiyon Sistemi Guncellemesi

- Kesfet kontrol panelinde konuma gore siralama artik birincil gorunur aksiyon olarak duruyor; yatay siralama chip'leri icinde kaybolmuyor.
- Kesfet directory-only kartlarinda yaklasik km bilgisi adres metnine gomulu degil, ayri yakinlik etiketi olarak gosteriliyor.
- Hesabim kurumsal akisi icin ana komuta paneli eklendi: randevular, musteriler, toplu mesaj, mesajlar, profil ve operasyon.
- Business Owner Hub ana sayfasi Fix Isletme Merkezi olarak yeniden duzenlendi; hizli aksiyonlar ve isletme yonetimi bolumleri ayrildi.
- Musteri defteri header aksiyonlari ayri widget'a tasindi; sayfa 30KB buyuk dosya limitinin altinda tutuldu.
- Devamlilik, tanitim/paylasim, personel kampanya/paylasim, personel finans ve stok defteri placeholder akislari gercek ekranlara veya mevcut veriden calisan gorunumlere baglandi.
- Uygulama ayarlari artik cihazda saklanan tercih ekranina donustu; rota mesafesi tercihi Kesfet rota hesaplama chip'i tarafindan okunuyor.
- Kalan UI borcu: ayni aksiyon sistemi finans, hizmet, personel ve kampanya alt sayfalarinda daha fazla ortak bilesene yayilmali; kritik ekranlar icin widget smoke testleri eklenmeli.

## Onerilen Sonraki Uygulama Sirasi

1. Kullanici ortaminda ilk Git commit.
2. `tools/ci_quality_check.ps1 -SkipBuild` ile format/analyze/test kapisini calistirma.
3. GitHub Actions uzerinde CI sonucunu yesile alma.
4. Firebase CLI kurulumu ve rules emulator testleri.
5. Konum kesfi icin yeni Places deploy + health-check, seed/backfill scriptlerini dry-run/write sirasi ile calistirma, Firestore index kontrolu ve emulator testleri.
6. Kalan cekirdek servislerde adapter/facade siniri ve emulator testleri.
7. Backend callable/functions tek kaynak duzenlemesi.
8. Kalan feature'larda presentation siniri ve kalan 2 buyuk page dosyasini parcalama.
9. Kalan gorunur mojibake metinlerin feature feature temizlenmesi.
10. Release build ve manuel smoke test.

## 2026-05-26 Profesyonel Audit Notu

Detayli profesyonel seviye audit su dosyada kayitli:

- `docs/project_index/rxpro_professional_audit_20260526.md`

Yeni audit, kalan borcu sadece servislesme olarak degil; release, guvenlik, test, CI sonucu, paket kimligi, signing, Crashlytics, App Check, feed/media/moderation ve kod agaci olgunlugu olarak siniflandirir.
