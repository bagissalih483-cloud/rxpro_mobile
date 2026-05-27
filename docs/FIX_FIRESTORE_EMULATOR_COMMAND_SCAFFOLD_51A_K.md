# FIX Firestore Emulator Command Scaffold - 51A-K

Bu dokuman davranis degistirmez. Rules deploy etmez, index deploy etmez, build almaz.
Amac, 51A-F/51A-I draft rules dosyalarini production'a dokunmadan emulator/staging uzerinden test etmek icin komut ve dosya planini netlestirmektir.

## 1. Kilit durumu

51A-J statik dogrulama sonucu:

- BRACE_CHECK: OK
- HAS_RULES_VERSION: True
- HAS_DO_NOT_DEPLOY: True
- HAS_DENY_FALLBACK: True
- HAS_WIDE_SIGNEDIN_FALLBACK: False
- HAS_SCOPED_NOTIFICATION_CREATE: True
- HAS_BUSINESS_EXPENSE_CREATE_REQUEST_DATA: True
- HAS_THREAD_PARTICIPANT_FUNCTION: True
- INDEX_JSON_PARSE: OK
- INDEX_COUNT: 6
- RULES_IDENTICAL: False
- INDEX_IDENTICAL: False

Bu sonuÃ§la 51A draft katmani kilitlenebilir. Draft ve production dosyalari ayridir.

## 2. Aktif production dosyalari

Production tarafinda aktif dosyalar:

- infra/rules/firestore.rules
- infra/rules/firestore.indexes.json
- infra/rules/storage.rules

51A draft dosyalari:

- docs/FIX_FIRESTORE_RULES_DRAFT_51A_F_DO_NOT_DEPLOY.rules
- docs/FIX_FIRESTORE_INDEXES_DRAFT_51A_F_DO_NOT_DEPLOY.json

Draft dosyalar production'a kopyalanmayacak ve deploy edilmeyecek.

## 3. Emulator icin guvenli kopya stratejisi

Firebase emulator testinde iki yol var:

### Yol A - Production rules ile emulator

Bu yol mevcut production rules dosyasini kullanir. Uygulamanin mevcut davranisini test eder.

Komut:

```powershell
firebase emulators:start --only firestore,auth,storage
```

### Yol B - Draft rules icin gecici test klasoru

Bu yol draft rules dosyasini production'a dokunmadan gecici bir klasore kopyalar. firebase.json production icin degistirilmez.

Gecici test yapisi:

```text
emulator_rules_lab/
  firebase.json
  firestore.rules
  firestore.indexes.json
  storage.rules
```

Bu klasor sadece local emulator icindir. Production deploy icin kullanilmaz.

## 4. Emulator lab olusturma komut taslagi

AÅŸaÄŸÄ±daki komutlar dokumantasyon amaclidir. Gerektiginde ayri patch ile scriptlestirilebilir.

```powershell
$root = 'C:\Users\Casper\Desktop\rxpro_mobile'
$lab = Join-Path $root 'emulator_rules_lab'
New-Item -ItemType Directory -Force -Path $lab | Out-Null
Copy-Item (Join-Path $root 'docs\FIX_FIRESTORE_RULES_DRAFT_51A_F_DO_NOT_DEPLOY.rules') (Join-Path $lab 'firestore.rules') -Force
Copy-Item (Join-Path $root 'docs\FIX_FIRESTORE_INDEXES_DRAFT_51A_F_DO_NOT_DEPLOY.json') (Join-Path $lab 'firestore.indexes.json') -Force
Copy-Item (Join-Path $root 'infra\rules\storage.rules') (Join-Path $lab 'storage.rules') -Force
```

Lab firebase.json ornek icerik:

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  },
  "emulators": {
    "auth": { "port": 9099 },
    "firestore": { "port": 8080 },
    "storage": { "port": 9199 },
    "ui": { "enabled": true, "port": 4000 }
  }
}
```

## 5. Emulator baslatma komutu

Lab klasoru uzerinden:

```powershell
Set-Location C:\Users\Casper\Desktop\rxpro_mobile\emulator_rules_lab
firebase emulators:start --only firestore,auth,storage
```

Bu komut production'a deploy yapmaz.

## 6. Manuel test akisi

Emulator calisirken test edilecek minimum akÄ±ÅŸlar:

1. individualUser kendi users dokumanini okuyup yazabiliyor mu?
2. unrelatedUser baska users dokumanini yazamiyor mu?
3. fcmTokens sadece kendi uid altina yazilabiliyor mu?
4. businessOwner kendi businesses dokumanini update edebiliyor mu?
5. unrelatedUser business update edemiyor mu?
6. businessOwner businessStaff create/update yapabiliyor mu?
7. linkedStaff kendi staffWorkStatus alanini update edebiliyor mu?
8. linkedStaff baska personel kaydini update edemiyor mu?
9. individualUser appointment create yapabiliyor mu?
10. linkedStaff sadece kendi appointment kaydini update edebiliyor mu?
11. notification targetScope=user sadece recipientUid tarafindan okunabiliyor mu?
12. notification targetScope=business business member tarafindan okunabiliyor mu?
13. messageThreads customer/business participant tarafindan okunabiliyor mu?
14. unrelatedUser thread okuyamiyor mu?
15. businessExpenses owner/staff permission olmadan okunamiyor mu?

## 7. Firebase deploy yasagi

51A-K asamasinda asagidaki komutlar calistirilmamalidir:

```powershell
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only storage
```

Production deploy ancak emulator/staging testlerinden sonra, tek domain tek patch mantigiyla yapilmalidir.

## 8. Sonraki karar

51A-K sonrasi iki guvenli yol var:

1. 51A-L: emulator_rules_lab klasorunu olusturan ama deploy yapmayan script.
2. 51B: Finance Domain Dictionary ve finance rules/index detay analizi.

Mevcut risklere gore finance/expense alanlari yuksek riskli oldugu icin 51B hattina gecmek mantiklidir. Ancak production rules sertlestirmeden once 51A-L emulator lab scripti daha guvenli ara adimdir.
