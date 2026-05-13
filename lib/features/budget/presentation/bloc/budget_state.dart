part of 'budget_bloc.dart';

sealed class BudgetState extends Equatable {
  const BudgetState();
}

class BudgetInitial extends BudgetState {
  const BudgetInitial();
  @override
  List<Object?> get props => [];
}

class BudgetLoading extends BudgetState {
  const BudgetLoading();
  @override
  List<Object?> get props => [];
}

class BudgetLoaded extends BudgetState {
  final List<Budget> budgets;
  final String searchQuery;
  final bool isOffline;
  final bool hasMore;
  final int currentPage;

  const BudgetLoaded({
    required this.budgets,
    this.searchQuery = '',
    this.isOffline = false,
    this.hasMore = false,
    this.currentPage = 1,
  });

  List<Budget> get filteredBudgets {
    if (searchQuery.isEmpty) return budgets;
    return budgets
        .where(
          (b) => b.category.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  BudgetLoaded copyWith({
    List<Budget>? budgets,
    String? searchQuery,
    bool? isOffline,
    bool? hasMore,
    int? currentPage,
  }) {
    return BudgetLoaded(
      budgets: budgets ?? this.budgets,
      searchQuery: searchQuery ?? this.searchQuery,
      isOffline: isOffline ?? this.isOffline,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [
    budgets,
    searchQuery,
    isOffline,
    hasMore,
    currentPage,
  ];
}

class BudgetError extends BudgetState {
  final String message;
  const BudgetError(this.message);
  @override
  List<Object?> get props => [message];
}
