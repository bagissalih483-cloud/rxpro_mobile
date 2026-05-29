# 47B Görevlerim Giriş Sayfası

Bu aşamada ayrı `StaffTasksEntryPage` eklendi.

## Durum

- Görevlerim artık bağımsız bir sayfa olarak var.
- Sayfa mevcut kullanıcıya bağlı `businessStaff` kayıtlarını bulur.
- Kaydı seçince `StaffWorkspacePage` açılır.
- Açılışta `users/{uid}.permissions` görev yetkileriyle senkronize edilir.

## Neden Hesabım'a henüz otomatik eklenmedi?

Hesabım/kurumsal panel yerleşimi projede birkaç kez değiştiği için kör patch ile yanlış yere kart eklemek istemiyoruz. Bu patch exact navigation candidate raporu çıkarır. Sonraki küçük patchte Görevlerim kartı gerçek Hesabım ekranına bağlanacak.

## Sonraki adım

47B REV1:
- Hesabım veya Kurumsal Yönetim Merkezi içine görünür "Görevlerim" kartı eklenecek.