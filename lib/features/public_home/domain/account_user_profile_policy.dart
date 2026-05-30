class AccountUserProfileUpdateInput {
  const AccountUserProfileUpdateInput({
    required this.displayName,
    required this.phone,
    required this.city,
    required this.district,
    required this.photoUrl,
  });

  final String displayName;
  final String phone;
  final String city;
  final String district;
  final String photoUrl;
}

class AccountUserProfilePolicy {
  const AccountUserProfilePolicy._();

  static String clean(Object? value) {
    return value?.toString().trim() ?? '';
  }

  static String? validateDisplayName(String? value) {
    if (clean(value).length < 2) {
      return 'Ad soyad en az 2 karakter olmalıdır.';
    }

    return null;
  }

  static AccountUserProfileUpdateInput normalizeUpdate({
    required String displayName,
    required String phone,
    required String city,
    required String district,
    required String photoUrl,
  }) {
    return AccountUserProfileUpdateInput(
      displayName: clean(displayName),
      phone: clean(phone),
      city: clean(city),
      district: clean(district),
      photoUrl: clean(photoUrl),
    );
  }

  static String verificationText({
    required String email,
    required String? authPhoneNumber,
    required String profilePhone,
  }) {
    final emailText = clean(email).isEmpty ? '-' : clean(email);
    final authPhoneText = clean(authPhoneNumber);
    final profilePhoneText = clean(profilePhone);
    var phoneText = authPhoneText;
    if (phoneText.isEmpty) {
      phoneText = profilePhoneText.isEmpty ? '-' : profilePhoneText;
    }

    return 'E-posta: $emailText\nTelefon: $phoneText';
  }
}
