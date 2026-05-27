# Fix / RxPro Firestore Data Dictionary V1

Bu dokÃ¼man 50A Firestore Data Dictionary Audit sonrasÄ±nda oluÅŸturulan ilk veri sÃ¶zlÃ¼ÄŸÃ¼dÃ¼r.

AmaÃ§:
- Firestore alanlarÄ±nÄ±n anlamÄ±nÄ± netleÅŸtirmek
- Yeni kod yazÄ±mlarÄ±nda standart alan kullanÄ±mÄ±nÄ± saÄŸlamak
- Legacy/fallback alanlarÄ± hemen silmeden migration planÄ±nÄ± yÃ¶netmek
- Randevu, personel, bildirim, rol ve iÅŸletme baÄŸlamÄ±nÄ± tek veri diliyle ilerletmek

> Not: Bu dokÃ¼man davranÄ±ÅŸ deÄŸiÅŸtirmez. Ä°lk aÅŸamada standartlarÄ± tanÄ±mlar. Legacy alanlar hemen silinmez.

---

## 1. Genel Veri Ä°lkeleri

Her kritik dokÃ¼manda mÃ¼mkÃ¼n olduÄŸunca ÅŸu alanlar kullanÄ±lmalÄ±dÄ±r:

| Alan | Tip | Durum | AÃ§Ä±klama |
|---|---|---|---|
| `createdAt` | Timestamp | Standart | DokÃ¼manÄ±n oluÅŸturulma zamanÄ± |
| `updatedAt` | Timestamp | Standart | Son gÃ¼ncelleme zamanÄ± |
| `createdBy` | string uid | Ã–nerilir | OluÅŸturan kullanÄ±cÄ± |
| `updatedBy` | string uid | Ã–nerilir | Son gÃ¼ncelleyen kullanÄ±cÄ± |
| `schemaVersion` | string | Ã–nerilir | Koleksiyonun genel ÅŸema sÃ¼rÃ¼mÃ¼ |
| `sourceModule` | string | Ã–nerilir | KaydÄ± oluÅŸturan modÃ¼l adÄ± |
| `businessId` | string | Kritik | Kurumsal baÄŸlamÄ± olan tÃ¼m kayÄ±tlarda iÅŸletme kimliÄŸi |

---

## 2. users/{uid}

### Standart rol alanlarÄ±

| Alan | Tip | Durum | AÃ§Ä±klama |
|---|---|---|---|
| `accountKind` | string | Standart | `individual`, `corporate`, `staff`, `guest` gibi ana hesap tÃ¼rÃ¼ |
| `activeRole` | string | Standart | Aktif rol: `individual`, `corporateOwner`, `corporateStaff`, `guest` |
| `roleSchemaVersion` | string | Standart | Rol yazÄ±m standardÄ± sÃ¼rÃ¼mÃ¼; Ã¶rn. `49D-C` |
| `roleUpdatedAt` | Timestamp | Standart | Rol alanÄ± son gÃ¼ncelleme zamanÄ± |

### Legacy uyumluluk alanlarÄ±

| Alan | Tip | Durum | AÃ§Ä±klama |
|---|---|---|---|
| `role` | string | Legacy/Fallback | Eski ekranlar iÃ§in geÃ§ici uyumluluk alanÄ± |
| `legacyRole` | string | Legacy/Fallback | Eski role deÄŸerinin korunmasÄ± |
| `userType` | string | Legacy/Fallback | Eski kullanÄ±cÄ± tÃ¼rÃ¼ alanÄ± |
| `accountType` | string | Legacy/Fallback | Eski hesap tÃ¼rÃ¼ alanÄ± |
| `isBusiness` | bool | Legacy/Fallback | Eski kurumsal hesap iÅŸareti |
| `businessAccount` | bool | Legacy/Fallback | Eski kurumsal hesap iÅŸareti |
| `isBusinessOwner` | bool | Legacy/Fallback | Eski owner iÅŸareti |

### Business context alanlarÄ±

