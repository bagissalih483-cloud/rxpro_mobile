# 46L Muhasebe Firestore Rules Taslağı

Bu dosya uygulama build'ine etki etmez. Firestore güvenlik kuralları için taslak niteliğindedir.

## Temel hedef

- Kurumsal kullanıcı sadece kendi `businessId` alanındaki muhasebe verisini görebilir.
- Personel yetkileri role/permission map üzerinden kontrol edilmelidir.
- Yazma işlemleri doğrudan client tarafından değil, mümkünse Cloud Function ile yapılmalıdır.

## Koleksiyonlar

```text
businesses/{businessId}/accountingSales/{saleId}
businesses/{businessId}/accountingPayments/{paymentId}
businesses/{businessId}/accountingReceivables/{receivableId}
businesses/{businessId}/accountingExpenses/{expenseId}
businesses/{businessId}/accountingRecurringExpenses/{recurringExpenseId}
businesses/{businessId}/accountingReports/{reportId}
```

## Yetki anahtarları

```text
financeRead
financeWrite
expenseWrite
receivableManage
reportExport
```

## Önerilen sıra

1. Önce sadece okuma kuralları test edilecek.
2. Sonra satış/tahsilat/gider yazmaları callable Cloud Function ile açılacak.
3. Client doğrudan muhasebe koleksiyonlarına yazmayacak.
4. Bildirimler 46H/sonrası Cloud Function tetikleyiciyle üretilecek.