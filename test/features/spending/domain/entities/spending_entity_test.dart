import 'package:flutter_test/flutter_test.dart';
import 'package:wealthpath/features/spending/domain/entities/spending.dart';

void main() {
  group('Spending', () {
    test('supports value equality', () {
      final first = Spending(
        id: '1',
        merchant: 'Amazon',
        amount: 49.99,
        currency: 'USD',
        category: 'Shopping',
        date: DateTime(2024, 1, 1),
      );
      final second = Spending(
        id: '1',
        merchant: 'Amazon',
        amount: 49.99,
        currency: 'USD',
        category: 'Shopping',
        date: DateTime(2024, 1, 1),
      );

      expect(first, equals(second));
      expect(first.hashCode, second.hashCode);
    });

    test('does not equal a spending with different fields', () {
      final first = Spending(
        id: '1',
        merchant: 'Amazon',
        amount: 49.99,
        currency: 'USD',
        category: 'Shopping',
        date: DateTime(2024, 1, 1),
      );
      final second = Spending(
        id: '2',
        merchant: 'Starbucks',
        amount: 5.5,
        currency: 'USD',
        category: 'Food',
        date: DateTime(2024, 1, 2),
      );

      expect(first, isNot(equals(second)));
    });

    test('exposes all constructor values', () {
      final spending = Spending(
        id: '123',
        merchant: 'Target',
        amount: 32.75,
        currency: 'EUR',
        category: 'Groceries',
        date: DateTime(2025, 5, 12),
      );

      expect(spending.id, '123');
      expect(spending.merchant, 'Target');
      expect(spending.amount, 32.75);
      expect(spending.currency, 'EUR');
      expect(spending.category, 'Groceries');
      expect(spending.date, DateTime(2025, 5, 12));
    });

    test('includes all fields in props', () {
      final spending = Spending(
        id: '1',
        merchant: 'Amazon',
        amount: 49.99,
        currency: 'USD',
        category: 'Shopping',
        date: DateTime(2024, 1, 1),
      );

      expect(spending.props, [
        '1',
        'Amazon',
        49.99,
        'USD',
        'Shopping',
        DateTime(2024, 1, 1),
      ]);
    });
  });
}