| Alan | Tip | Durum | AÃ§Ä±klama |
|---|---|---|---|
| `activeBusinessId` | string | Standart | KullanÄ±cÄ±nÄ±n aktif kurumsal baÄŸlamÄ± |
| `ownedBusinessId` | string | Standart/Owner | Owner kullanÄ±cÄ±nÄ±n ana iÅŸletmesi |
| `linkedBusinessId` | string | Standart/Staff | BaÄŸlÄ± personelin iÅŸletmesi |
| `businessStaffId` | string | Standart/Staff | businessStaff dokÃ¼man kimliÄŸi |
| `staffUid` | string | Standart/Staff | Firebase user uid |
| `linkedUid` | string | Standart/Staff | businessStaff Ã¼zerinde baÄŸlÄ± uid |
| `staffLinkStatus` | string | Standart/Staff | `linked`, `pending`, `inactive` vb. |
| `staffWorkStatus` | string | Standart/Staff | `active`, `inactive`, `paused` vb. |

### KullanÄ±m kuralÄ±

Yeni rol kararlarÄ± ÅŸu sÄ±rayla yorumlanmalÄ±dÄ±r:

```text
SessionRolePolicy.resolveCanonicalRole(userData)
```

UI veya feature dosyalarÄ± doÄŸrudan string matching ile rol kararÄ± vermemelidir.

---

## 3. businesses/{businessId}

| Alan | Tip | Durum | AÃ§Ä±klama |
|---|---|---|---|
| `ownerUid` | string uid | Kritik | Ä°ÅŸletme sahibinin Firebase uid deÄŸeri |
| `businessName` | string | Kritik | Ä°ÅŸletme adÄ± |
| `category` | string | Standart | Merkezi kategori alanÄ± |
| `address` | string | Standart | Adres |
| `city` | string | Standart | Ä°l |
| `district` | string | Standart | Ä°lÃ§e |
| `location` | GeoPoint/map | Ã–nerilir | Konum bazlÄ± keÅŸif iÃ§in |
| `createdAt` | Timestamp | Standart | OluÅŸturma zamanÄ± |
| `updatedAt` | Timestamp | Standart | GÃ¼ncelleme zamanÄ± |

### Legacy koleksiyonlar

AÅŸaÄŸÄ±daki koleksiyonlar fallback olarak gÃ¶rÃ¼lebilir:

| Koleksiyon | Durum | Not |
|---|---|---|
| `registeredBusinesses` | Legacy/Fallback | Eski kayÄ±tlÄ± iÅŸletme akÄ±ÅŸlarÄ±ndan kalabilir |
| `businessProfiles` | Legacy/Fallback | Eski profil akÄ±ÅŸlarÄ±ndan kalabilir |

Yeni geliÅŸtirmede ana kaynak tercihen `businesses/{businessId}` olmalÄ±dÄ±r.

---

## 4. businessStaff/{businessStaffId}

| Alan | Tip | Durum | AÃ§Ä±klama |
|---|---|---|---|
| `businessId` | string | Kritik | Personelin baÄŸlÄ± olduÄŸu iÅŸletme |
| `businessStaffId` | string | Standart | DokÃ¼man kimliÄŸiyle aynÄ± kullanÄ±labilir |
| `staffName` | string | GÃ¶rsel | Personel adÄ± |
| `staffEmail` | string | DoÄŸrulama | Davet ve eÅŸleÅŸme iÃ§in e-posta |
| `targetEmail` | string | Legacy/Fallback | Eski davet hedef e-postasÄ± |
| `linkedUid` | string uid | Kritik | Daveti kabul eden kullanÄ±cÄ±nÄ±n uid deÄŸeri |
| `staffUid` | string uid | Standart | Personel Firebase uid |
| `linkedAt` | Timestamp | Standart | BaÄŸlantÄ± zamanÄ± |
| `staffLinkStatus` | string | Standart | `linked`, `pending`, `inactive` |
| `staffWorkStatus` | string | Standart | `active`, `inactive`, `paused` |
| `serviceIds` | list<string> | Kritik | Personelin verebildiÄŸi hizmetler |
| `permissions` | map/list | Ã–nerilir | Yetki matrisi altyapÄ±sÄ± |
| `isActive` | bool | Legacy/GeÃ§iÅŸ | Yeni kullanÄ±mda `staffWorkStatus` tercih edilmeli |

### KullanÄ±m kuralÄ±

Randevu atamalarÄ±nda isim deÄŸil, ÅŸu alanlar temel alÄ±nmalÄ±dÄ±r:

```text
businessStaffId + serviceId
```

`staffName` sadece gÃ¶rÃ¼ntÃ¼leme amacÄ±yla kullanÄ±lmalÄ±dÄ±r.

---

## 5. services/{serviceId}

