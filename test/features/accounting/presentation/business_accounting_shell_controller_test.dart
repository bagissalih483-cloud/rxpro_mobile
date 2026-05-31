import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/accounting/models/accounting_models.dart';
import 'package:rxpro_mobile/features/accounting/presentation/business_accounting_shell_controller.dart';

void main() {
  group('BusinessAccountingShellController', () {
    test('owns tab selection and clamps invalid indexes', () {
      final controller = BusinessAccountingShellController(
        now: DateTime(2026, 5, 30, 14),
      );

      expect(controller.index, 0);

      controller.selectTab(3, 5);
      expect(controller.index, 3);

      controller.selectTab(99, 5);
      expect(controller.index, 4);

      controller.selectTab(-10, 5);
      expect(controller.index, 0);

      controller.dispose();
    });

    test('normalizes and shifts accounting periods', () {
      final controller = BusinessAccountingShellController(
        now: DateTime(2026, 5, 30, 14, 45),
      );

      expect(controller.periodMode, AccountingPeriodMode.month);
      expect(controller.periodAnchor, DateTime(2026, 5));

      controller
        ..setPeriodMode(AccountingPeriodMode.day)
        ..shiftPeriod(1);
      expect(controller.periodAnchor, DateTime(2026, 5, 2));

      controller.setPeriodMode(AccountingPeriodMode.year);
      expect(controller.periodAnchor, DateTime(2026));

      controller.shiftPeriod(-1);
      expect(controller.periodAnchor, DateTime(2025));

      controller.goToCurrentPeriod(now: DateTime(2027, 8, 12, 9));
      expect(controller.periodAnchor, DateTime(2027));

      controller.dispose();
    });
  });
}
