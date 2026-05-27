# 46Q Muhasebe Yetki Köprüsü

Bu aşama mevcut personel sistemine doğrudan yazmaz. Eski ve yeni yetki anahtarları arasında geçiş köprüsü kurar.

## Yeni standart muhasebe yetkileri

- `financeRead`
- `financeWrite`
- `expenseWrite`
- `receivableManage`
- `reportExport`

## Eski anahtar eşlemeleri

### financeRead
- `viewFinance`
- `canViewFinance`
- `analysisRead`
- `canViewAnalysis`

### financeWrite
- `enterFinance`
- `canManageFinance`
- `canManageSales`
- `paymentCollect`

### expenseWrite
- `enterExpenses`
- `canManageExpenses`
- `expenseManage`

### receivableManage
- `canManageReceivables`
- `receivableWrite`
- `paymentCollect`

### reportExport
- `canExportReports`
- `reportWrite`
- `financeExport`

## Hazır rol presetleri

- Owner: tüm yetkiler
- Kasa: satış/tahsilat + alacak
- Muhasebe: tüm muhasebe yetkileri
- Sadece görüntüleme: sadece financeRead

## Sonraki adım

46R aşamasında mevcut personel dosyaları analiz edilerek bu presetler personel düzenleme ekranına bağlanacak.