| Alan | Tip | Durum | AÃ§Ä±klama |
|---|---|---|---|
| `businessId` | string | Kritik | Hizmetin iÅŸletmesi |
| `serviceId` | string | Kritik | Hizmet kimliÄŸi |
| `serviceName` | string | Kritik | Hizmet adÄ± |
| `durationMinutes` | number | Ã–nerilir | Randevu sÃ¼resi |
| `price` | number | Opsiyonel | Hizmet fiyatÄ± |
| `isActive` | bool | Standart | Aktif/pasif hizmet |
| `createdAt` | Timestamp | Standart | OluÅŸturma zamanÄ± |
| `updatedAt` | Timestamp | Standart | GÃ¼ncelleme zamanÄ± |

---

## 6. appointments/{appointmentId}

| Alan | Tip | Durum | AÃ§Ä±klama |
|---|---|---|---|
| `businessId` | string | Kritik | Ä°ÅŸletme kimliÄŸi |
| `userId` / `customerUid` | string uid | Kritik | Randevuyu alan bireysel kullanÄ±cÄ± |
| `serviceId` | string | Kritik | Hizmet kimliÄŸi |
| `serviceName` | string | GÃ¶rsel | Hizmet adÄ± |
| `businessStaffId` | string | Kritik | Atanan personel dokÃ¼manÄ± |
| `staffUid` | string uid | Standart | Atanan personelin user uid deÄŸeri |
| `assignedStaffUid` | string uid | Legacy/Fallback | Eski atama alanÄ± |
| `appointmentStatus` | string | Kritik | `pending`, `confirmed`, `started`, `completed`, `cancelled`, `noShow` |
| `paymentStatus` | string | Ã–nerilir | `unpaid`, `paid`, `partial`, `refunded` |
| `startedAt` | Timestamp | Operasyon | Ä°ÅŸe baÅŸlama zamanÄ± |
| `completedAt` | Timestamp | Operasyon | Ä°ÅŸ bitiÅŸ zamanÄ± |
| `cancelledAt` | Timestamp | Operasyon | Ä°ptal zamanÄ± |
| `createdAt` | Timestamp | Standart | OluÅŸturma zamanÄ± |
| `updatedAt` | Timestamp | Standart | GÃ¼ncelleme zamanÄ± |
| `serviceStaffRelationVersion` | string | Standart | Personel-hizmet iliÅŸki sÃ¼rÃ¼mÃ¼; Ã¶rn. `49B-C` |
| `appointmentSchemaVersion` | string | Ã–nerilir | Randevu ÅŸema sÃ¼rÃ¼mÃ¼ |

### KullanÄ±m kuralÄ±

Yeni randevu oluÅŸturma akÄ±ÅŸÄ±:

```text
AppointmentBookingService
â†’ ServiceStaffCompatibilityPolicy
â†’ AppointmentRepository / FirestoreAppointmentRepository
```

UI doÄŸrudan randevu iÅŸ kuralÄ± uygulamamalÄ±dÄ±r.

---

## 7. notifications/{notificationId}

| Alan | Tip | Durum | AÃ§Ä±klama |
|---|---|---|---|
| `targetScope` | string | Kritik | `user`, `business`, `staff` |
| `recipientUid` | string uid | Kritik/User | KullanÄ±cÄ± hedefli bildirim |
| `targetUserId` | string uid | Legacy/Fallback | Eski kullanÄ±cÄ± hedef alanÄ± |
| `businessId` | string | Kritik/Business | Ä°ÅŸletme baÄŸlamÄ± |
| `targetBusinessId` | string | Legacy/Fallback | Eski iÅŸletme hedef alanÄ± |
| `type` | string | Standart | Bildirim tipi |
| `notificationType` | string | Legacy/Fallback | Eski tip alanÄ± |
| `payload` | map | Ã–nerilir | Deep link/ek veri |
| `read` | bool | Standart | Okundu bilgisi |
| `isRead` | bool | Legacy/Fallback | Eski okundu alanÄ± |
| `createdAt` | Timestamp | Standart | OluÅŸturma zamanÄ± |

### KullanÄ±m kuralÄ±

Bildirim gÃ¶rÃ¼nÃ¼rlÃ¼k kararÄ± merkezi role policy ile uyumlu olmalÄ±dÄ±r:

```text
SessionRolePolicy.resolveCanonicalRole(userData)
```

FCM token ve Cloud Functions gÃ¶nderim Ã§ekirdeÄŸi ayrÄ± korunmalÄ±dÄ±r.

---

## 8. favorites / follows

