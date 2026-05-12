import 'package:wealthpath/features/spending/domain/entities/spending.dart';

abstract class SpendingRepository {
  Future<({List<Spending> items, double total, bool hasMore})> getSpending({
    required int page,
    int limit = 20,
  });

  Future<Spending> addSpending({
    required String merchant,
    required double amount,
    required String category,
    String currency = 'USD',
  });
}
