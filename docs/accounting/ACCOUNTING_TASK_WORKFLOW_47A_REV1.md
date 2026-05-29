# 47A REV1 Görevlerim / Randevu İş Akışı / Muhasebe Bağlantısı

Bu aşamada personel yetkileri yeniden ayrıldı.

## Yetki ayrımı

### Görevlerim / iş başlat-bitir
Personel kendisine atanan randevuyu başlatır ve işlemi bitirir.

Bu yetki çoğu iş yapan personelde açık olmalıdır.

Yazılan alanlar:
- workAssignedAppointments
- canWorkAssignedAppointments
- appointmentWork
- appointmentStartFinish
- completeAssignedAppointments
- viewAppointments

### Randevu erteleme / iptal yönetimi
Randevu tarihini değiştirme, erteleme veya iptal etme özel yetkidir.

Yazılan alanlar:
- manageAppointmentChanges
- canManageAppointmentChanges
- appointmentManage
- appointmentReschedule
- appointmentCancel
- canRescheduleAppointments
- canCancelAppointments
- updateAppointments
- cancelAppointments

## Muhasebe bağlantısı

İşlemi Bitirdim akışı ileride şu kayıtları tetiklemelidir:

1. Appointment status -> completed
2. Staff performance event
3. Service revenue draft
4. Payment status control
5. If unpaid/partial: receivable draft
6. If paid: payment transaction draft

Bu canlı kayıtlar Cloud Function tarafına bağlanmadan açılmayacak.