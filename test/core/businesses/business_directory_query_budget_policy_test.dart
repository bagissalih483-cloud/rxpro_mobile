import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/core/businesses/business_directory_query_budget_policy.dart';

void main() {
  group('BusinessDirectoryQueryBudgetPolicy', () {
    test('caps starter directory scans to a bounded Firestore budget', () {
      expect(BusinessDirectoryQueryBudgetPolicy.pageSize(1000), 60);
      expect(BusinessDirectoryQueryBudgetPolicy.pageCap(1000), 300);
      expect(BusinessDirectoryQueryBudgetPolicy.pageSize(0), 1);
      expect(BusinessDirectoryQueryBudgetPolicy.pageCap(0), 1);
    });

    test('caps nearby searches before Firestore whereIn and limit', () {
      final prefixes = List.generate(20, (index) => 'prefix-$index');

      expect(
        BusinessDirectoryQueryBudgetPolicy.whereInPrefixes(prefixes),
        prefixes.take(10),
      );
      expect(BusinessDirectoryQueryBudgetPolicy.nearbyLimit(300), 120);
      expect(BusinessDirectoryQueryBudgetPolicy.nearbyLimit(0), 1);
      expect(BusinessDirectoryQueryBudgetPolicy.nearbyFallbackMinLocalResults, 8);
    });

    test('deduplicates and drops empty geo prefixes', () {
      expect(
        BusinessDirectoryQueryBudgetPolicy.whereInPrefixes([
          '',
          '  ',
          'syee',
          'syee',
          'syef',
        ]),
        ['syee', 'syef'],
      );
    });
  });
}
