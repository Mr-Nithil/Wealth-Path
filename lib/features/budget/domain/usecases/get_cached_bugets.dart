import 'package:wealthpath/features/budget/domain/entities/budget.dart';
import 'package:wealthpath/features/budget/domain/repositories/budget_repository.dart';

class GetCachedBudgets {
  final BudgetRepository repository;
  const GetCachedBudgets({required this.repository});

  Future<List<Budget>> call() {
    return repository.getCachedBudgets();
  }
}
