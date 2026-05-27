# FIX Finance Domain Dictionary - 51B-C

Bu dokuman davranis degistirmez. Kod patch'i, build, deploy veya production rules/index degisikligi yapmaz.
Amac, 51B-B audit sonucunda ortaya cikan legacy/canonical finance yapisini netlestirmek ve sonraki patchleri guvenli siraya almaktir.

## 1. Audit sonucu kisa karar

51B-B sonucunda finans tarafinda iki farkli hat oldugu goruldu:

1. Legacy/aktif ekran hatti:
   - lib/features/businesses/business_finance_page.dart
   - lib/features/finance/services/finance_record_service.dart
   - collection: financeRecords
   - collection: businessExpenses

2. Yeni accounting domain hatti:
   - lib/features/accounting/*
   - AccountingRepository
   - CallableAccountingRepository
   - AccountingFunctionsClient
   - AccountingFirestorePaths
   - nested path: businesses/{businessId}/accountingSales
   - nested path: businesses/{businessId}/accountingPayments
   - nested path: businesses/{businessId}/accountingReceivables
   - nested path: businesses/{businessId}/accountingExpenses
   - nested path: businesses/{businessId}/accountingRecurringExpenses
   - nested path: businesses/{businessId}/accountingReports

Karar: Mevcut calisan business_finance_page ve FinanceRecordService bozulmayacak. Yeni accounting domain su an gelecekteki profesyonel muhasebe mimarisi icin daha dogru adaydir; fakat aktif veri okuma/yazma davranisi tam oturmadigi icin bir anda ana akisa alinmayacak.

## 2. Canonical / legacy ayrimi

| Alan | Durum | Karar |
|---|---|---|
| financeRecords | Randevu tamamlandi -> gelir kaydi icin aktif | Legacy-active olarak korunacak |
| businessExpenses | BusinessFinancePage masraf ekliyor/okuyor | Legacy-active olarak korunacak |
| businessFinanceRecords | Rules icinde var ama aktif kullanim net degil | Legacy/unused adayi |
| businesses/{businessId}/accountingSales | Yeni accounting domain | Canonical hedef |
| businesses/{businessId}/accountingPayments | Yeni accounting domain | Canonical hedef |
| businesses/{businessId}/accountingReceivables | Yeni accounting domain | Canonical hedef |
| businesses/{businessId}/accountingExpenses | Yeni accounting domain | Canonical hedef |
| businesses/{businessId}/accountingRecurringExpenses | Yeni accounting domain | Canonical hedef |
| businesses/{businessId}/accountingReports | Yeni accounting domain | Canonical hedef |

## 3. Legacy-active financeRecords sozlugu

Kayit tipi: appointment tamamlaninca gelir kaydi.

Kaynak servis:

- FinanceRecordService.createIncomeFromCompletedAppointment

Collection:

- financeRecords/{recordId}

Record id standardi:

- appointment_{appointmentId}

Zorunlu alanlar:

| Alan | Tip | Aciklama |
|---|---|---|
| id | string | recordId ile ayni |
| recordId | string | benzersiz finans kaydi |
| source | string | appointment_completed |
| sourceCollection | string | appointments |
| sourceAppointmentId | string | kaynak randevu id |
| appointmentId | string | kaynak randevu id |
| businessId | string | isletme id |
| amount | number | gelir tutari |
| recordType | string | income |
| paymentStatus | string | paid/paymentPending/receivable vb. |
| createdAt | timestamp | server timestamp |
| updatedAt | timestamp | server timestamp |
| monthKey | string | yyyy-MM |
| isDeleted | bool | soft delete |

Opsiyonel alanlar:

- businessName
- customerId
- customerName
- serviceId
- serviceName
- staffId
- staffUid
- staffName
- paymentMethod
- dueDate
- appointmentDate
- appointmentTime
- createdBy
- createdByName
- updatedBy
- updatedByName

## 4. Legacy-active businessExpenses sozlugu

Kaynak ekran:

- BusinessFinancePage / Masraf Ekle

Collection:

- businessExpenses/{expenseId}

Alanlar:

| Alan | Tip | Aciklama |
|---|---|---|
| businessId | string | isletme id |
| businessName | string | isletme adi |
| title | string | masraf basligi |
| expenseName | string | masraf adi |
| amount | number | masraf tutari |
| category | string | kategori |
| note | string | not |
| isRecurring | bool | tekrarli masraf mi |
| recurringPeriod | string | tekrar periyodu |
| periodResetDay | number | aylik reset gunu |
| expenseDate | string | gorunen tarih |
| expenseDateIso | string | ISO tarih |
| createdAtLocalIso | string | local ISO zaman |
| monthKey | string | yyyy-MM |
| createdAt | timestamp | server timestamp |
| updatedAt | timestamp | server timestamp |
| source | string | business_finance_page_37M_B |

## 5. Canonical accounting domain hedef sozluk

Yeni profesyonel muhasebe hedefi nested business altinda olmalidir:

```text
businesses/{businessId}/accountingSales/{saleId}
businesses/{businessId}/accountingPayments/{paymentId}
businesses/{businessId}/accountingReceivables/{receivableId}
businesses/{businessId}/accountingExpenses/{expenseId}
businesses/{businessId}/accountingRecurringExpenses/{recurringExpenseId}
businesses/{businessId}/accountingReports/{reportId}
```

Bu model Facebook/Instagram seviyesine daha yakindir; cunku her business domain verisi business root altinda scope edilir.

## 6. Payment status standardi

Mevcut sistemde birden fazla payment status var:

- paid
- paymentPending
- receivable
- unpaid
- partial
- collected

Hedef normalize enum:

| Canonical | Legacy karsiliklar | Anlam |
|---|---|---|
| unpaid | unpaid, paymentPending, receivable | tahsil edilmedi |
| partial | partial | kismi tahsilat |
| collected | paid, collected | tahsil edildi |
| overdue | overdue | vadesi gecmis |
| cancelled | cancelled | iptal |

51B sonrasi patchlerde bu enum sabitlestirilmeli; ancak mevcut veriler okunurken legacy fallback korunmali.

## 7. Appointment -> finance bridge karari

Mevcut calisan akista FinanceRecordService appointment tamamlaninca financeRecords altina idempotent gelir kaydi yaziyor.

Bu akisa dokunulmayacak. Sonraki hedef:

1. financeRecords yazimi korunur.
2. Accounting canonical modele gecis icin bridge tasarlanir.
3. Bir sure dual-read veya migration okuma stratejisi uygulanir.
4. business_finance_page once legacy financeRecords + businessExpenses okumaya devam eder.
5. Sonra BusinessFinanceRepository ile okuma tek noktaya toplanir.

## 8. Rules risk karari

Mevcut production rules'ta finans alanlari fazla genis:

```text
businessExpenses -> allow read, write: if signedIn()
businessActivityLogs -> allow read, write: if signedIn()
businessFinanceRecords -> allow read, write: if signedIn()
```

Bu production icin risklidir. Fakat hemen sertlestirme yapilmayacak. Once draft rules ve emulator/staging testi gerekir.

Rules hedefi:

| Collection | Read | Create | Update | Delete |
|---|---|---|---|---|
| businessExpenses | owner/finance staff | owner/finance staff | owner/finance staff | false veya owner only |
| financeRecords | owner/finance staff | appointment service/owner/staff limited | owner/finance staff limited | false |
| accountingExpenses | owner/finance staff | owner/finance staff | owner/finance staff | false |
| accountingSales | owner/finance staff | owner/staff/service bridge | owner/finance staff | false |
| accountingPayments | owner/finance staff | owner/finance staff | owner/finance staff | false |
| accountingReceivables | owner/finance staff | owner/finance staff | owner/finance staff | false |

## 9. Index hedefleri

Legacy-active index adaylari:

| Collection | Alanlar | Amac |
|---|---|---|
| financeRecords | businessId ASC, recordType ASC, monthKey DESC | aylik gelir listesi |
| financeRecords | businessId ASC, paymentStatus ASC, monthKey DESC | tahsilat durumu |
| businessExpenses | businessId ASC, monthKey DESC | aylik masraf listesi |
| businessExpenses | businessId ASC, category ASC, monthKey DESC | kategori bazli masraf |

Canonical accounting index adaylari:

| Path | Alanlar | Amac |
|---|---|---|
| businesses/{businessId}/accountingSales | saleDate DESC | satis listesi |
| businesses/{businessId}/accountingExpenses | expenseDate DESC | masraf listesi |
| businesses/{businessId}/accountingReceivables | dueDate ASC, status ASC | alacak takip |
| businesses/{businessId}/accountingPayments | paidAt DESC | tahsilat listesi |

## 10. Sonraki guvenli patch sirasi

1. 51B-D: Finance constants foundation.
2. 51B-E: business_finance_page constants adoption, davranis degistirmeden.
3. 51B-F: FinanceRecordService constants adoption, davranis degistirmeden.
4. 51B-G: Finance rules draft hardening, DO NOT DEPLOY.
5. 51B-H: BusinessFinanceRepository taslagi.
6. 51B-I: Accounting canonical migration plan.

## 11. 51B-C sonucu

Finance domain icin karar: legacy-active yapi korunacak, canonical accounting domain hedef olarak dokumante edilecek, production rules hemen degistirilmeyecek.
