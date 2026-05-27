# 46K Muhasebe Veri Kontratı

Bu aşamada gerçek Firestore okuma/yazma açılmadı. Ama koleksiyon isimleri, veri alanları ve repository sınırı sabitlendi.

## Koleksiyonlar

- `businesses/{businessId}/accountingSales`
- `businesses/{businessId}/accountingPayments`
- `businesses/{businessId}/accountingReceivables`
- `businesses/{businessId}/accountingExpenses`
- `businesses/{businessId}/accountingRecurringExpenses`
- `businesses/{businessId}/accountingReports`

## Ana tutar mantığı

- `totalAmountKurus`: işlem tutarı
- `paidAmountKurus`: tahsil edilen tutar
- `remainingAmountKurus`: alacak sayılacak kalan tutar
- `discountAmountKurus`: ileride indirim/fiyat farkı için ayrılabilecek alan
- `depositAmountKurus`: kapora/kısmi ödeme için ayrılabilecek alan

## Telefonla müşteri eşleştirme

46L/46M aşamasında kayıtlı bireysel kullanıcı eşleştirmesi için:
- kullanıcı tarafında `phoneNormalized`
- satış tarafında `customerPhone`
- mümkünse `customerId`
alanları kullanılacak.

Eşleşme yoksa satış `manualCustomer` mantığıyla kalacak.

## Yetki anahtarları

- `financeRead`
- `financeWrite`
- `expenseWrite`
- `receivableManage`
- `reportExport`

## Sonraki adım

46L aşamasında Firestore repository gerçek uygulaması ve güvenlik kuralları taslağı hazırlanacak.