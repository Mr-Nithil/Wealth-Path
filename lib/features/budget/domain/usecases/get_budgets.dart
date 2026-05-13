import 'package:wealthpath/features/budget/domain/entities/budget.dart';
import 'package:wealthpath/features/budget/domain/repositories/budget_repository.dart';

class GetBudgets {
  final BudgetRepository repository;
  const GetBudgets({required this.repository});

  Future<({List<Budget> budgets, bool hasMore})> call({
    int page = 1,
    int limit = 20,
  }) {
    return repository.getBudgets(page: page, limit: limit);
  }
}
