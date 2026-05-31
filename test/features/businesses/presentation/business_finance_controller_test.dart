import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/businesses/presentation/business_finance_controller.dart';
import 'package:rxpro_mobile/features/businesses/presentation/models/business_finance_models.dart';

void main() {
  group('BusinessFinanceController', () {
    test('owns finance loading, totals, period, and pdf state', () {
      final controller = BusinessFinanceController();
      addTearDown(controller.dispose);

      expect(controller.loading, isTrue);

      controller.beginReload();
      controller.applyLoaded(
        const FinanceLoadResult(
          expenses: [
            FinanceExpenseRow(
              id: 'expense-1',
              title: 'Rent',
              category: 'Kira',
              note: '',
              amount: 300,
              recurring: true,
              createdText: '2026-05-01',
            ),
            FinanceExpenseRow(
              id: 'expense-2',
              title: 'Ads',
              category: 'Reklam',
              note: '',
              amount: 100,
              recurring: false,
              createdText: '2026-05-02',
            ),
          ],
          incomes: [
            FinanceIncomeRow(
              id: 'income-1',
              title: 'Appointment',
              amount: 700,
              createdText: '2026-05-02',
            ),
          ],
          rawExpenseCount: 4,
          rawIncomeCount: 3,
          filteredExpenseCount: 2,
          filteredIncomeCount: 1,
          expenseReadError: null,
          incomeReadError: null,
        ),
      );

      expect(controller.loading, isFalse);
      expect(controller.expenseTotal, 400);
      expect(controller.incomeTotal, 700);
      expect(controller.net, 300);
      expect(controller.expenseByCategory['Kira'], 300);
      expect(controller.filteredIncomeCount, 1);

      final currentMonth = controller.period.month;
      controller.previousMonth();
      expect(controller.period.month, isNot(currentMonth));

      controller.setGeneratingPdf(true);
      expect(controller.generatingPdf, isTrue);
    });

    test('owns expense form selection and saving state', () {
      final controller = ExpenseFormController();
      addTearDown(controller.dispose);

      expect(controller.category, 'Genel');
      expect(controller.isRecurring, isFalse);

      controller.setCategory('Kira');
      controller.setRecurring(true);
      controller.setRecurringPeriod('weekly');
      controller.setSaving(true);

      expect(controller.category, 'Kira');
      expect(controller.isRecurring, isTrue);
      expect(controller.recurringPeriod, 'weekly');
      expect(controller.saving, isTrue);
    });
  });
}
