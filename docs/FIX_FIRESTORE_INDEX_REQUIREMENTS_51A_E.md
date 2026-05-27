# FIX Firestore Index Requirements - 51A-E

Bu dokuman davranis degistirmez. infra/rules/firestore.indexes.json dosyasini degistirmez ve deploy yapmaz.
Amac, 51A-D access matrix sonrasi Firestore query/index ihtiyaclarini toplu ve kontrollu sekilde planlamaktir.

## 1. Mevcut index dosyasi durumu

Aktif index dosyasi: infra/rules/firestore.indexes.json
Bu dosya bu asamada degistirilmez. Mevcut indexler silinmemelidir.

## 2. Index tasarim prensibi

- Sadece gercek sorgularin gerektirdigi composite indexler eklenmelidir.
- Gereksiz index deployment suresini ve bakim maliyetini artirir.
- where + orderBy kombinasyonlari onceliklidir.
- whereIn, arrayContains ve arrayContainsAny sorgulari ayrica izlenmelidir.
- Production index patch mevcut JSON ile merge edilerek yapilmalidir.

## 3. Oncelikli index adaylari

### 3.1 notifications

| Koleksiyon | Alanlar | Amac | Oncelik |
|---|---|---|---:|
| notifications | targetScope ASC, recipientUid ASC, createdAt DESC | user scope bildirim listesi | Yuksek |
| notifications | targetScope ASC, businessId ASC, createdAt DESC | business scope bildirim listesi | Yuksek |
| notifications | targetScope ASC, recipientUid ASC, isRead ASC, createdAt DESC | kullanici okunmamis bildirimleri | Orta |
| notifications | targetScope ASC, businessId ASC, isRead ASC, createdAt DESC | isletme okunmamis bildirimleri | Orta |

### 3.2 appointments

| Koleksiyon | Alanlar | Amac | Oncelik |
|---|---|---|---:|
| appointments | businessId ASC, dateText ASC, timeText ASC | isletme gunluk randevu sirasi | Yuksek |
| appointments | businessId ASC, businessStaffId ASC, dateText ASC, timeText ASC | personel bazli is kuyrugu | Yuksek |
| appointments | businessId ASC, businessStaffId ASC, appointmentStatus ASC, dateText ASC | personel status filtreli is kuyrugu | Orta |
| appointments | customerUid ASC, dateText DESC | bireysel kullanici randevu gecmisi | Orta |
| appointments | businessId ASC, serviceId ASC, dateText DESC | hizmet bazli rapor | Dusuk-Orta |

### 3.3 messageThreads / messages

| Koleksiyon | Alanlar | Amac | Oncelik |
|---|---|---|---:|
| messageThreads | businessId ASC, lastMessageAt DESC | isletme inbox | Yuksek |
| messageThreads | customerUid ASC, lastMessageAt DESC | bireysel inbox | Yuksek |
| messageThreads | businessId ASC, unreadForBusiness ASC, lastMessageAt DESC | isletme okunmamis badge/list | Orta |
| messageThreads | customerUid ASC, unreadForCustomer ASC, lastMessageAt DESC | bireysel okunmamis badge/list | Orta |
| messageThreads/{threadId}/messages | createdAt ASC | mesaj akisi | Orta |

### 3.4 businessStaff

| Koleksiyon | Alanlar | Amac | Oncelik |
|---|---|---|---:|
| businessStaff | businessId ASC, staffEmailLower ASC | davet/e-posta eslestirme | Yuksek |
| businessStaff | linkedUid ASC, businessId ASC | linked staff baglantisini bulma | Yuksek |
| businessStaff | businessId ASC, staffLinkStatus ASC | owner personel baglanti durumu | Orta |
| businessStaff | businessId ASC, staffWorkStatus ASC | owner aktif/pasif calisma durumu | Orta |

### 3.5 businessServices

| Koleksiyon | Alanlar | Amac | Oncelik |
|---|---|---|---:|
| businessServices | businessId ASC, isActive ASC | aktif hizmet listesi | Yuksek |
| businessServices | businessId ASC, bookingEnabled ASC | randevu alinabilir hizmet listesi | Orta |
| businessServices | businessId ASC, isActive ASC, bookingEnabled ASC | aktif + booking hizmet filtreleme | Orta |

### 3.6 businessExpenses / finance

| Koleksiyon | Alanlar | Amac | Oncelik |
|---|---|---|---:|
| businessExpenses | businessId ASC, expenseDate DESC | masraf listesi | Orta |
| businessExpenses | businessId ASC, category ASC, expenseDate DESC | kategori bazli masraf | Dusuk-Orta |
| financeRecords veya businessFinanceRecords | businessId ASC, recordDate DESC | finans kayit listesi | Orta |
| financeRecords veya businessFinanceRecords | businessId ASC, recordType ASC, recordDate DESC | gelir/gider raporu | Dusuk-Orta |

### 3.7 businessProfilePosts / story / campaign

| Koleksiyon | Alanlar | Amac | Oncelik |
|---|---|---|---:|
| businessProfilePosts | businessId ASC, isActive ASC, createdAt DESC | profil post akisi | Orta |
| businessStories | businessId ASC, isActive ASC, createdAt DESC | story akisi | Dusuk-Orta |
| businessCampaigns | businessId ASC, isActive ASC, createdAt DESC | kampanya listesi | Orta |
| businessCampaigns | targetScope ASC, isActive ASC, createdAt DESC | hedefli kampanya listesi | Dusuk-Orta |

## 4. Ilk index patch icin minimum set

Ilk deploy edilebilir minimum set su alanlari hedefleyebilir:

- notifications: targetScope + recipientUid + createdAt
- notifications: targetScope + businessId + createdAt
- appointments: businessId + dateText + timeText
- appointments: businessId + businessStaffId + dateText + timeText
- messageThreads: businessId + lastMessageAt
- messageThreads: customerUid + lastMessageAt

Bu minimum set bile hemen uygulanmadan once mevcut infra/rules/firestore.indexes.json ile merge edilmelidir.

## 5. Uygulama stratejisi

1. Index dokumani tamamlandi.
2. 51A-F icin deploy edilmeyecek firestore.rules.draft veya firestore.indexes.draft.json hazirlanabilir.
3. Production infra/rules/firestore.indexes.json patchi sadece merge mantigiyla yapilmali.
4. Firebase index deploy ayri ve bilincli komutla yapilmali.
5. Uygulama APK buildi index dokumani icin gerekli degildir.

## 6. Test kontrol listesi

- Bildirim merkezi: bireysel ve kurumsal bildirimler.
- Kesfet badge: mesaj/bildirim badge.
- Gorevlerim: personel is kuyrugu.
- Randevu takibi: owner randevu listesi.
- Business profile: hizmet/personel secimi.
- Messages inbox: business/customer thread listesi.
- Finance/masraf: 51B alanina kadar yalniz duman testi.

## 7. Sonuc

51A-E sadece dokumantasyon asamasidir. Bu asamada index deploy edilmez.
Sonraki guvenli adim 51A-F deploy edilmeyecek draft rules/index dosyasi veya 51A-G emulator/staging test plan dokumanidir.
