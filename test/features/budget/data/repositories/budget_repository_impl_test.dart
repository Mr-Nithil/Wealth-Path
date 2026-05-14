import 'package:flutter_test/flutter_test.dart';
import 'package:wealthpath/core/errors/exceptions.dart';
import 'package:wealthpath/features/budget/data/datasources/budget_local_data_source.dart';
import 'package:wealthpath/features/budget/data/datasources/budget_remote_datasource.dart';
import 'package:wealthpath/features/budget/data/models/budget_model.dart';
import 'package:wealthpath/features/budget/data/repositories/budget_repository_impl.dart';

class MockBudgetRemoteDataSource implements BudgetRemoteDataSource {
  ({List<BudgetModel> budgets, bool hasMore})? _mockGetResult;
  BudgetModel? _mockUpdateResult;
  ServerException? _mockException;

  void mockGetBudgetsSuccess(
    ({List<BudgetModel> budgets, bool hasMore}) result,
  ) {
    _mockGetResult = result;
    _mockException = null;
  }

  void mockUpdateBudgetSuccess(BudgetModel result) {
    _mockUpdateResult = result;
    _mockException = null;
  }

  void mockException(ServerException exception) {
    _mockException = exception;
    _mockGetResult = null;
    _mockUpdateResult = null;
  }

  void reset() {
    _mockGetResult = null;
    _mockUpdateResult = null;
    _mockException = null;
  }

  @override
  Future<({List<BudgetModel> budgets, bool hasMore})> getBudgets({
    int page = 1,
    int limit = 20,
  }) async {
    if (_mockException != null) {
      throw _mockException!;
    }
    return _mockGetResult ?? (budgets: <BudgetModel>[], hasMore: false);
  }

  @override
  Future<BudgetModel> updateBudgetLimit(String id, double newLimit) async {
    if (_mockException != null) {
      throw _mockException!;
    }
    return _mockUpdateResult ??
        BudgetModel(
          id: id,
          category: 'Food',
          spent: 100.0,
          limit: newLimit,
          currency: 'USD',
        );
  }
}

class MockBudgetLocalDataSource implements BudgetLocalDataSource {
  List<BudgetModel>? _cachedBudgets;
  Exception? _mockException;

  void mockGetSuccess(List<BudgetModel> budgets) {
    _cachedBudgets = budgets;
    _mockException = null;
  }

  void mockException(Exception exception) {
    _mockException = exception;
    _cachedBudgets = null;
  }

  void reset() {
    _cachedBudgets = null;
    _mockException = null;
  }

  @override
  List<BudgetModel> getCachedBudgets() {
    if (_mockException != null) {
      throw _mockException!;
    }
    return _cachedBudgets ?? <BudgetModel>[];
  }

  @override
  Future<void> cacheBudgets(List<BudgetModel> budgets) async {
    _cachedBudgets = budgets;
  }

  @override
  Future<void> updateCachedBudget(BudgetModel budget) async {
    if (_cachedBudgets != null) {
      _cachedBudgets = _cachedBudgets!
          .map((b) => b.id == budget.id ? budget : b)
          .toList();
    }
  }
}

void main() {
  late BudgetRepositoryImpl repository;
  late MockBudgetRemoteDataSource mockRemoteDataSource;
  late MockBudgetLocalDataSource mockLocalDataSource;

  setUp(() {
    mockRemoteDataSource = MockBudgetRemoteDataSource();
    mockLocalDataSource = MockBudgetLocalDataSource();
    repository = BudgetRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  group('BudgetRepositoryImpl - getBudgets', () {
    final tBudgetList = [
      BudgetModel(
        id: '1',
        category: 'Food',
        spent: 100.0,
        limit: 500.0,
        currency: 'USD',
      ),
      BudgetModel(
        id: '2',
        category: 'Entertainment',
        spent: 50.0,
        limit: 200.0,
        currency: 'USD',
      ),
    ];

    test('returns correct data when getBudgets succeeds', () async {
      mockRemoteDataSource.mockGetBudgetsSuccess((
        budgets: tBudgetList,
        hasMore: false,
      ));

      final result = await repository.getBudgets(page: 1, limit: 20);

      expect(result.budgets, tBudgetList);
      expect(result.hasMore, false);
    });

    test('returns paginated data when hasMore is true', () async {
      mockRemoteDataSource.mockGetBudgetsSuccess((
        budgets: tBudgetList,
        hasMore: true,
      ));

      final result = await repository.getBudgets(page: 1, limit: 20);

      expect(result.budgets.length, 2);
      expect(result.hasMore, true);
    });

    test('throws ServerException when remote data source fails', () async {
      mockRemoteDataSource.mockException(
        ServerException(message: 'Failed to fetch budgets'),
      );

      expect(
        () => repository.getBudgets(page: 1, limit: 20),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Failed to fetch budgets',
          ),
        ),
      );
    });

    test('throws ServerException with specific status code', () async {
      mockRemoteDataSource.mockException(
        ServerException(message: 'Unauthorized', statusCode: 401),
      );

      expect(
        () => repository.getBudgets(page: 1),
        throwsA(
          isA<ServerException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });
  });

  group('BudgetRepositoryImpl - updateBudgetLimit', () {
    const tId = '1';
    const tNewLimit = 750.0;

    test('returns updated budget when updateBudgetLimit succeeds', () async {
      final tUpdatedBudget = BudgetModel(
        id: tId,
        category: 'Food',
        spent: 100.0,
        limit: tNewLimit,
        currency: 'USD',
      );
      mockRemoteDataSource.mockUpdateBudgetSuccess(tUpdatedBudget);

      final result = await repository.updateBudgetLimit(tId, tNewLimit);

      expect(result.id, tId);
      expect(result.limit, tNewLimit);
    });

    test('throws ServerException when update fails', () async {
      mockRemoteDataSource.mockException(
        ServerException(message: 'Failed to update budget'),
      );

      expect(
        () => repository.updateBudgetLimit(tId, tNewLimit),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Failed to update budget',
          ),
        ),
      );
    });
  });

  group('BudgetRepositoryImpl - cacheBudgets', () {
    final tBudgetList = [
      BudgetModel(
        id: '1',
        category: 'Food',
        spent: 100.0,
        limit: 500.0,
        currency: 'USD',
      ),
    ];

    test('caches budgets successfully', () async {
      await repository.cacheBudgets(tBudgetList);
      final cached = await repository.getCachedBudgets();

      expect(cached, tBudgetList);
    });
  });

  group('BudgetRepositoryImpl - getCachedBudgets', () {
    final tBudgetList = [
      BudgetModel(
        id: '1',
        category: 'Food',
        spent: 100.0,
        limit: 500.0,
        currency: 'USD',
      ),
    ];

    test('returns cached budgets', () async {
      mockLocalDataSource.mockGetSuccess(tBudgetList);

      final result = await repository.getCachedBudgets();

      expect(result, tBudgetList);
    });

    test('returns empty list when no cache exists', () async {
      mockLocalDataSource.mockGetSuccess([]);

      final result = await repository.getCachedBudgets();

      expect(result, isEmpty);
    });

    test('throws exception when cache fails', () async {
      mockLocalDataSource.mockException(Exception('Cache error'));

      expect(() => repository.getCachedBudgets(), throwsA(isA<Exception>()));
    });
  });
}
