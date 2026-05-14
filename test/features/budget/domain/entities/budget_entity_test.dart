import 'package:flutter_test/flutter_test.dart';
import 'package:wealthpath/features/budget/domain/entities/budget.dart';

void main() {
  group('Budget', () {
    test('supports value equality', () {
      final first = Budget(
        id: '1',
        category: 'Food',
        spent: 100.0,
        limit: 500.0,
        currency: 'USD',
      );
      final second = Budget(
        id: '1',
        category: 'Food',
        spent: 100.0,
        limit: 500.0,
        currency: 'USD',
      );

      expect(first, equals(second));
      expect(first.hashCode, second.hashCode);
    });

    test('does not equal a budget with different fields', () {
      final first = Budget(
        id: '1',
        category: 'Food',
        spent: 100.0,
        limit: 500.0,
        currency: 'USD',
      );
      final second = Budget(
        id: '2',
        category: 'Entertainment',
        spent: 50.0,
        limit: 200.0,
        currency: 'USD',
      );

      expect(first, isNot(equals(second)));
    });

    test('exposes all constructor values', () {
      final budget = Budget(
        id: '123',
        category: 'Groceries',
        spent: 150.50,
        limit: 300.0,
        currency: 'EUR',
      );

      expect(budget.id, '123');
      expect(budget.category, 'Groceries');
      expect(budget.spent, 150.50);
      expect(budget.limit, 300.0);
      expect(budget.currency, 'EUR');
    });

    test('includes all fields in props', () {
      final budget = Budget(
        id: '1',
        category: 'Food',
        spent: 100.0,
        limit: 500.0,
        currency: 'USD',
      );

      expect(budget.props, ['1', 'Food', 100.0, 500.0, 'USD']);
    });

    test('calculates spendPercentage correctly', () {
      final budget = Budget(
        id: '1',
        category: 'Food',
        spent: 250.0,
        limit: 500.0,
        currency: 'USD',
      );

      expect(budget.spendPercentage, 0.5);
    });

    test('clamps spendPercentage to 1.0 when spent exceeds limit', () {
      final budget = Budget(
        id: '1',
        category: 'Food',
        spent: 600.0,
        limit: 500.0,
        currency: 'USD',
      );

      expect(budget.spendPercentage, 1.0);
    });

    test('returns 0.0 spendPercentage when limit is 0', () {
      final budget = Budget(
        id: '1',
        category: 'Food',
        spent: 100.0,
        limit: 0,
        currency: 'USD',
      );

      expect(budget.spendPercentage, 0.0);
    });

    test('returns BudgetStatus.danger when spent >= 90% of limit', () {
      final budget = Budget(
        id: '1',
        category: 'Food',
        spent: 450.0,
        limit: 500.0,
        currency: 'USD',
      );

      expect(budget.status, BudgetStatus.danger);
    });

    test('returns BudgetStatus.warning when spent >= 75% but < 90%', () {
      final budget = Budget(
        id: '1',
        category: 'Food',
        spent: 400.0,
        limit: 500.0,
        currency: 'USD',
      );

      expect(budget.status, BudgetStatus.warning);
    });

    test('returns BudgetStatus.normal when spent < 75%', () {
      final budget = Budget(
        id: '1',
        category: 'Food',
        spent: 300.0,
        limit: 500.0,
        currency: 'USD',
      );

      expect(budget.status, BudgetStatus.normal);
    });

    test('copyWith creates a new instance with updated fields', () {
      final original = Budget(
        id: '1',
        category: 'Food',
        spent: 100.0,
        limit: 500.0,
        currency: 'USD',
      );

      final updated = original.copyWith(spent: 150.0, limit: 400.0);

      expect(updated.id, original.id);
      expect(updated.category, original.category);
      expect(updated.spent, 150.0);
      expect(updated.limit, 400.0);
      expect(updated.currency, original.currency);
      expect(updated, isNot(equals(original)));
    });
  });
}
