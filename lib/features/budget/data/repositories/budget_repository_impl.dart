import 'package:wealthpath/core/errors/exceptions.dart';
import 'package:wealthpath/features/budget/data/datasources/budget_local_data_source.dart';
import 'package:wealthpath/features/budget/data/datasources/budget_remote_datasource.dart';
import 'package:wealthpath/features/budget/data/models/budget_model.dart';
import 'package:wealthpath/features/budget/domain/entities/budget.dart';
import 'package:wealthpath/features/budget/domain/repositories/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetRemoteDataSource remoteDataSource;
  final BudgetLocalDataSource localDataSource;

  const BudgetRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<({List<Budget> budgets, bool hasMore})> getBudgets({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final result = await remoteDataSource.getBudgets(
        page: page,
        limit: limit,
      );
      return (budgets: result.budgets, hasMore: result.hasMore);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<Budget> updateBudgetLimit(String id, double newLimit) async {
    try {
      final updated = await remoteDataSource.updateBudgetLimit(id, newLimit);

      await localDataSource.updateCachedBudget(updated);
      return updated;
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<List<Budget>> getCachedBudgets() async {
    try {
      return localDataSource.getCachedBudgets();
    } on CacheException {
      return [];
    }
  }

  @override
  Future<void> cacheBudgets(List<Budget> budgets) async {
    try {
      final models = budgets.map(BudgetModel.fromEntity).toList();
      await localDataSource.cacheBudgets(models);
    } on CacheException {
      rethrow;
    }
  }
}
