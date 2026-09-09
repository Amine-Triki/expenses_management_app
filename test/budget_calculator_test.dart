import 'package:flutter_test/flutter_test.dart';
import 'package:expenses_management_app/domain/budget_calculator.dart';
import 'package:expenses_management_app/domain/cycle_resolver.dart';

void main() {
  group('remaining & daily available', () {
    test('constitution example: 1500 (TND millimes) spent 1200', () {
      // 1500.000 TND = 1_500_000 minor units.
      const initial = 1500000;
      const spent = 1200000;
      final r = BudgetCalculator.remaining(
        initialAmount: initial,
        carryOverAmount: 0,
        spentInCycle: spent,
      );
      expect(r, 300000);
    });

    test('negative remaining is preserved, never hidden', () {
      final r = BudgetCalculator.remaining(
        initialAmount: 1000,
        carryOverAmount: 0,
        spentInCycle: 1500,
      );
      expect(r, -500);
    });

    test('daily available divides over remaining days', () {
      final window = const CycleWindow(
        start: CalendarDate(2026, 9, 1),
        end: CalendarDate(2026, 9, 30),
      );
      final days = BudgetCalculator.remainingDays(window, CalendarDate(2026, 9, 8));
      expect(days, 23);
      final daily = BudgetCalculator.dailyAvailable(
        remainingMinor: 46000,
        remainingDays: days,
      );
      expect(daily, closeTo(2000, 0.01));
    });

    test('daily available is null outside the cycle', () {
      expect(
        BudgetCalculator.dailyAvailable(remainingMinor: 100, remainingDays: 0),
        isNull,
      );
      expect(
        BudgetCalculator.dailyAvailable(remainingMinor: 100, remainingDays: -3),
        isNull,
      );
    });
  });

  group('carry-over (constitution rule)', () {
    test('enabled: remaining transfers to the new cycle', () {
      final carry = BudgetCalculator.carryOverAmount(
        carryOverEnabled: true,
        lastClosed: const ClosedCycleSnapshot(
          finalExpenseTotal: 1200000,
          finalRemaining: 300000,
        ),
      );
      // New cycle: 1500 + 300 = 1800 available.
      expect(
        BudgetCalculator.available(initialAmount: 1500000, carryOverAmount: carry),
        1800000,
      );
    });

    test('disabled: fresh start', () {
      final carry = BudgetCalculator.carryOverAmount(
        carryOverEnabled: false,
        lastClosed: const ClosedCycleSnapshot(
          finalExpenseTotal: 1200000,
          finalRemaining: 300000,
        ),
      );
      expect(carry, 0);
    });

    test('negative remaining carries as-is when enabled', () {
      final carry = BudgetCalculator.carryOverAmount(
        carryOverEnabled: true,
        lastClosed: const ClosedCycleSnapshot(
          finalExpenseTotal: 1700000,
          finalRemaining: -200000,
        ),
      );
      expect(
        BudgetCalculator.available(initialAmount: 1500000, carryOverAmount: carry),
        1300000,
      );
    });

    test('no previous cycle means no carry-over', () {
      expect(
        BudgetCalculator.carryOverAmount(carryOverEnabled: true, lastClosed: null),
        0,
      );
    });
  });
}
