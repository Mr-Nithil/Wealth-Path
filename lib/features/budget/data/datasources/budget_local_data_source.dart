import 'package:hive/hive.dart';
import 'package:wealthpath/core/errors/exceptions.dart';
import 'package:wealthpath/features/budget/data/models/budget_model.dart';

abstract class BudgetLocalDataSource {
  List<BudgetModel> getCachedBudgets();
  Future<void> cacheBudgets(List<BudgetModel> budgets);
  Future<void> updateCachedBudget(BudgetModel budget);
}

class BudgetLocalDataSourceImpl implements BudgetLocalDataSource {
  final Box<BudgetModel> budgetBox;

  const BudgetLocalDataSourceImpl({required this.budgetBox});

  @override
  List<BudgetModel> getCachedBudgets() {
    try {
      return budgetBox.values.toList();
    } catch (e) {
      throw CacheException(message: 'Failed to read cache: ${e.toString()}');
    }
  }

  @override
  Future<void> cacheBudgets(List<BudgetModel> budgets) async {
    try {
      await budgetBox.clear();
      // Use budget id as Hive key for easy single-item updates
      final map = {for (final b in budgets) b.id: b};
      await budgetBox.putAll(map);
    } catch (e) {
      throw CacheException(message: 'Failed to cache budgets: ${e.toString()}');
    }
  }

  @override
  Future<void> updateCachedBudget(BudgetModel budget) async {
    try {
      await budgetBox.put(budget.id, budget);
    } catch (e) {
      throw CacheException(message: 'Failed to update cache: ${e.toString()}');
    }
  }
}
