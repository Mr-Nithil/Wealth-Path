import 'package:wealthpath/features/budget/domain/entities/budget.dart';
import 'package:wealthpath/features/budget/domain/repositories/budget_repository.dart';

class CacheBudgets {
  final BudgetRepository repository;
  const CacheBudgets({required this.repository});

  Future<void> call(List<Budget> budgets) async {
    return await repository.cacheBudgets(budgets);
  }
}
