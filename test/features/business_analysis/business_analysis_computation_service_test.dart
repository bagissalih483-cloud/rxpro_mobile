import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/business_analysis/services/business_analysis_computation_service.dart';

void main() {
  group('BusinessAnalysisComputationService', () {
    test('buildPeriodData filters rows by date and cancellation status', () {
      final service = BusinessAnalysisComputationService();
      final start = DateTime(2026, 5, 1);
      final end = DateTime(2026, 5, 2);

      final data = service.buildPeriodData(
        appointmentRows: const [
          {
            'startAtIso': '2026-05-01T10:00:00',
            'amount': '150,5',
            'serviceName': 'Massage',
            'staffName': 'Ada',
          },
          {
            'startAtIso': '2026-05-01T11:00:00',
            'amount': 200,
            'status': 'cancelled',
          },
          {
            'startAtIso': '2026-05-02T10:00:00',
            'amount': 300,
          },
        ],
        productSaleRows: const [
          {
            'saleDateIso': '2026-05-01T12:00:00',
            'productName': 'Serum',
            'quantity': 2,
            'totalAmount': 80,
          },
        ],
        productPurchaseRows: const [
          {'purchaseDateIso': '2026-05-01T09:00:00', 'quantity': 5},
          {'purchaseDateIso': '2026-05-03T09:00:00', 'quantity': 9},
        ],
        start: start,
        endExclusive: end,
      );

      expect(data.services, hasLength(1));
      expect(data.productSales, hasLength(1));
      expect(data.productPurchases, hasLength(1));
    });

    test('compute summarizes revenue, quantities and top lists', () {
      final service = BusinessAnalysisComputationService();
      final data = service.buildPeriodData(
        appointmentRows: const [
          {
            'startAtIso': '2026-05-01T10:00:00',
            'amount': '150,5',
            'serviceName': 'Massage',
            'staffName': 'Ada',
            'customerType': 'returning',
          },
        ],
        productSaleRows: const [
          {
            'saleDateIso': '2026-05-01T12:00:00',
            'productName': 'Serum',
            'quantity': 2,
            'totalAmount': 80,
          },
        ],
        productPurchaseRows: const [
          {'purchaseDateIso': '2026-05-01T09:00:00', 'quantity': 5},
        ],
        start: DateTime(2026, 5, 1),
        endExclusive: DateTime(2026, 5, 2),
      );

      final computed = service.compute(data);

      expect(computed.serviceRevenue, 150.5);
      expect(computed.productRevenue, 80);
      expect(computed.soldProductCount, 2);
      expect(computed.purchasedProductCount, 5);
      expect(computed.topServices.single.key, 'Massage');
      expect(computed.topProducts.single.key, 'Serum');
      expect(computed.topStaff.single.key, 'Ada');
    });
  });
}
