# 46V Muhasebe Yetki Oturum Görünümü

Bu aşamada canlı muhasebe kaydı açılmadı. Yetkiler sekmesine sadece okuma yapan bir kontrol kartı eklendi.

## Amaç

- `users/{uid}.permissions` alanı gerçekten doluyor mu?
- 46U ile `businessStaff` yetkileri session cache'e taşınıyor mu?
- Aktif personel oturumu hangi businessId ile çalışıyor?
- Muhasebe yetkileri uygulama içinde görünür mü?

## Güvenlik

- Firestore yazma yoktur.
- Cloud Function çağrısı yoktur.
- Muhasebe kaydetme butonları kapalıdır.