import 'package:flutter/material.dart';

class RxDirectoryCategory {
  const RxDirectoryCategory({
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.aliases,
  });

  final String label;
  final String shortLabel;
  final IconData icon;
  final List<String> aliases;
}

class RxDirectoryFilters {
  static const categories = <RxDirectoryCategory>[
    RxDirectoryCategory(
      label: 'Güzellik & Bakım',
      shortLabel: 'Güzellik',
      icon: Icons.spa_rounded,
      aliases: [
        'güzellik',
        'guzellik',
        'kuaför',
        'kuafor',
        'berber',
        'cilt',
        'cilt bakımı',
        'tirnak',
        'tırnak',
        'protez tırnak',
        'kaş',
        'kas',
        'kirpik',
        'lazer',
        'epilasyon',
        'ağda',
        'agda',
        'makyaj',
        'masaj',
        'spa',
        'bakım',
        'bakim',
      ],
    ),
    RxDirectoryCategory(
      label: 'Sağlık & Klinik',
      shortLabel: 'Sağlık',
      icon: Icons.local_hospital_outlined,
      aliases: [
        'sağlık',
        'saglik',
        'klinik',
        'poliklinik',
        'doktor',
        'diş',
        'dis',
        'diş hekimi',
        'estetik',
        'psikolog',
        'psikiyatri',
        'diyetisyen',
        'fizyoterapi',
        'fizik tedavi',
        'laboratuvar',
      ],
    ),
    RxDirectoryCategory(
      label: 'Spor & Terapi',
      shortLabel: 'Spor',
      icon: Icons.fitness_center_rounded,
      aliases: [
        'spor',
        'fitness',
        'gym',
        'pt',
        'personal trainer',
        'pilates',
        'yoga',
        'terapi',
        'fizyoterapi',
        'fizik tedavi',
        'masaj',
        'rehabilitasyon',
      ],
    ),
    RxDirectoryCategory(
      label: 'Araç & Oto',
      shortLabel: 'Oto',
      icon: Icons.directions_car_filled_outlined,
      aliases: [
        'oto',
        'araç',
        'arac',
        'oto yıkama',
        'oto yikama',
        'oto bakım',
        'oto bakim',
        'ekspertiz',
        'servis',
        'lastik',
        'kaporta',
        'boya',
        'detailing',
        'yıkama',
        'yikama',
      ],
    ),
    RxDirectoryCategory(
      label: 'Eğitim & Kurs',
      shortLabel: 'Eğitim',
      icon: Icons.school_outlined,
      aliases: [
        'eğitim',
        'egitim',
        'kurs',
        'özel ders',
        'ozel ders',
        'sürücü kursu',
        'surucu kursu',
        'dil kursu',
        'dershane',
        'etüt',
        'etut',
      ],
    ),
    RxDirectoryCategory(
      label: 'Danışmanlık',
      shortLabel: 'Danışman',
      icon: Icons.handshake_outlined,
      aliases: [
        'danışmanlık',
        'danismanlik',
        'danışman',
        'danisman',
        'avukat',
        'hukuk',
        'mali müşavir',
        'mali musavir',
        'muhasebe',
        'emlak',
        'sigorta',
        'finans',
      ],
    ),
    RxDirectoryCategory(
      label: 'Ev & Teknik',
      shortLabel: 'Teknik',
      icon: Icons.home_repair_service_outlined,
      aliases: [
        'ev',
        'teknik',
        'tesisat',
        'elektrikçi',
        'elektrikci',
        'klima',
        'beyaz eşya',
        'beyaz esya',
        'tamir',
        'usta',
        'temizlik',
        'boya',
        'tadilat',
      ],
    ),
    RxDirectoryCategory(
      label: 'Veteriner',
      shortLabel: 'Veteriner',
      icon: Icons.pets_rounded,
      aliases: [
        'veteriner',
        'pet',
        'hayvan',
        'pet kuaför',
        'pet kuafor',
        'hayvan bakım',
        'hayvan bakim',
      ],
    ),
    RxDirectoryCategory(
      label: 'Fotoğraf & Organizasyon',
      shortLabel: 'Organizasyon',
      icon: Icons.photo_camera_outlined,
      aliases: [
        'fotoğraf',
        'fotograf',
        'fotoğrafçı',
        'fotografci',
        'organizasyon',
        'düğün',
        'dugun',
        'nişan',
        'nisan',
        'etkinlik',
        'kamera',
        'video',
      ],
    ),
  ];

  static bool matchesCategory({
    required String selectedCategory,
    required String businessCategory,
    String businessName = '',
    String description = '',
  }) {
    final selected = _norm(selectedCategory);

    if (selected.isEmpty || selected == _norm('Tümü')) {
      return true;
    }

    final haystack = _norm('$businessCategory $businessName $description');

    final matchedGroup = categories.where((category) {
      return _norm(category.label) == selected ||
          _norm(category.shortLabel) == selected;
    }).toList();

    if (matchedGroup.isEmpty) {
      return haystack.contains(selected);
    }

    final group = matchedGroup.first;

    if (haystack.contains(_norm(group.label)) ||
        haystack.contains(_norm(group.shortLabel))) {
      return true;
    }

    for (final alias in group.aliases) {
      if (haystack.contains(_norm(alias))) {
        return true;
      }
    }

    return false;
  }

  static String _norm(String value) {
    return value.trim().toLowerCase();
  }
}
