# Accounting Production Hardening Status

## Bu pakette kilitlenen alan

Bu çalışma, muhasebe/adisyon zincirindeki en kritik production riskini azaltmak için yapıldı:

```text
Mobil uygulama
  -> accountingEnsureAppointmentAdisyon / accountingProcessSale callable komutları
  -> Cloud Function transaction
  -> sale/payment/receivable/installment/activity log kayıtları
```

Mobil taraf artık adisyon işleme sırasında `accountingSales`, `accountingPayments`,
`accountingReceivables` ve `accountingInstallments` koleksiyonlarına doğrudan
çoklu yazım yapmaz. Adisyon işleme komutu `functions/modules/accounting.js`
içindeki tek transaction akışına taşındı.

Randevu tamamlandıktan sonra bekleyen adisyon oluşturma köprüsü de client
Firestore transaction yerine `accountingEnsureAppointmentAdisyon` callable
komutuna taşındı. Böylece Firestore rules finans koleksiyonlarını kapattığında
randevu -> bekleyen adisyon akışı korunur.

Randevu tamamlandıktan sonra adisyon callable'ı hata verirse randevu tamamlama
akışı geri alınmaz. Kullanıcıya bekleyen adisyonun oluşturulamadığı ve
muhasebeden manuel açılabileceği bildirilir.

Ek tahsilat akışı da aynı pakette sıkılaştırıldı. `accountingCollectPayment`
artık yalnızca ödeme belgesi oluşturmaz; aynı transaction içinde bağlı adisyonun
`paidAmountKurus`, `remainingAmountKurus`, `paymentStatus` alanlarını ve ilgili
alacak kaydını günceller.

Taksit ve iptal için ikinci güvenlik katmanı da eklendi:

- `accountingCollectInstallmentPayment`
  - Tekil taksit ödemesini alır.
  - Taksit bakiyesi, adisyon bakiyesi, alacak ve ödeme kaydını aynı transaction
    içinde günceller.
  - Kapanmış/iptal taksite tekrar tahsilat girilmesini engeller.
- `accountingCancelSale`
  - Tahsilat alınmamış adisyonu iptal eder.
  - Varsa bağlı alacak ve taksit kayıtlarını iptal işaretler.
  - Tahsilat alınmış adisyon için iptal yerine iade/düzeltme akışı zorunlu
    bırakılır.
- `accountingRefundSale`
  - İlk güvenli fazda yalnızca tam iade kabul eder.
  - İade kaydı, ters ödeme hareketi, adisyon durumu ve activity log aynı
    transaction içinde yazılır.
  - İade edilen adisyonlar özet gelir hesabından dışlanır.

## UI bağlantıları

- `Muhasebe > Adisyon Yönet`
  - Bekleyen adisyonlarda yetkiye göre `İşle` ve `İptal` aksiyonları görünür.
  - İşlenmiş ve tahsilatı olan adisyonlarda yetkiye göre `İade` aksiyonu
    görünür.
  - İade aksiyonu ilk fazda tam iade komutuna bağlandı.
- `Muhasebe > Tahsilatlar`
  - Kalan bakiyesi olan adisyonlarda yetkili kullanıcı tutar ve yöntem seçerek
    gerçek tahsilat kaydı oluşturur.
  - Tahsilat işlemi `accountingCollectPayment` server transaction akışına gider.
  - Taksit kayıtları `Taksitler` filtresinde ayrı satır olarak görünür.
  - Taksit tahsilatı `accountingCollectInstallmentPayment` server transaction
    akışına gider.

## Uygulanan kararlar

- Adisyon işleme sonucu desteklenen durumlar:
  - `paid`
  - `partial`
  - `openAccount`
  - `installment`
  - `free`
- `paid` ve `partial` işlemleri için ödeme alma yetkisi aranır.
- `openAccount`, `installment` ve `free` işlemleri için adisyon işleme yetkisi aranır.
- Kısmi ödemede alınan tutar sıfırdan büyük ve toplamdan küçük olmak zorundadır.
- Açık hesap ve taksitli işlemde kalan tutar ve vade tarihi zorunludur.
- Taksit sayısı 2 ile 24 arasında sınırlandı.
- İşlenen adisyon tekrar işlenemez.
- İptal veya geçersiz adisyon işlenemez.
- Her işleme activity log yazılır.
- Randevudan adisyon üretimi deterministic `appointment_{appointmentId}` id ile
  duplicate oluşturmaz.
- Manuel adisyon oluştururken kalan bakiye server tarafında yeniden hesaplanır;
  client'tan gelen tutarsız `remainingAmountKurus` değeri kabul edilmez.

## Firestore rules sıkılaştırması

`infra/rules/firestore.rules` içinde nested business yazımı daraltıldı.
Şu finans koleksiyonları server-managed kabul edildi:

```text
accountingSales
accountingPayments
accountingReceivables
accountingInstallments
accountingExpenses
accountingReports
accountingRecurringExpenses
accountingRefunds
```

Bu koleksiyonlara mobil client doğrudan yazamaz. Cloud Functions Admin SDK ile
rules dışından güvenli transaction yürütür.

## Yetki uyumluluğu

Yeni izin anahtarları eklendi:

```text
saleProcess
saleCancel
paymentCollect
paymentRefund
reportsRead
adisyon.view
adisyon.edit
adisyon.collectPayment
adisyon.cancel
```

Eski `financeWrite`, `receivableManage`, `canManageFinance` gibi anahtarlar
geçiş döneminde geriye dönük uyumlu tutuldu.

## Henüz deploy edilmedi

Bu pakette production deploy, rules deploy, functions deploy, build veya APK
alınmadı. Canlıya almak için sonraki adımlar kullanıcı tarafından ayrıca
PowerShell ile yürütülmelidir.

## Sonraki güvenli aşama

1. Emulator testleriyle rules ve function transaction senaryoları doğrulanmalı.
2. Kısmi iade/düzeltme için ayrı denetimli muhasebe akışı tasarlanmalı.
3. Kısmi iade ve düzeltme akışı için ayrı UI + callable tasarlanmalı.
4. Günlük kasa/rapor özetleri Cloud Function event akışına bağlanmalı.
5. Finans koleksiyonları için production index gereksinimleri tekrar çıkarılmalı.
