# 46U Personel Session Yetki Senkronizasyonu

46T analizine göre AppSessionController `users/{uid}.permissions` alanını okuyor. 46S ile muhasebe yetkileri `businessStaff` belgesine yazıldığı için personel paneli açılırken bu yetkilerin session cache alanına taşınması gerekir.

## Yapılan

- `RegisteredBusinessesPage` içinde personel paneli açılmadan önce `users/{uid}` belgesi merge edilir.
- `accountKind/accountType/role` alanları `corporateStaff` olarak set edilir.
- `businessId/activeBusinessId/selectedBusinessId/staffBusinessId` alanları set edilir.
- `permissions` map içine muhasebe yetkileri normalize edilerek yazılır.
- Cloud Function taslağındaki permission lookup `businesses/{businessId}/staff/{uid}` yerine mevcut kök `businessStaff` koleksiyonuna göre düzeltildi.

## Henüz yapılmayan

- Firebase deploy yapılmadı.
- Muhasebe kaydetme butonları açılmadı.
- APK kurulumu yapılmadı.