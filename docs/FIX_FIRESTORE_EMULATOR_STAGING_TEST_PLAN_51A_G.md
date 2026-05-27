# FIX Firestore Rules Emulator / Staging Test Plan - 51A-G

Bu dokuman davranis degistirmez. Rules deploy etmez, index deploy etmez, build almaz.
Amac, 51A-F draft rules/index dosyalari production'a yaklasmadan once hangi testlerden gecmeli netlestirmektir.

## 1. 51A-F draft inceleme notu

51A-F draft dosyalari dogru yerde olusturuldu:

- docs/FIX_FIRESTORE_RULES_DRAFT_51A_F_DO_NOT_DEPLOY.rules
- docs/FIX_FIRESTORE_INDEXES_DRAFT_51A_F_DO_NOT_DEPLOY.json

Bu dosyalar production dosyalarini degistirmedi:

- infra/rules/firestore.rules degismedi
- infra/rules/firestore.indexes.json degismedi
- deploy yapilmadi
- build alinmadi

Onemli not: Draft rules dosyasi test edilmeden deploy edilmemelidir. Ozellikle create kurallarinda resource.data yerine request.resource.data kullanilmasi gereken yerler olabilir. Bu belge, bu tur riskleri yakalamak icin test planidir.

## 2. Test ortami karari

En guvenli sira:

1. Local emulator test
2. Staging Firebase project test
3. Kucuk production index deploy
4. Kucuk production rules patch
5. APK duman testi

Production rules dogrudan sertlestirilmeyecek.

## 3. Emulator kurulumu hedefi

Firebase emulator kullanilacaksa hedef servisler:

- Firestore emulator
- Auth emulator
- Storage emulator
- Functions emulator, gerekirse sonraki asamada

Temel komutlar dokuman amaclidir. Dogrudan calistirma zorunlu degildir:

```powershell
firebase emulators:start --only firestore,auth,storage
```

Rules testleri icin daha sonra su tarz bir test klasoru kurulabilir:

```text
test/security/firestore_rules_test.dart
test/security/rules_owner_staff_user_matrix_test.dart
```

## 4. Minimum test aktorleri

| Aktor | Test kimligi | Beklenen rol |
|---|---|---|
| individualUser | bireysel kullanici UID | individual |
| businessOwner | kurumsal owner UID | corporateOwner |
| linkedStaffA | personel A UID | corporateStaff / linkedStaff |
| linkedStaffB | personel B UID | corporateStaff / linkedStaff |
| guest | auth yok | guest |
| unrelatedUser | baska kullanici UID | yetkisiz |

## 5. Test veri seti

Minimum seed data:

| Koleksiyon | Dokuman | Kritik alanlar |
|---|---|---|
| users | individualUser | role/accountKind/activeRole |
| users | businessOwner | businessId/ownedBusinessId/activeBusinessId |
| users | linkedStaffA | activeBusinessId/staffBusinessId/linkedStaff |
| businesses | businessA | ownerUid/businessName |
| businessStaff | staffA | businessId/linkedUid/staffEmail/staffWorkStatus |
| businessStaff | staffB | businessId/linkedUid |
| businessServices | serviceA | businessId/isActive/bookingEnabled |
| appointments | appointmentA | businessId/customerUid/businessStaffId/staffUid/serviceId/status |
| notifications | notifUser | targetScope=user/recipientUid |
| notifications | notifBusiness | targetScope=business/businessId |
| messageThreads | threadA | businessId/customerUid/participants |
| businessExpenses | expenseA | businessId/amount/category |

## 6. Users rules testleri

Beklenenler:

- individualUser kendi users dokumanini okuyabilmeli.
- individualUser kendi users dokumanini olusturabilmeli.
- unrelatedUser baska kullanicinin hassas users dokumanini yazamamali.
- guest users dokumani yazamamali.
- role/accountKind/activeRole gibi kritik rol alanlari ileride restricted update ile korunmali.

Test sonucu kabul kriteri:

- Kendi profil akisi kirilmamali.
- Baska kullanicinin rolunu veya businessId alanini yazma engellenmeli.

## 7. FCM token rules testleri

Beklenenler:

- Kullanici kendi users/{uid}/fcmTokens altina token yazabilmeli.
- Kullanici kendi tokenini update edebilmeli.
- Kullanici kendi tokenini silebilmeli veya pasife alabilmeli.
- Baska kullanicinin tokeni okunamamali/yazilamamali.

Kritik not: 41I bildirim cekirdegi calisiyor. Token yazimi kirilirsa native push ve bildirim badge akisi bozulabilir.

## 8. Business owner rules testleri

