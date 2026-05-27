# FIX Finance Rules Draft Hardening - 51B-G

Bu dokuman ve draft production rules degisikligi yapmaz.
Amac, 51B finance domain icin mevcut genis signedIn kurallarini ileride nasil daraltacagimizi DO NOT DEPLOY taslak halinde netlestirmektir.

## 1. Kilit durum

51B-D: Finance constants foundation build aldi.
51B-E: BusinessFinancePage constants adoption build aldi.
51B-F: FinanceRecordService constants adoption build aldi.

Calisan davranis korunmustur:

- business_finance_page.dart gelir/masraf okuma davranisi
- businessExpenses yazma/okuma davranisi
- financeRecords fallback okuma davranisi
- FinanceRecordService appointment tamamlandi gelir kaydi
- appointment_{appointmentId} idempotent record id davranisi

## 2. Mevcut production risk

Mevcut production rules tarafinda finans bloklari fazla genis olabilir:

```text
businessExpenses -> signedIn read/write
businessActivityLogs -> signedIn read/write
businessFinanceRecords -> signedIn read/write
```

Bu production icin risklidir; fakat bir anda sertlestirme yapilmayacak.

## 3. Hedef finans yetki modeli

| Aktor | Okuma | Yazma | Not |
|---|---|---|---|
| corporateOwner | Tum finance/expense verisi | Tum finance/expense verisi | Ana yetkili |
| linkedStaff financePermission=false | Genelde kapali | Kapali | Finans hassas veri |
| linkedStaff financePermission=true | Kendi business finance verisi | Yetkili alanlarla sinirli | Ileride permission field gerekir |
| individual user | Kendi odeme/randevu bilgisi kadar | Finans collection yazamaz | Customer finance projection ayrilabilir |
| unrelated user | Kapali | Kapali | Kesin deny |
| guest | Kapali | Kapali | Yazma yok |

## 4. Hedef rules fonksiyonlari

Rules tarafinda su yardimci fonksiyonlar hedeflenir:

```rules
function signedIn() {
  return request.auth != null;
}

function isBusinessOwner(businessId) {
  // business doc veya user doc uzerinden owner dogrulama
}

function isLinkedStaffForBusiness(businessId) {
  // businessStaff veya user doc uzerinden linked staff dogrulama
}

function hasFinancePermission(businessId) {
  return isBusinessOwner(businessId) || staff finance permission;
}

function financeDataBelongsToBusiness(data, businessId) {
  return data.businessId == businessId;
}
```

## 5. Draft finance rules hedefi

Legacy-active collectionlar:

- financeRecords
- businessExpenses
- businessFinanceRecords
- businessActivityLogs

Canonical accounting hedefleri:

- businesses/{businessId}/accountingSales
- businesses/{businessId}/accountingPayments
- businesses/{businessId}/accountingReceivables
- businesses/{businessId}/accountingExpenses
- businesses/{businessId}/accountingRecurringExpenses
- businesses/{businessId}/accountingReports

## 6. Production gecis sirasi

1. finance read rules draft compile/emulator test.
2. businessExpenses read/write owner-only veya financePermission taslagi.
3. financeRecords create/update icin owner/staff/service bridge taslagi.
4. businessActivityLogs create-only/read-owner taslagi.
5. businessFinanceRecords legacy kullanim var mi tekrar audit.
6. Emulator testleri.
7. Staging testleri.
8. Production'a tek collection tek patch.

## 7. Dikkat edilecek riskler

- BusinessFinancePage halen businessExpenses ve financeRecords okuyor.
- FinanceRecordService appointment tamamlaninca financeRecords yaziyor.
- Bu yazim engellenirse gorev/randevu tamamlaninca finans kaydi olusmaz.
- Rules hardening once emulator/staging olmadan production'a alinmayacak.
- Personel finance permission alanlari netlesmeden linkedStaff'a genel finans izni verilmeyecek.

## 8. Sonuc

51B-G production rules patch degildir. Sadece finance security hardening icin draft ve dokuman zeminidir.
