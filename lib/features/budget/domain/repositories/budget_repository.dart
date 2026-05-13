import 'package:wealthpath/features/budget/domain/entities/budget.dart';

abstract class BudgetRepository {
  Future<({List<Budget> budgets, bool hasMore})> getBudgets({
    int page = 1,
    int limit = 20,
  });

  Future<Budget> updateBudgetLimit(String id, double newLimit);

  Future<List<Budget>> getCachedBudgets();

  Future<void> cacheBudgets(List<Budget> budgets);
}
