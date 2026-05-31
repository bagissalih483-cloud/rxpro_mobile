# Accounting Emulator Scenarios

Deploy öncesi emulator üzerinde doğrulanacak minimum muhasebe senaryoları:

## Randevu -> Bekleyen Adisyon

1. Yetkili personel randevuyu tamamlar.
2. `accountingEnsureAppointmentAdisyon` çalışır.
3. `accountingSales/appointment_{appointmentId}` oluşur.
4. Aynı randevu tekrar tamamlandığında ikinci adisyon oluşmaz.

## Adisyon İşleme

1. Bekleyen adisyon `paid` işlenir.
2. Adisyon `processed/paid` olur.
3. `accountingPayments` kaydı oluşur.
4. `accountingReceivables` kaydı oluşmaz veya kapanır.

## Kısmi Ödeme

1. Adisyon toplamından düşük tahsilat girilir.
2. Adisyon `processed/partial` olur.
3. Ödeme kaydı oluşur.
4. Alacak kaydı kalan bakiye ile oluşur.

## Açık Hesap

1. Ödeme alınmadan vade tarihiyle adisyon işlenir.
2. Adisyon `processed/openAccount` olur.
3. Ödeme kaydı oluşmaz.
4. Alacak kaydı açık durumda oluşur.

## Taksitli Satış

1. Adisyon taksitli işlenir.
2. Taksit kayıtları oluşur.
3. Tahsilatlar ekranında `Taksitler` filtresinde açık taksit görünür.
4. Tekil taksit tahsilatı `accountingCollectInstallmentPayment` ile yapılır.
5. Taksit ve bağlı adisyon bakiyesi birlikte güncellenir.

## İptal

1. Tahsilat alınmamış bekleyen adisyon iptal edilir.
2. Adisyon `cancelled` olur.
3. Varsa alacak/taksit kayıtları iptal işaretlenir.
4. Tahsilat alınmış adisyon iptali reddedilir.

## Tam İade

1. Tahsilatı olan işlenmiş adisyona tam iade uygulanır.
2. `accountingRefunds` kaydı oluşur.
3. Ters ödeme hareketi `accountingPayments` içine negatif tutarla yazılır.
4. Adisyon `refunded` olur.

## Yetki

1. Yetkisiz personel adisyon işleyemez.
2. `paymentCollect` olmayan kullanıcı tahsilat alamaz.
3. `saleCancel` olmayan kullanıcı iptal edemez.
4. `paymentRefund` olmayan kullanıcı iade yapamaz.
5. Mobil client finans koleksiyonlarına doğrudan yazamaz.