| Alan | Tip | Durum | AÃ§Ä±klama |
|---|---|---|---|
| `userId` | string uid | Kritik | Favoriye alan kullanÄ±cÄ± |
| `businessId` | string | Kritik | Favori/takip edilen iÅŸletme |
| `createdAt` | Timestamp | Standart | Takip/favori zamanÄ± |
| `sourceModule` | string | Ã–nerilir | KeÅŸfet, profil, kampanya vb. |

### Gelecek standart

Favori ve takip ayrÄ±mÄ± netleÅŸtirilmelidir:

```text
favorites = kullanÄ±cÄ±nÄ±n kaydettiÄŸi iÅŸletmeler
follows   = story/kampanya akÄ±ÅŸÄ± iÃ§in takip iliÅŸkisi
```

---

## 9. campaigns/{campaignId}

| Alan | Tip | Durum | AÃ§Ä±klama |
|---|---|---|---|
| `businessId` | string | Kritik | KampanyayÄ± oluÅŸturan iÅŸletme |
| `title` | string | Kritik | Kampanya baÅŸlÄ±ÄŸÄ± |
| `description` | string | Standart | Kampanya aÃ§Ä±klamasÄ± |
| `validFrom` | Timestamp | Ã–nerilir | BaÅŸlangÄ±Ã§ |
| `validUntil` | Timestamp | Ã–nerilir | BitiÅŸ |
| `targetScope` | string | Ã–nerilir | `nearby`, `favorites`, `all`, `segment` |
| `createdAt` | Timestamp | Standart | OluÅŸturma zamanÄ± |
| `createdBy` | string uid | Ã–nerilir | OluÅŸturan kullanÄ±cÄ± |

---

## 10. messages / chats

| Alan | Tip | Durum | AÃ§Ä±klama |
|---|---|---|---|
| `businessId` | string | Kritik | Ä°ÅŸletme baÄŸlamÄ± |
| `participantUids` | list<string> | Kritik | KonuÅŸma katÄ±lÄ±mcÄ±larÄ± |
| `lastMessageAt` | Timestamp | Standart | Son mesaj zamanÄ± |
| `createdAt` | Timestamp | Standart | OluÅŸturma zamanÄ± |
| `readBy` | map/list | Ã–nerilir | Okundu bilgisi |
| `sourceModule` | string | Ã–nerilir | Profil, randevu, kampanya vb. |

---

## 11. Legacy Cleanup Prensibi

Legacy alanlar hemen silinmeyecek. Temizlik sÄ±rasÄ±:

```text
1. Yeni yazÄ±mlar standart alanlarÄ± Ã¼retir.
2. Eski alanlar fallback olarak okunur.
3. Audit ile aktif kullanÄ±m Ã¶lÃ§Ã¼lÃ¼r.
4. Migration script ile eski dokÃ¼manlar dÃ¶nÃ¼ÅŸtÃ¼rÃ¼lÃ¼r.
5. Fallback dallarÄ± deprecated yapÄ±lÄ±r.
6. En son silinir.
```

---

## 12. Ä°lk Teknik Standartlar

Yeni kodda tercih edilmesi gereken karar merkezleri:

| Alan | DoÄŸru kaynak |
|---|---|
| Rol kararÄ± | `SessionRolePolicy.resolveCanonicalRole(data)` |
| Hesap modu | `AccountModeResolver.fromUserData(data)` |
| Oturum | `AppSessionController / AppSession` |
| Randevu oluÅŸturma | `AppointmentBookingService` |
| Personel-hizmet uyumu | `ServiceStaffCompatibilityPolicy` |
| Bildirim gÃ¶rÃ¼nÃ¼rlÃ¼ÄŸÃ¼ | `NotificationCenterPage` + merkezi role policy |
| Legacy business resolver | `BusinessRoleResolver` adapter olarak geÃ§ici |

---

## 13. Bir Sonraki Hedef

Ã–nerilen sÄ±radaki teknik iÅŸler:

1. Kritik koleksiyonlar iÃ§in constants/helper dosyalarÄ± tasarlanacak.
2. Firestore write iÅŸlemlerinde `schemaVersion`, `createdAt`, `updatedAt`, `sourceModule` standardÄ± kademeli eklenecek.
3. Legacy alanlar iÃ§in migration raporu hazÄ±rlanacak.
4. Yeni Ã¶zellikler bu sÃ¶zlÃ¼ÄŸe gÃ¶re geliÅŸtirilecek.