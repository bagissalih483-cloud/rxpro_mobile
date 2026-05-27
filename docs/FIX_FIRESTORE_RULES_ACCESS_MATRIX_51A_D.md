# FIX Firestore Rules Access Matrix - 51A-D

Bu dokuman davranis degistirmez. Production `firestore.rules` deploy etmez. Amac, 50C constants adoption ve 51A-C risk analizinden sonra Firestore erisim kurallarini guvenli sekilde daraltmak icin hedef matrisi netlestirmektir.

## 1. Genel karar

Mevcut aktif dosyalar:

- `infra/rules/firestore.rules`
- `infra/rules/firestore.indexes.json`
- `infra/rules/storage.rules`

Mevcut `firestore.rules` gelistirme asamasinda genis fallback iceriyor. Bu fallback uygulamanin calismasini kolaylastirir; ancak production icin fazla genistir.

Kritik fallback tipi:

```rules
match /{collection}/{docId} {
  allow read, write: if collection != "notifications" && signedIn();
}
```

51A-D asamasinda bu fallback kaldirilmaz. Sadece hedef erisim matrisi dokumante edilir.

## 2. Temel kimlik ve rol prensibi

Uygulamadaki roller ve scope kararlari artik `SessionRolePolicy` ve constants hattina yaklasti. Rules tarafinda da ayni ayrim hedeflenmelidir.

Ana aktorler:

| Aktor | Aciklama | Rules icin beklenen kimlik |
|---|---|---|
| individual | Bireysel kullanici | `request.auth.uid` |
| corporateOwner | Kurumsal yetkili/isletme sahibi | `businesses/{businessId}.ownerUid/ownerId/businessOwnerUid/userId/uid/createdBy/adminUid/managerUid` veya `users/{uid}.ownedBusinessId/businessId/activeBusinessId` |
| corporateStaff / linkedStaff | Davet koduyla bagli personel | `businessStaff` icinde `linkedUid == request.auth.uid`, `businessId` eslesmesi |
| guest | Misafir | Firestore yazma yok; public okuma varsa sinirli |
| server/function | Cloud Functions / trusted backend | Admin SDK rules bypass eder; istemci rules buna gore tasarlanmali |

## 3. Yardimci rules fonksiyon hedefleri

Mevcut rules dosyasinda benzer fonksiyonlar var. Nihai hedef fonksiyonlar:

```rules
function signedIn() {
  return request.auth != null;
}

function isSelf(uid) {
  return signedIn() && request.auth.uid == uid;
}

function hasBusinessId(data) {
  return data.businessId is string && data.businessId.size() > 0;
}

function isBusinessOwner(businessId) {
  // business doc veya user doc uzerinden owner dogrulama
}

function isLinkedStaffForBusiness(businessId) {
  // businessStaff dokumanlarinda linkedUid == request.auth.uid ve businessId eslesmesi
}

function isBusinessMember(businessId) {
  return isBusinessOwner(businessId) || isLinkedStaffForBusiness(businessId);
}

function isNotificationRecipient() {
  // targetScope == user ise recipientUid == request.auth.uid
  // targetScope == business ise businessId uzerinden owner/staff kontrolu
}

function isMessageParticipant() {
  // thread icinde customerUid/sender/participants uzerinden ilgili kisi veya isletme uyesi
}
```

## 4. Koleksiyon bazli erisim matrisi

### 4.1 `users/{uid}`

| Islem | Hedef kural | Not |
|---|---|---|
| read | `isSelf(uid)` | Owner tarafindan personel profili goruntuleme gerekiyorsa ayri limited rule gerekir |
| create | `isSelf(uid)` | Kullanici kendi profilini olusturabilir |
| update | `isSelf(uid)` ve kritik rol alanlari korumali | `role`, `accountKind`, `activeRole`, `businessAccount`, `isBusinessOwner` gibi alanlar istemciden serbest degismemeli |
| delete | kapali | Hesap silme backend veya kontrollu flow olmali |

Kritik alanlar:

- `role`
- `accountKind`
- `activeRole`
- `legacyRole`
- `businessId`
- `ownedBusinessId`
- `activeBusinessId`
- `linkedStaff`
- `businessStaffId`

