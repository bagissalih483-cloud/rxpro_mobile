enum AccountMode { guest, individual, corporateOwner, linkedStaff }

extension AccountModeX on AccountMode {
  bool get isGuest => this == AccountMode.guest;
  bool get isIndividual => this == AccountMode.individual;
  bool get isCorporateOwner => this == AccountMode.corporateOwner;
  bool get isLinkedStaff => this == AccountMode.linkedStaff;

  bool get isCorporate {
    return this == AccountMode.corporateOwner ||
        this == AccountMode.linkedStaff;
  }

  String get badgeLabel {
    switch (this) {
      case AccountMode.guest:
        return 'Oturum yok';
      case AccountMode.individual:
        return 'Bireysel kullanıcı hesabı';
      case AccountMode.corporateOwner:
        return 'Kurumsal owner hesabı';
      case AccountMode.linkedStaff:
        return 'Bağlı personel hesabı';
    }
  }
}
