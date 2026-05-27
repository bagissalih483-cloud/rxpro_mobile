enum AppRole {
  guest,
  individual,
  corporateOwner,
  corporateStaff,
  admin,
  invalid,
}

extension AppRoleX on AppRole {
  bool get isGuest => this == AppRole.guest;
  bool get isIndividual => this == AppRole.individual;
  bool get isCorporate {
    return this == AppRole.corporateOwner || this == AppRole.corporateStaff;
  }

  bool get isCorporateOwner => this == AppRole.corporateOwner;
  bool get isCorporateStaff => this == AppRole.corporateStaff;

  String get label {
    switch (this) {
      case AppRole.guest:
        return 'Misafir';
      case AppRole.individual:
        return 'Bireysel Kullanıcı';
      case AppRole.corporateOwner:
        return 'Kurumsal Kullanıcı';
      case AppRole.corporateStaff:
        return 'Kurumsal Personel';
      case AppRole.admin:
        return 'Admin';
      case AppRole.invalid:
        return 'Rol Hatası';
    }
  }
}
