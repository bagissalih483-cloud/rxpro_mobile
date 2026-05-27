# fi Muhasebe Modülü Check List

## 46A - Analiz
- [x] Mevcut analiz/finans/randevu/yetki/bildirim dosyaları incelendi.
- [x] Claude muhasebe taslağı mevcut sisteme göre değerlendirildi.
- [x] Geliştirme haritası çıkarıldı.

## 46B - Muhasebe çekirdeği
- [x] `lib/features/accounting` klasörü oluşturuldu.
- [x] Muhasebe model sınıfları eklendi.
- [x] BusinessAccountingShell iskeleti eklendi.
- [x] Özet / Satışlar / Alacaklar / Giderler / Raporlar placeholder ekranları eklendi.
- [x] Kurumsal navigasyon 46C ile bağlandı.

## 46C - Kurumsal sekme entegrasyonu
- [x] Analiz sekmesi adı Muhasebe yapıldı.
- [x] BusinessAnalysisPage yerine BusinessAccountingShell bağlandı.
- [x] financeRead yetki kontrolü eklendi.
- [x] Build alındı; APK test kullanıcı tarafından yapılacak.

## 46D - Manuel satış
- [x] Hizmet satışı girişi UI iskeleti.
- [x] Ãœrün satışı girişi UI iskeleti.
- [ ] Misafir müşteri / kayıtlı müşteri seçimi.
- [ ] Toplam, indirim, kapora, ödeme durumu.

## 46E - Tahsilat / alacak / vade
- [ ] Kapora.
- [x] K\u0131smi \u00f6deme UI iskeleti.
- [x] Vade tarihi UI iskeleti.
- [x] Geciken alacak UI iskeleti sınıflandırması.

## 46F - Gider yönetimi
- [ ] Yeni gider modeli.
- [x] Gider ekleme UI iskeleti.
- [x] Gider listesi demo UI.
- [ ] Gider kategori özeti.

## 46G - Randevu tamamlandı -> satış kaydı
- [ ] Completed appointment satışa dönüşecek.
- [ ] Tahsilat bekleyen olarak listelenecek.

## 46H - Vade bildirimleri
- [ ] Vade yaklaşınca bireysel kullanıcı bildirimi.
- [ ] Vade geçince kurumsal kullanıcı bildirimi.

## 46I - Personel yetki bağlantısı
- [ ] financeRead.
- [ ] financeWrite.
- [ ] expenseWrite.
- [ ] receivableManage.
- [ ] reportExport.

## 46J - Rapor/PDF export
- [x] Dönemsel rapor UI iskeleti.
- [x] PDF/Excel export ön izleme UI iskeleti.
- [x] 46C REV4: Muhasebe sekmesi Türkçe karakterleri Dart unicode escape ile onarıldı.

- [x] 46D: Özet ekranındaki bottom overflow düzeltildi.

