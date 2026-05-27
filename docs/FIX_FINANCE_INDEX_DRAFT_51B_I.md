# FIX Finance Index Draft - 51B-I REV1

Bu dokuman davranis degistirmez. Production infra/rules/firestore.indexes.json dosyasini degistirmez ve deploy yapmaz.

## 1. Kilit durum

51B-D/E/F constants adoption ve finance servis/ekran sabitleme hatti build aldi.
51B-G/H finance rules draft katmani statik dogrulamadan gecti.
51B-I ilk scriptinde JSON draft temiz olustu; ancak markdown dokumanda PowerShell encoding kaynakli Turkce karakter bozulmasi goruldu.
REV1 sadece dokumani ASCII-guvenli formatta yeniden yazar ve JSON draft'i tekrar parse eder.

## 2. Legacy-active index adaylari

| Collection | Alanlar | Amac | Oncelik |
|---|---|---|---:|
| financeRecords | businessId ASC, recordType ASC, monthKey DESC | aylik gelir/gider listeleme | Yuksek |
| financeRecords | businessId ASC, paymentStatus ASC, monthKey DESC | tahsilat/odeme durumu | Orta |
| financeRecords | businessId ASC, serviceId ASC, monthKey DESC | hizmet bazli gelir raporu | Orta |
| financeRecords | businessId ASC, staffUid ASC, monthKey DESC | personel bazli performans/gelir | Orta |
| businessExpenses | businessId ASC, monthKey DESC | aylik masraf listesi | Yuksek |
| businessExpenses | businessId ASC, category ASC, monthKey DESC | kategori bazli masraf | Orta |
| businessExpenses | businessId ASC, isRecurring ASC, monthKey DESC | tekrarli masraflar | Dusuk-Orta |

## 3. Canonical accounting index adaylari

| CollectionGroup | Alanlar | Amac | Oncelik |
|---|---|---|---:|
| accountingSales | businessId ASC, saleDate DESC | satis listesi | Orta |
| accountingExpenses | businessId ASC, expenseDate DESC | canonical masraf listesi | Orta |
| accountingReceivables | businessId ASC, paymentStatus ASC, dueDate ASC | alacak/vade takibi | Orta |
| accountingPayments | businessId ASC, paidAt DESC | odeme/tahsilat listesi | Orta |

## 4. Production gecis notu

Bu indexler production'a hemen uygulanmaz.
Production index merge ancak su siradan sonra yapilmalidir:

1. Aktif sorgularin BusinessFinancePage ve repository seviyesinde netlesmesi.
2. Emulator/staging test.
3. Mevcut infra/rules/firestore.indexes.json ile merge.
4. Tek komutla bilincli Firebase index deploy.

## 5. 51B-I kilit kriteri

- Draft JSON parse OK olmali.
- financeRecords, businessExpenses ve accounting* indexleri taslakta bulunmali.
- Production infra/rules/firestore.indexes.json degismemis olmali.
- Deploy yapilmamis olmali.

## 6. Sonraki adim

51B-J: Finance index draft static validation veya BusinessFinanceRepository audit.
