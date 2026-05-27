import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/businesses/presentation/utils/business_finance_formatters.dart';

void main() {
  group('business finance formatters', () {
    test('financeFilePeriod creates stable yyyy-mm keys', () {
      expect(financeFilePeriod(DateTime(2026, 5, 26)), '2026-05');
      expect(financeFilePeriod(DateTime(2026, 11, 1)), '2026-11');
    });

    test('financeDateText creates Turkish day month year text', () {
      expect(financeDateText(DateTime(2026, 5, 6)), '06.05.2026');
    });

    test('financeMoney formats positive and negative amounts', () {
      expect(financeMoney(1250), '1250,00 TL');
      expect(financeMoney(-42.5), '-42,50 TL');
    });
  });
}
