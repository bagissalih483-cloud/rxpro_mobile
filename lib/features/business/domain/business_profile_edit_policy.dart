class BusinessProfileReadiness {
  const BusinessProfileReadiness({
    required this.completed,
    required this.total,
  });

  final int completed;
  final int total;

  int get percent => total <= 0 ? 0 : ((completed / total) * 100).round();
}

class BusinessProfileEditPolicy {
  const BusinessProfileEditPolicy._();

  static String clean(Object? value) {
    return value?.toString().trim() ?? '';
  }

  static String firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = clean(value);
      if (text.isNotEmpty) return text;
    }

    return '';
  }

  static String? validateBusinessName(String? value) {
    if (clean(value).length < 2) {
      return 'İşletme adı en az 2 karakter olmalıdır.';
    }

    return null;
  }

  static String? validateDescription(String? value) {
    final text = clean(value);
    if (text.isEmpty) {
      return 'Kurumsal profil açıklaması boş bırakılamaz.';
    }
    if (text.length < 10) {
      return 'Açıklama biraz daha detaylı olmalıdır.';
    }

    return null;
  }

  static String? validateRequired(String? value, String message) {
    return clean(value).isEmpty ? message : null;
  }

  static String? validateOptionalEmail(String? value) {
    final text = clean(value);
    if (text.isEmpty) return null;

    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
    return valid ? null : 'Geçerli bir e-posta giriniz.';
  }

  static String? validateOptionalUrl(String? value) {
    final text = clean(value);
    if (text.isEmpty) return null;

    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || uri.host.trim().isEmpty) {
      return 'Web sitesi https:// ile başlamalıdır.';
    }

    if (uri.scheme != 'https' && uri.scheme != 'http') {
      return 'Web sitesi http veya https adresi olmalıdır.';
    }

    return null;
  }

  static BusinessProfileReadiness readiness({
    required String businessName,
    required String description,
    required String city,
    required String district,
    required String address,
    required String workingHours,
    required bool hasLocation,
    required bool hasLogo,
    required bool hasCover,
  }) {
    final completed = <bool>[
      clean(businessName).isNotEmpty,
      clean(description).length >= 10,
      clean(city).isNotEmpty,
      clean(district).isNotEmpty,
      clean(address).isNotEmpty,
      clean(workingHours).isNotEmpty,
      hasLocation,
      hasLogo,
      hasCover,
    ].where((item) => item).length;

    return BusinessProfileReadiness(completed: completed, total: 9);
  }
}
