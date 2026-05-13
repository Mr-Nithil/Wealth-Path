part of 'budget_bloc.dart';

sealed class BudgetEvent extends Equatable {
  const BudgetEvent();
}

class LoadBudgets extends BudgetEvent {
  const LoadBudgets();
  @override
  List<Object?> get props => [];
}

class LoadMoreBudgets extends BudgetEvent {
  const LoadMoreBudgets();
  @override
  List<Object?> get props => [];
}

class RefreshBudgets extends BudgetEvent {
  const RefreshBudgets();
  @override
  List<Object?> get props => [];
}

class SearchBudgets extends BudgetEvent {
  final String query;
  const SearchBudgets(this.query);
  @override
  List<Object?> get props => [query];
}

class ChangeBudgetLimit extends BudgetEvent {
  final String id;
  final double newLimit;
  const ChangeBudgetLimit({required this.id, required this.newLimit});
  @override
  List<Object?> get props => [id, newLimit];
}
