# FIX Emulator Rules Lab - 51A-L

Bu klasor sadece local emulator testleri icindir.

Production dosyalarina dokunulmaz:

- infra/rules/firestore.rules
- infra/rules/firestore.indexes.json
- infra/rules/storage.rules

Bu lab klasorundeki dosyalar:

- firestore.rules: docs altindaki DO NOT DEPLOY draft rules kopyasi
- firestore.indexes.json: docs altindaki DO NOT DEPLOY draft index kopyasi
- storage.rules: mevcut infra/rules/storage.rules kopyasi
- firebase.json: sadece emulator lab icin minimal config

Emulator baslatma komutu:

```powershell
Set-Location C:\Users\Casper\Desktop\rxpro_mobile\emulator_rules_lab
firebase emulators:start --only firestore,auth,storage
```

Yasak:

```powershell
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only storage
```

Bu lab klasoru production deploy icin kullanilmayacak.
