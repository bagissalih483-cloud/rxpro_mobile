# Kurumsal Navigasyon Revizyon Durumu

Kaynak PDF: `RxPro_Kurumsal_Navigasyon_Yapilacaklar.pdf`

## Karar

Kurumsal alt bar hedef omurgasi:

`Yonetim | Randevu | Muhasebe | Pazarlama | Hesap`

Bu karar onaylandi. Kurumsal hesap artik musteri kesfiyle acilmayacak; isletme yonetimi ilk ekran olacak.

## Uygulanan guvenli ilk paket

- `BusinessMainShell` alt bar sirasi yeni 5'liye alindi.
- Eski `On Izleme` kurumsal alt bardan cikarildi.
- Ilk sekme `BusinessManagementHomePage` ile isletme yonetimi merkezine baglandi.
- `Randevu` sekmesi mevcut `BusinessAppointmentDashboardPage` akisini koruyacak sekilde aynen bagli kaldi.
- `Muhasebe` sekmesi ayri ana sekme olarak korundu.
- `Pazarlama` sekmesi `BusinessMarketingHubPage` ile kampanya, toplu mesaj, AI kampanya, hikaye ve paylasim aksiyonlarini tek merkezde topladi.
- `Hesap` icindeki eski profil on izleme aksiyonu `Musteri gibi gor` adina tasindi.

## Uygulanan tam revizyon paketi

- Yonetim ekrani acilir `Bugun Ozeti`, hizli islemler, isletme duzeni ve operasyon kartlariyla sinirlandi.
- Yonetim kartlari musteri, personel/yetki, hizmet, urun/stok, sure analizi ve hareketler odaginda kalir; muhasebe, randevu ve pazarlama detay ekranlari buraya gomulmez.
- Pazarlama merkezi kampanya, toplu mesaj, AI kampanya, hikaye paylas, paylasim olustur, bos saati doldur ve eski musteriyi cagir aksiyonlarini baglar.
- Hesap sekmesi profil/vitrin, musteri gibi gor/kesfet on izleme, bildirim-guvenlik, yasal metinler, hesap silme ve cikis alanlari icin duzenli kalir.
- Personel yetkileri icin `appointmentsRead`, `appointmentsWrite`, `financeRead`, `financeWrite`, `campaignRead`, `campaignWrite`, `bulkMessage`, `staffManage`, `servicesManage` ve `productsManage` anahtarlari dokumante edildi ve izin alias kontrolu eklendi.
- Randevu tamamlandi akisindan sonra mevcut tamamlandi davranisini bozmayan opsiyonel `Adisyon olustur / Muhasebeye git` onerisi eklendi.
- `FixShellNavState.setCorporateIndex(2)` ile muhasebe sekmesine kontrollu yonlendirme desteklendi.

## Kilit koruma notu

Randevu grid sistemi bu patchte yeniden yazilmadi, gomulmedi ve baska bir widget ile degistirilmedi.
Randevu sekmesinin ana ekrani mevcut `BusinessAppointmentDashboardPage` olarak kalir.

## Build notu

Bu calismada `flutter build`, Gradle assemble, release veya APK uretim komutu calistirilmadi. Final build ve APK dogrulamasini PowerShell ile kullanici alacak.

## Sonraki paketler

- Yonetim ekranindaki bugun ozeti canli metriklerle beslenecek.
- Pazarlama hub icindeki bos saat/eski musteri aksiyonlari gercek segment verisine baglanacak.
- Randevu tamamlandi -> adisyon taslagi daha sonra gercek muhasebe taslak verisiyle genisletilebilir.
