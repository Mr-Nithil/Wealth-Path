import 'package:wealthpath/features/budget/domain/entities/budget.dart';
import 'package:wealthpath/features/budget/domain/repositories/budget_repository.dart';

class UpdateBudgetLimit {
  final BudgetRepository repository;
  const UpdateBudgetLimit({required this.repository});

  Future<Budget> call(String id, double newLimit) {
    return repository.updateBudgetLimit(id, newLimit);
  }
}
