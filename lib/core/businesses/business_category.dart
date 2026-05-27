import 'package:flutter/foundation.dart';

@immutable
class BusinessCategoryOption {
  const BusinessCategoryOption({
    required this.id,
    required this.label,
    required this.keywords,
  });

  final String id;
  final String label;
  final List<String> keywords;

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'categoryId': id,
      'categoryLabel': label,
      'category': label,
      'businessCategory': label,
      'categoryKeywords': keywords,
    };
  }
}

class BusinessCategories {
  const BusinessCategories._();

  static const String allLabel = 'Tümü';

  static const List<BusinessCategoryOption> values = <BusinessCategoryOption>[
    BusinessCategoryOption(
      id: 'beauty_care',
      label: 'Güzellik & Bakım',
      keywords: <String>[
        'güzellik',
        'bakım',
        'cilt',
        'tırnak',
        'makyaj',
        'estetik',
        'lazer',
      ],
    ),
    BusinessCategoryOption(
      id: 'health_clinic',
      label: 'Sağlık & Klinik',
      keywords: <String>[
        'sağlık',
        'klinik',
        'muayene',
        'diş',
        'fizyoterapi',
        'diyetisyen',
      ],
    ),
    BusinessCategoryOption(
      id: 'sport_fitness',
      label: 'Spor & Fitness',
      keywords: <String>['spor', 'fitness', 'pilates', 'yoga', 'antrenman'],
    ),
    BusinessCategoryOption(
      id: 'consulting',
      label: 'Danışmanlık',
      keywords: <String>[
        'danışmanlık',
        'koçluk',
        'uzman',
        'görüşme',
        'randevu',
      ],
    ),
    BusinessCategoryOption(
      id: 'organization',
      label: 'Organizasyon',
      keywords: <String>[
        'organizasyon',
        'etkinlik',
        'düğün',
        'nişan',
        'doğum günü',
      ],
    ),
    BusinessCategoryOption(
      id: 'education',
      label: 'Eğitim',
      keywords: <String>['eğitim', 'kurs', 'özel ders', 'akademi', 'atölye'],
    ),
    BusinessCategoryOption(
      id: 'other_services',
      label: 'Diğer Hizmetler',
      keywords: <String>['hizmet', 'işletme', 'diğer'],
    ),
  ];

  static List<String> get labels {
    return values.map((e) => e.label).toList(growable: false);
  }

  static BusinessCategoryOption? byId(String? id) {
    final normalized = (id ?? '').trim();
    if (normalized.isEmpty) return null;

    for (final item in values) {
      if (item.id == normalized) return item;
    }

    return null;
  }

  static BusinessCategoryOption? byLabel(String? label) {
    final normalized = normalize(label);
    if (normalized.isEmpty) return null;

    for (final item in values) {
      if (normalize(item.label) == normalized) return item;
    }

    return null;
  }

  static BusinessCategoryOption fallbackFromDynamic({
    String? categoryId,
    String? categoryLabel,
    String? category,
    String? businessCategory,
  }) {
    return byId(categoryId) ??
        byLabel(categoryLabel) ??
        byLabel(category) ??
        byLabel(businessCategory) ??
        values.last;
  }

  static String normalize(String? value) {
    return _cleanLegacyEncoding(value ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('i̇', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  static bool matches({
    required String selectedLabel,
    required String? businessCategory,
    String? categoryId,
    String? categoryLabel,
  }) {
    if (selectedLabel == allLabel) return true;

    final selected = byLabel(selectedLabel);
    if (selected == null) return false;

    if ((categoryId ?? '').trim().isNotEmpty && categoryId == selected.id) {
      return true;
    }

    final selectedNorm = normalize(selected.label);

    return normalize(categoryLabel) == selectedNorm ||
        normalize(businessCategory) == selectedNorm;
  }

  static String _cleanLegacyEncoding(String value) {
    return value
        .replaceAll('Ãƒâ€Ã‚Â°', 'İ')
        .replaceAll('Ãƒâ€Ã‚Â±', 'ı')
        .replaceAll('Ãƒâ€Ã…Â¸', 'ğ')
        .replaceAll('Ãƒâ€Ã…Â¾', 'Ğ')
        .replaceAll('ÃƒÆ’Ã‚Â¼', 'ü')
        .replaceAll('ÃƒÆ’Ã…â€œ', 'Ü')
        .replaceAll('Ãƒâ€¦Ã…Â¸', 'ş')
        .replaceAll('Ãƒâ€¦Ã…Â¾', 'Ş')
        .replaceAll('ÃƒÆ’Ã‚Â¶', 'ö')
        .replaceAll('ÃƒÆ’Ã¢â‚¬â€œ', 'Ö')
        .replaceAll('ÃƒÆ’Ã‚Â§', 'ç')
        .replaceAll('ÃƒÆ’Ã¢â‚¬Â¡', 'Ç')
        .replaceAll('Ã„Â°', 'İ')
        .replaceAll('Ã„Â±', 'ı')
        .replaceAll('Ã„Å¸', 'ğ')
        .replaceAll('Ã„Å¾', 'Ğ')
        .replaceAll('ÃƒÂ¼', 'ü')
        .replaceAll('ÃƒÅ“', 'Ü')
        .replaceAll('Ã…Å¸', 'ş')
        .replaceAll('Ã…Å¾', 'Ş')
        .replaceAll('ÃƒÂ¶', 'ö')
        .replaceAll('Ãƒâ€“', 'Ö')
        .replaceAll('ÃƒÂ§', 'ç')
        .replaceAll('Ãƒâ€¡', 'Ç')
        .replaceAll('Ä°', 'İ')
        .replaceAll('Ä±', 'ı')
        .replaceAll('ÄŸ', 'ğ')
        .replaceAll('Ä', 'Ğ')
        .replaceAll('Ã¼', 'ü')
        .replaceAll('Ãœ', 'Ü')
        .replaceAll('ÅŸ', 'ş')
        .replaceAll('Å', 'Ş')
        .replaceAll('Ã¶', 'ö')
        .replaceAll('Ã–', 'Ö')
        .replaceAll('Ã§', 'ç')
        .replaceAll('Ã‡', 'Ç');
  }
}