### 4.2 `users/{uid}/fcmTokens/{tokenId}`

| Islem | Hedef kural | Not |
|---|---|---|
| read | `isSelf(uid)` | Token gizli kabul edilmeli |
| create/update | `isSelf(uid)` | Token ownership korunmali |
| delete | `isSelf(uid)` | Cikis yaparken token temizleme/deactivate icin gerekli |

Kritik not: 41I bildirim cekirdegi calisiyor; rules sertlestirmesi token yazimini bozmamali.

### 4.3 `businesses/{businessId}`

| Islem | Hedef kural | Not |
|---|---|---|
| read | public/signed-in | Kesfet icin public veya signed-in read gerekebilir |
| create | signed-in ve owner alanlari request.auth.uid ile uyumlu | Sahte owner yazimi engellenmeli |
| update | `isBusinessOwner(businessId)` | Staff sadece belirli alanlari update edebilmeli |
| delete | kapali | Arsiv/pasiflestirme tercih edilmeli |

### 4.4 `businessStaff/{staffId}`

| Islem | Hedef kural | Not |
|---|---|---|
| read | `isBusinessOwner(businessId)` veya `linkedUid == request.auth.uid` | Personel kendi kaydini ve owner ekibi gorebilmeli |
| create | `isBusinessOwner(request.resource.data.businessId)` | Personel ekleme sadece owner |
| update | owner full, linkedStaff limited | Staff sadece `staffWorkStatus`, `activeWorkSession`, `lastSeenAt` gibi alanlari degistirebilmeli |
| delete | kapali veya owner only | Tercihen status ile pasiflestirme |

### 4.5 `businessServices/{serviceId}`

| Islem | Hedef kural | Not |
|---|---|---|
| read | public/signed-in | Profil/randevu icin gerekli |
| create/update | `isBusinessOwner(businessId)` | Hizmet listesi owner kontrolunde |
| delete | owner only veya status pasif | Silme yerine `isActive=false` daha guvenli |

### 4.6 `appointments/{appointmentId}`

| Islem | Hedef kural | Not |
|---|---|---|
| read | ilgili `customerUid`, business owner veya assigned linkedStaff | Personel sadece kendi randevusunu gormeli |
| create | signed-in customer veya owner flow | `businessId`, `serviceId`, `businessStaffId` uyumu servis tarafinda da korunuyor |
| update | owner/assigned staff/ilgili customer limited | Baslat/bitir staff; iptal durumuna gore limited |
| delete | kapali | Audit trail icin delete kapali olmali |

Kritik alanlar:

- `businessId`
- `customerUid`
- `businessStaffId`
- `staffUid`
- `assignedStaffUid`
- `serviceId`
- `appointmentStatus`
- `startedAt`
- `completedAt`
- `cancelledAt`
- `noShow`

### 4.7 `notifications/{notificationId}`

| Islem | Hedef kural | Not |
|---|---|---|
| read | `targetScope=user` ise `recipientUid == request.auth.uid`; `targetScope=business` ise business member | 41I bildirim scope korunmali |
| create | dikkatli: app/server kontrollu | Ileride Cloud Functions tarafina tasinmali |
| update | sadece `isRead/readAt` gibi alanlar recipient tarafindan | Icerik degistirme engellenmeli |
| delete | kapali | Bildirim gecmisi audit icin saklanabilir |

Kritik not: FCM/Cloud Functions/push cekirdegi rules ile kirilmamali.

### 4.8 `messageThreads/{threadId}` ve alt `messages`

| Islem | Hedef kural | Not |
|---|---|---|
| read | thread participant veya business member | `customerUid`, `businessId`, `participants` uzerinden |
| create | participant veya business member | Sahte thread engellenmeli |
| update | unread/status/lastMessage limited | Message mirror davranisi korunmali |
| delete | kapali | Mesaj geri alma soft update ile kalmali |

Kritik alanlar:

- `businessId`
- `customerUid`
- `participants`
- `senderUid`
- `recipientUid`
- `lastMessage`
- `lastMessageAt`
- `unreadForBusiness`
- `unreadForCustomer`

### 4.9 Legacy mirror message koleksiyonlari

Ayrik koleksiyonlar:

