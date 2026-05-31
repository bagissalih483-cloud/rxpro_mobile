import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/business_analysis/presentation/business_analysis_controller.dart';

void main() {
  group('BusinessAnalysisController', () {
    test('moves daily weekly and monthly periods from one owner', () {
      final controller = BusinessAnalysisController(
        anchorDate: DateTime(2026, 5, 30, 12),
      );

      expect(controller.periodMode, 0);
      expect(controller.rangeStart, DateTime(2026, 5, 30));
      expect(controller.rangeEndExclusive, DateTime(2026, 5, 31));

      controller.selectPeriod(1);

      expect(controller.periodLabel, 'Haftalık');
      expect(controller.rangeStart, DateTime(2026, 5, 25));
      expect(controller.rangeEndExclusive, DateTime(2026, 6, 1));

      controller.selectPeriod(2);
      controller.nextPeriod();

      expect(controller.periodLabel, 'Aylık');
      expect(controller.rangeStart, DateTime(2026, 6, 1));
      expect(controller.rangeEndExclusive, DateTime(2026, 7, 1));

      controller.dispose();
    });

    test('clears stale AI report when period changes', () {
      final controller = BusinessAnalysisController(
        anchorDate: DateTime(2026, 5, 30),
      );

      controller.setAiReport('ready');
      controller.selectPeriod(1);

      expect(controller.aiReport, isEmpty);

      controller.dispose();
    });

    test('owns AI loading and report state', () {
      final controller = BusinessAnalysisController(
        anchorDate: DateTime(2026, 5, 30),
      );
      var notifications = 0;
      controller.addListener(() => notifications += 1);

      controller
        ..setAiLoading(true)
        ..setAiReport('analysis');

      expect(controller.aiLoading, isTrue);
      expect(controller.aiReport, 'analysis');
      expect(notifications, 2);

      controller.dispose();
    });
  });
}
