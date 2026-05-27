import 'package:flutter/material.dart';

import '../../../../core/businesses/business_category.dart';
import '../../../../core/theme/rx_ui.dart';

class HomeExploreCategoryStyle {
  const HomeExploreCategoryStyle({
    required this.background,
    required this.border,
    required this.accent,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color accent;
  final IconData icon;
}

class HomeExploreCategoryStyles {
  const HomeExploreCategoryStyles._();

  static const HomeExploreCategoryStyle all = HomeExploreCategoryStyle(
    background: RxColors.surface,
    border: Color(0xFFE1ECEB),
    accent: RxColors.primary,
    icon: Icons.grid_view_rounded,
  );

  static const HomeExploreCategoryStyle beauty = HomeExploreCategoryStyle(
    background: Color(0xFFFFF1F7),
    border: Color(0xFFF9C7DA),
    accent: Color(0xFFBE185D),
    icon: Icons.spa_outlined,
  );

  static const HomeExploreCategoryStyle health = HomeExploreCategoryStyle(
    background: Color(0xFFFFFFFF),
    border: Color(0xFFD6F5EA),
    accent: Color(0xFF0F766E),
    icon: Icons.local_hospital_outlined,
  );

  static const HomeExploreCategoryStyle sport = HomeExploreCategoryStyle(
    background: Color(0xFFEFF8FF),
    border: Color(0xFFBAE6FD),
    accent: Color(0xFF0369A1),
    icon: Icons.fitness_center_outlined,
  );

  static const HomeExploreCategoryStyle consulting = HomeExploreCategoryStyle(
    background: Color(0xFFF5F3FF),
    border: Color(0xFFDDD6FE),
    accent: RxColors.premium,
    icon: Icons.psychology_alt_outlined,
  );

  static const HomeExploreCategoryStyle organization = HomeExploreCategoryStyle(
    background: Color(0xFFFFF7ED),
    border: Color(0xFFFED7AA),
    accent: RxColors.warning,
    icon: Icons.celebration_outlined,
  );

  static const HomeExploreCategoryStyle education = HomeExploreCategoryStyle(
    background: Color(0xFFEEF2FF),
    border: Color(0xFFC7D2FE),
    accent: Color(0xFF4338CA),
    icon: Icons.school_outlined,
  );

  static const HomeExploreCategoryStyle other = HomeExploreCategoryStyle(
    background: Color(0xFFF8FAFC),
    border: Color(0xFFE2E8F0),
    accent: Color(0xFF475569),
    icon: Icons.storefront_outlined,
  );

  static HomeExploreCategoryStyle forLabel(String? label) {
    final normalized = BusinessCategories.normalize(label);
    if (normalized == BusinessCategories.normalize(BusinessCategories.allLabel)) {
      return all;
    }

    final category = BusinessCategories.byLabel(label);
    switch (category?.id) {
      case 'beauty_care':
        return beauty;
      case 'health_clinic':
        return health;
      case 'sport_fitness':
        return sport;
      case 'consulting':
        return consulting;
      case 'organization':
        return organization;
      case 'education':
        return education;
      default:
        return other;
    }
  }
}