- `chatThreads`
- `conversations`
- `businessCustomerMessages`
- `customerMessages`
- `directMessages`
- `userMessages`
- `customerNotifications`

Karar: Bu koleksiyonlar 50C-U3 ile constants'a baglandi, fakat rules tarafinda hemen sertlestirilmemeli. 51 sonrasi `MessagingRepository` veya `MessageThreadService` ile teklesme planlanmali.

### 4.10 `businessExpenses`, `businessActivityLogs`, `businessFinanceRecords`

| Islem | Hedef kural | Not |
|---|---|---|
| read | owner veya finance permission staff | Finans verisi hassas |
| create | owner/staff with permission | Personelin masraf ekleme yetkisi ayrilmali |
| update | owner/finance permission | Muhasebe kaydi audit trail ile korunmali |
| delete | kapali veya owner only | Tercihen iptal/void status |

Bu alanlar mevcut fallback nedeniyle yuksek risk grubundadir. 51B Finance Domain Dictionary hattinda ayrica ele alinmali.

### 4.11 `businessProfilePosts`, story, campaign

| Islem | Hedef kural | Not |
|---|---|---|
| read | public/signed-in | Kesfet/profil icin |
| create/update | business owner veya authorized staff | Kampanya/story yayinlama yetkisi ayrilmali |
| delete | owner veya status pasif | Silme yerine pasife alma tercih edilebilir |

## 5. Storage rules hedef matrisi

| Path | Read | Write | Not |
|---|---|---|---|
| business profile images | public/signed-in | business owner/staff | Her signed-in kullanici her isletmeye yazamamali |
| user profile images | self | self | Kullanici kendi profil gorselini yazmali |
| story/campaign media | public/signed-in | business owner/staff | Storage path businessId icermeli |
| private docs | owner/recipient | owner/recipient | Ileride gerekirse ayrilir |

## 6. Index gereksinim oncelikleri

Aday index gruplari:

1. `notifications`
   - `targetScope + recipientUid + createdAt`
   - `targetScope + businessId + createdAt`
   - `targetScope + recipientUid + isRead + createdAt`

2. `appointments`
   - `businessId + dateText + timeText`
   - `businessId + businessStaffId + appointmentStatus + dateText`
   - `customerUid + appointmentStatus + dateText`

3. `messageThreads`
   - `businessId + lastMessageAt`
   - `customerUid + lastMessageAt`
   - `businessId + unreadForBusiness + lastMessageAt`

4. `businessStaff`
   - `businessId + staffEmailLower`
   - `linkedUid + businessId`

5. `businessServices`
   - `businessId + isActive`
   - `businessId + bookingEnabled`

## 7. Test senaryolari

Rules daraltmadan once test edilmesi gereken minimum senaryolar:

1. Bireysel kullanici
   - Profil okuma/yazma
   - Randevu olusturma
   - Kendi randevularini gorme
   - Kendi mesajlarini gorme/yazma
   - Kendi bildirimlerini okuma

2. Kurumsal owner
   - Isletme profili duzenleme
   - Hizmet/personel yonetimi
   - Tum isletme randevularini gorme
   - Finans/masraf kaydi
   - Business scope bildirimlerini okuma

3. Linked staff
   - Sadece kendi businessStaff kaydi
   - Kendisine atanan randevular
   - Randevu baslat/bitir/iptal/noShow
   - Aktif/pasif kurumsal baglanti
   - Yetkisiz finans alanlarina erisememe

4. Misafir
   - Public kesfet okuma varsa sadece okuma
   - Yazma yok
   - Randevu/mesaj/bildirim yok

5. Hesap degistirme/token
   - Eski hesabin tokeni aktif kalmamali
   - Yeni hesap sadece kendi scope bildirimlerini almali

## 8. 51A-D sonucu

Bu belge, production rules patch degildir. Bir sonraki adim:

- `51A-E`: Firestore Index Requirements dokumani
- `51A-F`: Deploy edilmeyecek rules draft dosyasi
- `51A-G`: Emulator/staging test plan dokumani

Production rules patch ancak bu dokumanlar tamamlandiktan ve test senaryolari netlestikten sonra kademeli uygulanmalidir.
