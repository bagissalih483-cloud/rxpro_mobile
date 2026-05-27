# 46O Muhasebe Deploy Hazırlık Notu

Bu aşama canlı deploy değildir. Ama Cloud Function ve Firestore rules tarafına geçmeden önce kontrol listesi sabitlenir.

## Mevcut durum

- Muhasebe UI iskeleti kuruldu.
- Satışlar, alacaklar, giderler ve raporlar ekranları hazırlandı.
- Lokal validasyon butonları eklendi.
- Firestore path kontratı yazıldı.
- DTO katmanı yazıldı.
- Callable Function taslakları yazıldı.
- Flutter tarafında kaydetme hÃ¢lÃ¢ kapalıdır.

## Deploy öncesi zorunlu kontroller

1. Functions TypeScript compile hatasız olmalı.
2. `functions/src/index.ts` muhasebe callable exportlarını doğru vermeli.
3. `businesses/{businessId}/staff/{uid}` yetki modeli mevcut sistemle uyuşmalı.
4. Owner alanı için hangi field kullanıldığı netleşmeli:
   - ownerUid
   - uid
   - createdByUid
5. Firestore rules içinde accounting koleksiyonları önce read-only test edilmeli.
6. Yazma işlemleri doğrudan client değil callable function üzerinden açılmalı.
7. UI kaydet butonları ancak deploy/test sonrası aktif edilmeli.

## Sonraki güvenli sıra

46P - Functions TypeScript compile düzeltmesi
46Q - Firestore rules taslağını gerçek rules dosyasına kontrollü ekleme
46R - Callable Function deploy
46S - UI kaydet butonlarını test modunda açma
46T - APK test