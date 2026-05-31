import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/accounting/presentation/accounting_receivables_controller.dart';

void main() {
  group('AccountingReceivablesController', () {
    test('owns receivables filter', () {
      final controller = AccountingReceivablesController();
      var notifications = 0;
      controller.addListener(() => notifications += 1);

      expect(controller.filter, 'all');

      controller.setFilter('overdue');
      expect(controller.filter, 'overdue');
      expect(notifications, 1);

      controller.setFilter('overdue');
      expect(notifications, 1);

      controller.dispose();
    });
  });
}