Beklenenler:

- businessOwner kendi business dokumanini okuyup guncelleyebilmeli.
- unrelatedUser business dokumanini owner gibi guncelleyememeli.
- guest business yazamamali.
- public kesfet gerekiyorsa business read public kalabilir.

## 9. BusinessStaff / linked staff testleri

Beklenenler:

- businessOwner businessStaff kaydi olusturabilmeli.
- linkedStaffA kendi linked kaydini okuyabilmeli.
- linkedStaffA aktif/pasif state alanlarini guncelleyebilmeli.
- linkedStaffA baska personelin kaydini degistirememeli.
- linkedStaffB staffA randevularini goremeyebilmeli.

Kritik mevcut kilitler:

- 48D-E3-I REV4 aktif/pasif personel akisi bozulmamali.
- Davet kodu tekrar istemeden aktif/pasif gecis korunmali.

## 10. Appointment rules testleri

Beklenenler:

- bireysel kullanici randevu olusturabilmeli.
- owner kendi business randevularini gorebilmeli.
- linkedStaffA sadece kendisine atanan randevulari gorebilmeli.
- linkedStaffA kendi randevusunu baslat/bitir yapabilmeli.
- linkedStaffA staffB randevusunu update edememeli.
- unrelatedUser randevu okuyamamali/yazamamali.

Kritik mevcut kilitler:

- 49B-B REV2 AppointmentBookingService cekirdegi bozulmamali.
- 48F-A/48F-B serviceId + businessStaffId uyumlulugu bozulmamali.
- Cakisma engeli korunmali.

## 11. Notifications rules testleri

Beklenenler:

- targetScope=user ise sadece recipientUid kullanicisi okuyabilmeli.
- targetScope=business ise business owner/staff okuyabilmeli.
- unrelatedUser business notification okuyamamali.
- isRead update sadece yetkili alici tarafindan yapilmali.
- notification content update serbest olmamali.

Kritik mevcut kilit:

- 41I bildirim cekirdegi ve FCM/Cloud Functions trigger davranisi bozulmamali.

## 12. MessageThreads / messages rules testleri

Beklenenler:

- customer kendi threadlerini okuyabilmeli.
- businessOwner kendi business threadlerini okuyabilmeli.
- linkedStaff yetki verilirse ilgili business threadlerini okuyabilmeli.
- unrelatedUser thread okuyamamali.
- customer mesaj yazabilmeli.
- business owner mesaj yazabilmeli.
- unreadForBusiness/unreadForCustomer update akisi bozulmamali.
- mesaj geri alma soft update akisi bozulmamali.

Kritik mevcut kilit:

- 50C-U1/U3 message constants adoption sonrasi inbox ve mirror davranisi korunmali.

## 13. Finance / expense rules testleri

Beklenenler:

- owner businessExpenses okuyup yazabilmeli.
- finance permission olmayan staff yazamamali.
- linkedStaff masraf ekleme yetkisi varsa sadece kendi businessId icin yazabilmeli.
- unrelatedUser finans verisi okuyamamali.

Not: Bu alan 51B Finance Domain Dictionary hattinda ayrica ele alinmali.

## 14. Storage rules testleri

Beklenenler:

- Kullanici kendi profil gorselini yazabilmeli.
- Business owner kendi business gorselini yazabilmeli.
- unrelatedUser baska business gorselini yazamamali.
- story/campaign media businessId path ile ayrilmali.

## 15. Index testleri

Index draft production'a uygulanmadan once su ekranlarda query hatasi var mi izlenmeli:

- Bildirim merkezi
- Kesfet mesaj/bildirim badge
- Gorevlerim
- Randevu takibi
- Business profile hizmet/personel secimi
- Messages inbox
- Finance/masraf duman testi

Firestore console veya terminalde missing index linki gorulurse index dokumanina eklenmeli.

## 16. Production gecis stratejisi

1. Draft rules compile testi.
2. Emulator testleri.
3. Staging Firebase project deploy testi.
4. Android APK staging duman testi.
5. Production index deploy.
6. Production rules daraltma patchleri, tek domain tek patch.

Production'a ilk sertlestirme sirasi:

1. fcmTokens owner-only dogrulama.
2. notifications read/update scope daraltma.
3. businessExpenses / finance signedIn fallback daraltma.
4. messageThreads participant daraltma.
5. appointments customer/owner/staff daraltma.
6. genel fallback kapatma.

## 17. 51A-G sonucu

51A-G sadece test planidir. Sonraki guvenli adim, draft rules dosyasini compile/test edebilecek ayri bir 51A-H audit veya emulator test scaffold hazirlamaktir.
