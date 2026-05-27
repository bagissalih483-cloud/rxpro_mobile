import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/core/businesses/business_category.dart';

void main() {
  group('BusinessCategories', () {
    test('normalizes Turkish labels for stable category matching', () {
      expect(
        BusinessCategories.normalize('  Güzellik & Bakım  '),
        'guzellik & bakim',
      );
      expect(BusinessCategories.normalize('Sağlık & Klinik'), 'saglik & klinik');
      expect(
        BusinessCategories.normalize('GÃƒÂ¼zellik & BakÃ„Â±m'),
        'guzellik & bakim',
      );
      expect(BusinessCategories.normalize('Spor & Fitness'), 'spor & fitness');
    });

    test('resolves fallback category by id, label, and legacy fields', () {
      expect(
        BusinessCategories.fallbackFromDynamic(categoryId: 'beauty_care').id,
        'beauty_care',
      );
      expect(
        BusinessCategories.fallbackFromDynamic(categoryLabel: 'Sağlık & Klinik')
            .id,
        'health_clinic',
      );
      expect(
        BusinessCategories.fallbackFromDynamic(
          businessCategory: 'Spor & Fitness',
        ).id,
        'sport_fitness',
      );
    });

    test('matches all label and selected category aliases', () {
      expect(
        BusinessCategories.matches(
          selectedLabel: BusinessCategories.allLabel,
          businessCategory: null,
        ),
        isTrue,
      );
      expect(
        BusinessCategories.matches(
          selectedLabel: 'Güzellik & Bakım',
          businessCategory: 'Güzellik & Bakım',
        ),
        isTrue,
      );
      expect(
        BusinessCategories.matches(
          selectedLabel: 'Güzellik & Bakım',
          businessCategory: 'Sağlık & Klinik',
        ),
        isFalse,
      );
    });

    test('writes Firestore compatibility fields', () {
      final category = BusinessCategories.byId('beauty_care')!;
      final data = category.toFirestore();

      expect(data['categoryId'], 'beauty_care');
      expect(data['categoryLabel'], 'Güzellik & Bakım');
      expect(data['category'], 'Güzellik & Bakım');
      expect(data['businessCategory'], 'Güzellik & Bakım');
      expect(data['categoryKeywords'], contains('güzellik'));
    });
  });
}
