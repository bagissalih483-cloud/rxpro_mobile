import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/accounting/presentation/accounting_reports_controller.dart';

void main() {
  group('AccountingReportsController', () {
    test('owns selected report type', () {
      final controller = AccountingReportsController();
      var notifications = 0;
      controller.addListener(() => notifications += 1);

      expect(controller.reportType, 'summary');

      controller.setReportType('expenses');
      expect(controller.reportType, 'expenses');
      expect(notifications, 1);

      controller.setReportType('expenses');
      expect(notifications, 1);

      controller.dispose();
    });
  });
}