## 46E - Manuel satış akış kolaylığı ve veri eşleştirme hazırlığı
- [x] Seçim sonrası otomatik basamak ilerleme iskeleti eklendi.
- [x] Telefonla kayıtlı bireysel kullanıcı eşleştirme alanı eklendi.
- [x] Hizmet / ürün katalog seçim alanı eklendi.
- [x] Özel fiyat / indirim / uygulanan tutar alanı eklendi.
- [x] Vadeli değilse kapanışı uygulanan/tahsil edilen tutardan kapatma seçeneği eklendi.
- [ ] Gerçek telefon sorgusu 46K veri katmanından sonra bağlanacak.
- [ ] Gerçek hizmet/ürün katalog verisi 46K veri katmanından sonra bağlanacak.
## 46E REV1 - Manuel satış sadeleştirme
- [x] İlk basamak açık gelecek şekilde başlangıç korundu.
- [x] Sabit satış tutarı alanı sadeleştirildi.
- [x] İşletmeye özel fiyat / indirim alanı kaldırıldı.
- [x] Kısmi alınanı tam sayma seçeneği ödeme basamağında bırakıldı.
## 46F - Alacaklar UI
- [x] Bekleyen / k\u0131smi / geciken filtreleri eklendi.
- [x] Tahsilat \u00f6n izleme eklendi.
- [x] Hat\u0131rlatma tasla\u011f\u0131 eklendi.
- [ ] Ger\u00e7ek veri ve bildirim 46K/46H sonras\u0131 ba\u011flanacak.
## 46G - Gider UI
- [x] Gider kategorileri eklendi.
- [x] Gider tutar / tarih / tedarik\u00e7i / not alanlar\u0131 eklendi.
- [x] \u00d6deme y\u00f6ntemi ve \u00f6dendi/bekliyor durumu eklendi.
- [x] Son giderler demo listesi eklendi.
- [ ] Ger\u00e7ek gider kayd\u0131 46K veri katman\u0131ndan sonra ba\u011flanacak.
## 46H - Tekrarlayan gider ve d\u00fczenleme UI
- [x] Tekrarlayan gider switch'i eklendi.
- [x] Haftal\u0131k / ayl\u0131k / 3 ayl\u0131k / y\u0131ll\u0131k periyot se\u00e7imi eklendi.
- [x] Sonraki tekrar tarihi alan\u0131 eklendi.
- [x] Gider kartlar\u0131na tekrar etiketi eklendi.
- [x] D\u00fczenleme tasla\u011f\u0131 bottom sheet'i eklendi.
- [ ] Ger\u00e7ek otomatik tekrar 46K/Cloud Function sonras\u0131 ba\u011flanacak.
## 46I REV1 - Takvim ve taksit UI
- [x] Vadeli satış tarihi takvim seçiciye bağlandı.
- [x] Tekrarlayan gider sonraki tarih alanı takvim seçiciye bağlandı.
- [x] Gider tarihi takvim seçiciye bağlandı.
- [x] Taksitli satış switch'i eklendi.
- [x] Taksit sayısı ve ödeme periyodu alanı eklendi.
- [ ] Gerçek taksit planı 46K veri katmanından sonra kaydedilecek.
## 46J - Rapor / Export UI
- [x] Günlük / haftalık / aylık / yıllık / özel dönem filtresi eklendi.
- [x] Gelir-gider, alacak, gider, personel ve hizmet/ürün rapor tipi eklendi.
- [x] Ciro / tahsilat / bekleyen / geciken / gider / net metrikleri eklendi.
- [x] PDF ve Excel/CSV export ön izleme eklendi.
- [x] Hizmet, ürün, kapora, tekrarlayan gider ve manuel gider kırılımı eklendi.
- [ ] Gerçek PDF/Excel üretimi 46L aşamasında bağlanacak.
## 46K - Veri kontratı / repository hazırlığı
- [x] Firestore path sabitleri eklendi.
- [x] DTO map dönüşüm katmanı eklendi.
- [x] AccountingRepository arayüzü eklendi.
- [x] DisabledAccountingRepository ile gerçek yazma kapalı tutuldu.
- [x] Muhasebe yetki anahtarları merkezi dosyaya alındı.
- [x] Veri kontratı mimari notu eklendi.
- [ ] Gerçek Firestore repository 46L aşamasında bağlanacak.
- [ ] Firestore security rules 46M aşamasında düzenlenecek.
## 46K - Veri kontratı / repository hazırlığı
- [x] Firestore path sabitleri eklendi.
- [x] DTO map dönüşüm katmanı eklendi.
- [x] AccountingRepository arayüzü eklendi.
- [x] DisabledAccountingRepository ile gerçek yazma kapalı tutuldu.
- [x] Muhasebe yetki anahtarları merkezi dosyaya alındı.
- [x] Veri kontratı mimari notu eklendi.
- [ ] Gerçek Firestore repository 46L aşamasında bağlanacak.
- [ ] Firestore security rules 46M aşamasında düzenlenecek.
## 46L - Doğrulama / taksit / güvenlik kontratı
- [x] Para parse/format helper eklendi.
- [x] Telefon normalize helper eklendi.
- [x] Manuel satış validasyon iskeleti eklendi.
- [x] Gider validasyon iskeleti eklendi.
- [x] Taksit planı hesaplama kontratı eklendi.
- [x] Firestore rules taslağı eklendi.
- [x] Cloud Function kontrat taslağı eklendi.
- [ ] Gerçek callable function kodu sonraki aşamada yazılacak.
## 46M - Callable Function iskeleti
- [x] Flutter callable client dosyası eklendi.
- [x] CallableAccountingRepository taslağı eklendi.
- [x] functions/src/accounting tip dosyası eklendi.
- [x] functions/src/accounting validator dosyası eklendi.
- [x] accountingCreateManualSale taslağı eklendi.
- [x] accountingCollectPayment taslağı eklendi.
- [x] accountingCreateExpense taslağı eklendi.
- [x] functions/src/index.ts export bağlantısı denendi.
- [ ] Deploy edilmedi.
- [ ] UI kaydet butonları hÃ¢lÃ¢ kapalı kalacak.
## 46N - Lokal doğrulama butonları
- [x] Satışlar ekranında kayda uygunluk kontrolü eklendi.
- [x] Giderler ekranında kayda uygunluk kontrolü eklendi.
- [x] Gerçek kaydetme hÃ¢lÃ¢ kapalı tutuldu.
- [x] Validasyon mesajları SnackBar ile gösterilecek.
- [ ] 46O aşamasında Cloud Function bağlantısına hazırlık kontrolü yapılacak.
## 46O - Deploy öncesi hazırlık kontrolü
- [x] Deploy readiness notu eklendi.
- [x] Firestore rules snippet taslağı eklendi.
- [x] Muhasebe data/function dosyaları envanteri alındı.
- [x] Functions npm build diagnostik logu alındı, deploy yapılmadı.
- [x] Flutter build alınacak.
- [ ] Functions build hatası varsa 46P aşamasında düzeltilecek.
- [ ] Gerçek rules entegrasyonu 46Q aşamasında yapılacak.
## 46P - Muhasebe yetki UI
- [x] Yetkiler sekmesi eklendi.
- [x] financeRead / financeWrite / expenseWrite / receivableManage / reportExport açıklamaları UI'a eklendi.
- [x] Owner ve personel yetki bağlantı planı eklendi.
- [ ] Gerçek personel yetki düzenleme mevcut personel sistemi analizinden sonra bağlanacak.
## 46Q - Muhasebe personel yetki köprüsü
- [x] Eski/yeni yetki anahtarları için bridge helper eklendi.
- [x] Owner / Kasa / Muhasebe / Sadece görüntüleme presetleri eklendi.
- [x] Yetkiler sekmesine preset gösterimi eklendi.
- [x] Yetki köprüsü mimari dokümanı eklendi.
- [ ] Mevcut personel düzenleme ekranına bağlama 46R aşamasında yapılacak.
## 46S REV1 - Personel formu muhasebe yetkileri
- [x] Önceki hedef blok bulunamadı hatası giderildi.
- [x] StaffFormPageState class bloğu güvenli şekilde yenilendi.
- [x] Kasa / Muhasebe / Sadece gör / Temizle presetleri eklendi.
- [x] financeRead / financeWrite / expenseWrite / receivableManage / reportExport switchleri eklendi.
- [x] permissions map ve eski flat field köprüleri eklendi.
## 46U - Staff session permission sync
- [x] 46T analizine göre AppSession users/{uid}.permissions okuduğu doğrulandı.
- [x] Personel paneli açılırken users/{uid} corporateStaff session cache merge eklendi.
- [x] businessStaff permissions -> users permissions normalizasyonu eklendi.
- [x] functions accounting permission lookup kök businessStaff koleksiyonuna göre düzeltildi.
- [ ] Firebase deploy yapılmadı.
- [ ] Muhasebe kayıt butonları hÃ¢lÃ¢ kapalı.
## 46V - Yetki oturum görünümü
- [x] Yetkiler sekmesine users/{uid}.permissions canlı okuma kartı eklendi.
- [x] Aktif rol / activeBusinessId / staffBusinessId bilgisi gösterildi.
- [x] Aktif muhasebe yetki chipleri gösterildi.
- [x] Firestore yazma yapılmadı.
- [x] Muhasebe kaydetme hÃ¢lÃ¢ kapalı.
## 46W REV1 - Türkçe karakter ve personel UI düzeltmesi
- [x] Raporlar ekranı unicode escape ile yeniden yazıldı.
- [x] Yetkiler ekranı unicode escape ile yeniden yazıldı.
- [x] Satışlar ekranı unicode escape ile yeniden yazıldı.
- [x] Personel formu unicode escape ile güvenli yazıldı.
- [x] Personel formundaki preset butonları kaldırıldı.
- [x] Personel yetkileri tek tip SwitchListTile yapısına alındı.
- [x] Muhasebe kaydetme hÃ¢lÃ¢ kapalı.
## 46W REV2 - Global Turkish mojibake cleanup
- [x] lib klasorunde yaygin UTF-8 mojibake dizileri tarandi.
- [x] Bulunan diziler Turkce unicode karakterlere cevrildi.
- [x] Bildirim/Muhasebe/Personel dahil kaynak dosya genelinde rapor alindi.
- [x] Kalan supheli satirlar after_suspicious_report.txt dosyasina yazildi.
## 46Y - Personel yetkileri tek kart + randevu yetki analizi
- [x] Personel formunda Genel/Muhasebe ayrımı kaldırıldı.
- [x] Tüm yetkiler tek Yetkiler kartına alındı.
- [x] Masraf girebilir ve Gider işlemleri çift switch görünümü kaldırıldı.
- [x] Gider / masraf işlemleri tek switch olarak expenseWrite + canManageExpenses alanlarına yazılır.
- [x] Randevu yönetimi açıklaması netleştirildi.
- [x] Randevu yetkisi appointmentManage / appointmentReschedule / appointmentCancel alanlarına da yazılır.
- [x] Randevu erteleme/iptal/tamamlandı aksiyonları için enforcement analiz raporu çıkarıldı.
- [ ] 46Z aşamasında randevu aksiyon butonları yetkiye göre kapatılacak/gizlenecek.
## 46Y - Personel yetkileri tek kart + randevu yetki analizi
- [x] Personel formunda Genel/Muhasebe ayrımı kaldırıldı.
- [x] Tüm yetkiler tek Yetkiler kartına alındı.
- [x] Masraf girebilir ve Gider işlemleri çift switch görünümü kaldırıldı.
- [x] Gider / masraf işlemleri tek switch olarak expenseWrite + canManageExpenses alanlarına yazılır.
- [x] Randevu yönetimi açıklaması netleştirildi.
- [x] Randevu yetkisi appointmentManage / appointmentReschedule / appointmentCancel alanlarına da yazılır.
- [x] Randevu erteleme/iptal/tamamlandı aksiyonları için enforcement analiz raporu çıkarıldı.
- [ ] 46Z aşamasında randevu aksiyon butonları yetkiye göre kapatılacak/gizlenecek.
## 46Z - Kurumsal hesapta randevu alma kapalı
- [x] BusinessProfilePage aktif users/{uid} oturum tipini okur.
- [x] Kurumsal/işletme/personel hesapta Randevu sekmesi gizlenir.
- [x] Kurumsal hesapta bilgi kartı gösterilir.
- [x] _createAppointment içine güvenlik guard eklendi.
- [x] Bireysel kullanıcı randevu akışı korunur.
## 47A REV1 - Görevlerim / iş akışı yetki ayrımı
- [x] Eski 47A'daki başlat/bitir kısıtlama yaklaşımı terk edildi.
- [x] Personelin atanmış randevuyu başlatıp bitirmesi ayrı yetki oldu.
- [x] Randevu erteleme/iptal ayrı özel yetki oldu.
- [x] Personel formunda Görevlerim / iş başlat-bitir switch'i eklendi.
- [x] Personel formunda Randevu erteleme / iptal yönetimi switch'i eklendi.
- [x] StaffWorkspace metinleri Görevlerim mantığına yaklaştırıldı.
- [x] Muhasebe bağlantı mimari notu eklendi.
- [ ] İşlemi Bitirdim -> muhasebe gelir/tahsilat taslağı 47B/47C sonrasında bağlanacak.
## 47B - Görevlerim giriş sayfası
- [x] StaffTasksEntryPage eklendi.
- [x] businessStaff kayıtlarını currentUser üzerinden bulur.
- [x] Görev seçilince StaffWorkspacePage açar.
- [x] users/{uid}.permissions görev yetkileriyle senkronize edilir.
- [x] Hesabım/Kurumsal panel bağlantısı için navigation candidate raporu alındı.
- [ ] 47B REV1: Görevlerim kartı gerçek Hesabım/Kurumsal ekrana bağlanacak.
## 47B REV1 - Görevlerim görünür giriş bağlantısı
- [x] Kurumsal Yönetim Merkezi AppBar içine Görevlerim butonu eklendi.
- [x] Kurumsal Yönetim Merkezi üst bölümüne Görevlerim kartı eklendi.
- [x] Kart StaffTasksEntryPage sayfasını açar.
- [x] Görevlerim artık kullanıcı yolunda görünür hale geldi.
## 47C - TÃ¼rkÃ§e karakter tekrar taramasÄ±
- [x] Yeni eklenen dosyalar dahil lib klasÃ¶rÃ¼ tekrar tarandÄ±.
- [x] Mojibake karakterleri TÃ¼rkÃ§e karakterlere Ã§evrildi.
- [x] DeÄŸiÅŸen dosyalar ve kalan ÅŸÃ¼pheli satÄ±rlar raporlandÄ±.
- [x] Build alÄ±ndÄ±.
## 47B REV2 - GÃ¶revlerim herkese aÃ§Ä±k
- [x] GÃ¶revlerim sayfasÄ± gÃ¶rev olmasa da aÃ§Ä±klama gÃ¶sterir.
- [x] GÃ¶revi olmayan kullanÄ±cÄ±ya neden boÅŸ olduÄŸu anlatÄ±lÄ±r.
- [x] Kurumsal YÃ¶netim Merkezi GÃ¶revlerim kartÄ± herkes iÃ§in gÃ¶rÃ¼nÃ¼r kalacak ÅŸekilde gÃ¼Ã§lendirildi.
- [x] AtanmÄ±ÅŸ randevular varsa StaffWorkspace akÄ±ÅŸÄ± aÃ§Ä±lÄ±r.
- [ ] 47C/47D: GÃ¶revlerim kartÄ± HesabÄ±m ana ekranÄ±na da baÄŸlanacaksa account_entry_page analiz edilecek.
