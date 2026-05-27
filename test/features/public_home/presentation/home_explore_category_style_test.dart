import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/public_home/presentation/models/home_explore_category_style.dart';

void main() {
  group('HomeExploreCategoryStyles', () {
    test('maps marketplace categories to stable visual identities', () {
      expect(
        HomeExploreCategoryStyles.forLabel('Güzellik & Bakım').background,
        HomeExploreCategoryStyles.beauty.background,
      );
      expect(
        HomeExploreCategoryStyles.forLabel('Sağlık & Klinik').background,
        HomeExploreCategoryStyles.health.background,
      );
      expect(
        HomeExploreCategoryStyles.forLabel('Spor & Fitness').background,
        HomeExploreCategoryStyles.sport.background,
      );
    });

    test('falls back to neutral directory style for unknown categories', () {
      expect(
        HomeExploreCategoryStyles.forLabel('Bilinmeyen').accent,
        HomeExploreCategoryStyles.other.accent,
      );
    });
  });
}
