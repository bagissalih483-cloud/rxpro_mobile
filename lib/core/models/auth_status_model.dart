/// 49D-F1: Legacy DTO enum. Yeni rol/yetki kararları için kullanma;
/// AppRole + SessionRolePolicy ana kaynaktır. Bu enum eski model ve ekran
/// uyumluluğu için geçici olarak tutulur.
enum UserRole { guest, customer, businessOwner, staff, admin }

enum AccountStatus { pendingVerification, active, blocked }

enum BusinessStatus {
  draft,
  pendingVerification,
  pendingAdminReview,
  active,
  rejected,
  suspended,
}

extension UserRoleText on UserRole {
  String get label {
    switch (this) {
      case UserRole.guest:
        return 'Misafir';
      case UserRole.customer:
        return 'Bireysel Kullanıcı';
      case UserRole.businessOwner:
        return 'Kurumsal Kullanıcı';
      case UserRole.staff:
        return 'Personel';
      case UserRole.admin:
        return 'Admin';
    }
  }
}

extension AccountStatusText on AccountStatus {
  String get label {
    switch (this) {
      case AccountStatus.pendingVerification:
        return 'Doğrulama Bekliyor';
      case AccountStatus.active:
        return 'Aktif';
      case AccountStatus.blocked:
        return 'Engelli';
    }
  }
}

extension BusinessStatusText on BusinessStatus {
  String get label {
    switch (this) {
      case BusinessStatus.draft:
        return 'Taslak';
      case BusinessStatus.pendingVerification:
        return 'Doğrulama Bekliyor';
      case BusinessStatus.pendingAdminReview:
        return 'Admin Onayı Bekliyor';
      case BusinessStatus.active:
        return 'Aktif';
      case BusinessStatus.rejected:
        return 'Reddedildi';
      case BusinessStatus.suspended:
        return 'Askıya Alındı';
    }
  }
}
