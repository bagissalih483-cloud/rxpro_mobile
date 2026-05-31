import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/accounting/presentation/widgets/accounting_overview_panel_controller.dart';

void main() {
  group('AccountingOverviewPanelController', () {
    test('owns summary expanded state', () {
      final controller = AccountingOverviewPanelController();
      var notifications = 0;
      controller.addListener(() => notifications += 1);

      expect(controller.summaryExpanded, isFalse);

      controller.toggleSummary();
      expect(controller.summaryExpanded, isTrue);
      expect(notifications, 1);

      controller.toggleSummary();
      expect(controller.summaryExpanded, isFalse);
      expect(notifications, 2);

      controller.dispose();
    });
  });
}
