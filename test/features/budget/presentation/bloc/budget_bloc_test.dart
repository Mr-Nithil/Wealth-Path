import 'package:flutter_test/flutter_test.dart';
import 'package:wealthpath/features/budget/data/models/budget_model.dart';
import 'package:wealthpath/features/budget/domain/entities/budget.dart';
import 'package:wealthpath/features/budget/domain/repositories/budget_repository.dart';
import 'package:wealthpath/features/budget/domain/usecases/cache_budgets.dart';
import 'package:wealthpath/features/budget/domain/usecases/get_budgets.dart';
import 'package:wealthpath/features/budget/domain/usecases/get_cached_bugets.dart';
import 'package:wealthpath/features/budget/domain/usecases/update_budget_limit.dart';
import 'package:wealthpath/features/budget/presentation/bloc/budget_bloc.dart';

class MockBudgetRepository implements BudgetRepository {
  @override
  Future<({List<Budget> budgets, bool hasMore})> getBudgets({
    int page = 1,
    int limit = 20,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Budget> updateBudgetLimit(String id, double newLimit) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Budget>> getCachedBudgets() async {
    throw UnimplementedError();
  }

  @override
  Future<void> cacheBudgets(List<Budget> budgets) async {
    throw UnimplementedError();
  }
}

class MockGetBudgets implements GetBudgets {
  ({List<Budget> budgets, bool hasMore})? _mockResult;
  Exception? _mockException;
  int callCount = 0;

  @override
  final repository = MockBudgetRepository();

  void mockSuccess(({List<Budget> budgets, bool hasMore}) result) {
    _mockResult = result;
    _mockException = null;
  }

  void mockError(Exception exception) {
    _mockException = exception;
    _mockResult = null;
  }

  void reset() {
    _mockResult = null;
    _mockException = null;
    callCount = 0;
  }

  @override
  Future<({List<Budget> budgets, bool hasMore})> call({
    int page = 1,
    int limit = 20,
  }) async {
    callCount++;
    if (_mockException != null) {
      throw _mockException!;
    }
    if (_mockResult != null) {
      return _mockResult!;
    }
    return (budgets: <Budget>[], hasMore: false);
  }
}

class MockGetCachedBudgets implements GetCachedBudgets {
  List<Budget>? _mockResult;
  Exception? _mockException;

  @override
  final repository = MockBudgetRepository();

  void mockSuccess(List<Budget> result) {
    _mockResult = result;
    _mockException = null;
  }

  void mockError(Exception exception) {
    _mockException = exception;
    _mockResult = null;
  }

  void reset() {
    _mockResult = null;
    _mockException = null;
  }

  @override
  Future<List<Budget>> call() async {
    if (_mockException != null) {
      throw _mockException!;
    }
    return _mockResult ?? <Budget>[];
  }
}

class MockUpdateBudgetLimit implements UpdateBudgetLimit {
  @override
  final repository = MockBudgetRepository();

  @override
  Future<Budget> call(String id, double newLimit) async {
    throw UnimplementedError();
  }
}

class MockCacheBudgets implements CacheBudgets {
  @override
  final repository = MockBudgetRepository();

  @override
  Future<void> call(List<Budget> budgets) async {}
}

void main() {
  late BudgetBloc budgetBloc;
  late MockGetBudgets mockGetBudgets;
  late MockGetCachedBudgets mockGetCachedBudgets;
  late MockUpdateBudgetLimit mockUpdateBudgetLimit;
  late MockCacheBudgets mockCacheBudgets;

  setUp(() {
    mockGetBudgets = MockGetBudgets();
    mockGetCachedBudgets = MockGetCachedBudgets();
    mockUpdateBudgetLimit = MockUpdateBudgetLimit();
    mockCacheBudgets = MockCacheBudgets();

    budgetBloc = BudgetBloc(
      getBudgets: mockGetBudgets,
      updateBudgetLimit: mockUpdateBudgetLimit,
      getCachedBudgets: mockGetCachedBudgets,
      cacheBudgets: mockCacheBudgets,
    );
  });

  tearDown(() {
    budgetBloc.close();
    mockGetBudgets.reset();
    mockGetCachedBudgets.reset();
  });

  group('BudgetBloc - LoadBudgets', () {
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

    test('emits BudgetLoading then BudgetLoaded on success', () async {
      mockGetCachedBudgets.mockSuccess([]);
      mockGetBudgets.mockSuccess((budgets: tBudgetList, hasMore: false));

      final states = <BudgetState>[];
      final subscription = budgetBloc.stream.listen(states.add);

      budgetBloc.add(const LoadBudgets());

      await Future.delayed(const Duration(milliseconds: 100));

      expect(states, [
        isA<BudgetLoading>(),
        isA<BudgetLoaded>()
            .having((s) => s.budgets.length, 'budgets length', 2)
            .having((s) => s.hasMore, 'hasMore', false)
            .having((s) => s.isOffline, 'isOffline', false),
      ]);

      expect(mockGetBudgets.callCount, 1);
      await subscription.cancel();
    });

    test('emits cached budgets first when available', () async {
      mockGetCachedBudgets.mockSuccess(tBudgetList);
      mockGetBudgets.mockSuccess((budgets: tBudgetList, hasMore: false));

      final states = <BudgetState>[];
      final subscription = budgetBloc.stream.listen(states.add);

      budgetBloc.add(const LoadBudgets());

      await Future.delayed(const Duration(milliseconds: 100));

      expect(states, [
        isA<BudgetLoaded>()
            .having((s) => s.budgets.length, 'budgets length', 2)
            .having((s) => s.isOffline, 'isOffline', true),
        isA<BudgetLoaded>()
            .having((s) => s.budgets.length, 'budgets length', 2)
            .having((s) => s.isOffline, 'isOffline', false),
      ]);

      await subscription.cancel();
    });

    test('emits BudgetError when getBudgets fails and no cache', () async {
      mockGetCachedBudgets.mockSuccess([]);
      mockGetBudgets.mockError(Exception('Network error'));

      final states = <BudgetState>[];
      final subscription = budgetBloc.stream.listen(states.add);

      budgetBloc.add(const LoadBudgets());

      await Future.delayed(const Duration(milliseconds: 100));

      expect(states, [
        isA<BudgetLoading>(),
        isA<BudgetError>().having(
          (e) => e.message,
          'message',
          contains('Failed to load'),
        ),
      ]);

      await subscription.cancel();
    });
  });

  group('BudgetBloc - SearchBudgets', () {
    final tBudgetList = [
      BudgetModel(
        id: '1',
        category: 'Food',
        spent: 100.0,
        limit: 500.0,
        currency: 'USD',
      ),
    ];

    test('updates search query in BudgetLoaded state', () async {
      mockGetCachedBudgets.mockSuccess([]);
      mockGetBudgets.mockSuccess((budgets: tBudgetList, hasMore: false));

      final states = <BudgetState>[];
      final subscription = budgetBloc.stream.listen(states.add);

      budgetBloc.add(const LoadBudgets());

      await Future.delayed(const Duration(milliseconds: 100));

      budgetBloc.add(const SearchBudgets('food'));

      await Future.delayed(const Duration(milliseconds: 50));

      final lastState = states.last;
      expect(lastState, isA<BudgetLoaded>());
      expect((lastState as BudgetLoaded).searchQuery, 'food');

      await subscription.cancel();
    });
  });

  group('BudgetBloc - RefreshBudgets', () {
    final tBudgetList = [
      BudgetModel(
        id: '1',
        category: 'Food',
        spent: 100.0,
        limit: 500.0,
        currency: 'USD',
      ),
    ];

    test('refreshes budgets from remote source', () async {
      mockGetCachedBudgets.mockSuccess(tBudgetList);
      mockGetBudgets.mockSuccess((budgets: tBudgetList, hasMore: false));

      final states = <BudgetState>[];
      final subscription = budgetBloc.stream.listen(states.add);

      budgetBloc.add(const LoadBudgets());

      await Future.delayed(const Duration(milliseconds: 100));

      budgetBloc.add(const RefreshBudgets());

      await Future.delayed(const Duration(milliseconds: 100));

      final lastRefreshedState = states.last;
      expect(lastRefreshedState, isA<BudgetLoaded>());
      expect((lastRefreshedState as BudgetLoaded).isOffline, false);

      await subscription.cancel();
    });

    test('emits error on refresh failure and shows cached data', () async {
      final cachedBudgets = [
        BudgetModel(
          id: '1',
          category: 'Food',
          spent: 100.0,
          limit: 500.0,
          currency: 'USD',
        ),
      ];
      mockGetCachedBudgets.mockSuccess(cachedBudgets);
      mockGetBudgets.mockSuccess((budgets: cachedBudgets, hasMore: false));

      final states = <BudgetState>[];
      final subscription = budgetBloc.stream.listen(states.add);

      budgetBloc.add(const LoadBudgets());

      await Future.delayed(const Duration(milliseconds: 100));

      mockGetBudgets.mockError(Exception('Network error'));

      budgetBloc.add(const RefreshBudgets());

      await Future.delayed(const Duration(milliseconds: 100));

      expect(states, contains(isA<BudgetError>()));

      await subscription.cancel();
    });
  });
}
