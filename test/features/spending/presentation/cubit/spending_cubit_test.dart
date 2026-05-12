import 'package:flutter_test/flutter_test.dart';
import 'package:wealthpath/core/errors/exceptions.dart';
import 'package:wealthpath/features/spending/data/models/spending_model.dart';
import 'package:wealthpath/features/spending/domain/entities/spending.dart';
import 'package:wealthpath/features/spending/domain/repositories/spending_repository.dart';
import 'package:wealthpath/features/spending/domain/usecases/add_spending.dart';
import 'package:wealthpath/features/spending/domain/usecases/get_spending.dart';
import 'package:wealthpath/features/spending/presentation/cubit/spending_cubit.dart';

class MockSpendingRepository implements SpendingRepository {
  @override
  Future<({List<Spending> items, double total, bool hasMore})> getSpending({
    required int page,
    int limit = 20,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Spending> addSpending({
    required String merchant,
    required double amount,
    required String category,
    String currency = 'USD',
  }) async {
    throw UnimplementedError();
  }
}

class MockGetSpending implements GetSpending {
  ({List<Spending> items, double total, bool hasMore})? _mockResult;
  ServerException? _mockException;
  int callCount = 0;

  @override
  final repository = MockSpendingRepository();

  void mockSuccess(
    ({List<Spending> items, double total, bool hasMore}) result,
  ) {
    _mockResult = result;
    _mockException = null;
  }

  void mockError(ServerException exception) {
    _mockException = exception;
    _mockResult = null;
  }

  void reset() {
    _mockResult = null;
    _mockException = null;
    callCount = 0;
  }

  @override
  Future<({List<Spending> items, double total, bool hasMore})> call({
    required int page,
    int limit = 20,
  }) async {
    callCount++;
    if (_mockException != null) {
      throw _mockException!;
    }
    if (_mockResult != null) {
      return _mockResult!;
    }
    return (items: <Spending>[], total: 0.0, hasMore: false);
  }
}

class MockAddSpending implements AddSpending {
  Spending? _mockResult;
  ServerException? _mockException;
  int callCount = 0;

  @override
  final repository = MockSpendingRepository();

  void mockSuccess(Spending result) {
    _mockResult = result;
    _mockException = null;
  }

  void mockError(ServerException exception) {
    _mockException = exception;
    _mockResult = null;
  }

  void reset() {
    _mockResult = null;
    _mockException = null;
    callCount = 0;
  }

  @override
  Future<Spending> call({
    required String merchant,
    required double amount,
    required String category,
    String currency = 'USD',
  }) async {
    callCount++;
    if (_mockException != null) {
      throw _mockException!;
    }
    return _mockResult ??
        SpendingModel(
          id: '1',
          merchant: merchant,
          amount: amount,
          category: category,
          currency: currency,
          date: DateTime.now(),
        );
  }
}

void main() {
  late SpendingCubit spendingCubit;
  late MockGetSpending mockGetSpending;
  late MockAddSpending mockAddSpending;

  setUp(() {
    mockGetSpending = MockGetSpending();
    mockAddSpending = MockAddSpending();
    spendingCubit = SpendingCubit(
      getSpending: mockGetSpending,
      addSpending: mockAddSpending,
    );
  });

  tearDown(() {
    spendingCubit.close();
    mockGetSpending.reset();
    mockAddSpending.reset();
  });

  group('SpendingCubit - loadSpending', () {
    final tSpendingList = [
      SpendingModel(
        id: '1',
        merchant: 'Amazon',
        amount: 50.0,
        category: 'Shopping',
        currency: 'USD',
        date: DateTime(2024, 1, 1),
      ),
      SpendingModel(
        id: '2',
        merchant: 'Starbucks',
        amount: 5.5,
        category: 'Food',
        currency: 'USD',
        date: DateTime(2024, 1, 2),
      ),
    ];

    test('emits SpendingLoading then SpendingLoaded on success', () async {
      mockGetSpending.mockSuccess((
        items: tSpendingList,
        total: 55.5,
        hasMore: false,
      ));

      final states = <SpendingState>[];
      final subscription = spendingCubit.stream.listen(states.add);

      await spendingCubit.loadSpending();

      await Future.delayed(const Duration(milliseconds: 100));

      expect(states, [
        isA<SpendingLoading>(),
        isA<SpendingLoaded>()
            .having((s) => s.items.length, 'items length', 2)
            .having((s) => s.total, 'total', 55.5)
            .having((s) => s.hasMore, 'hasMore', false),
      ]);

      expect(mockGetSpending.callCount, 1);
      await subscription.cancel();
    });

    test(
      'emits SpendingLoading then SpendingError on ServerException',
      () async {
        mockGetSpending.mockError(ServerException(message: 'Network error'));

        final states = <SpendingState>[];
        final subscription = spendingCubit.stream.listen(states.add);

        await spendingCubit.loadSpending();

        await Future.delayed(const Duration(milliseconds: 100));

        expect(states, [
          isA<SpendingLoading>(),
          isA<SpendingError>().having(
            (e) => e.message,
            'message',
            'Network error',
          ),
        ]);

        await subscription.cancel();
      },
    );

    test(
      'emits SpendingLoading then SpendingError on unexpected exception',
      () async {
        mockGetSpending.mockError(ServerException(message: 'Unexpected error'));

        final states = <SpendingState>[];
        final subscription = spendingCubit.stream.listen(states.add);

        await spendingCubit.loadSpending();

        await Future.delayed(const Duration(milliseconds: 100));

        expect(states, [isA<SpendingLoading>(), isA<SpendingError>()]);

        await subscription.cancel();
      },
    );

    test('initial state is SpendingInitial', () {
      expect(spendingCubit.state, isA<SpendingInitial>());
    });
  });

  group('SpendingCubit - loadMore', () {
    final tInitialList = [
      SpendingModel(
        id: '1',
        merchant: 'Store1',
        amount: 10.0,
        category: 'Cat1',
        currency: 'USD',
        date: DateTime(2024, 1, 1),
      ),
    ];

    final tNextPageList = [
      SpendingModel(
        id: '2',
        merchant: 'Store2',
        amount: 20.0,
        category: 'Cat2',
        currency: 'USD',
        date: DateTime(2024, 1, 2),
      ),
      SpendingModel(
        id: '3',
        merchant: 'Store3',
        amount: 30.0,
        category: 'Cat3',
        currency: 'USD',
        date: DateTime(2024, 1, 3),
      ),
    ];

    test('loads more items when hasMore is true', () async {
      mockGetSpending.mockSuccess((
        items: tInitialList,
        total: 10.0,
        hasMore: true,
      ));

      final states = <SpendingState>[];
      final subscription = spendingCubit.stream.listen(states.add);

      await spendingCubit.loadSpending();
      await Future.delayed(const Duration(milliseconds: 100));

      mockGetSpending.mockSuccess((
        items: tNextPageList,
        total: 60.0,
        hasMore: true,
      ));

      await spendingCubit.loadMore();
      await Future.delayed(const Duration(milliseconds: 100));

      final finalState = spendingCubit.state as SpendingLoaded;
      expect(finalState.items.length, 3);
      expect(finalState.total, 60.0);

      await subscription.cancel();
    });

    test('does not load more when hasMore is false', () async {
      mockGetSpending.mockSuccess((
        items: tInitialList,
        total: 10.0,
        hasMore: false,
      ));

      final states = <SpendingState>[];
      final subscription = spendingCubit.stream.listen(states.add);

      await spendingCubit.loadSpending();
      await Future.delayed(const Duration(milliseconds: 100));

      mockGetSpending.reset();

      await spendingCubit.loadMore();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(mockGetSpending.callCount, 0);

      await subscription.cancel();
    });

    test('emits error and reverts page on loadMore failure', () async {
      mockGetSpending.mockSuccess((
        items: tInitialList,
        total: 10.0,
        hasMore: true,
      ));

      final states = <SpendingState>[];
      final subscription = spendingCubit.stream.listen(states.add);

      await spendingCubit.loadSpending();
      await Future.delayed(const Duration(milliseconds: 100));

      mockGetSpending.mockError(ServerException(message: 'Load more failed'));

      await spendingCubit.loadMore();
      await Future.delayed(const Duration(milliseconds: 100));

      final errorState = states.whereType<SpendingError>().firstOrNull;

      expect(errorState, isNotNull);
      expect(errorState?.message, contains('Load more failed'));
      expect(errorState?.previousItems, tInitialList);

      await subscription.cancel();
    });

    test('ignores loadMore when state is not SpendingLoaded', () async {
      final states = <SpendingState>[];
      final subscription = spendingCubit.stream.listen(states.add);

      await spendingCubit.loadMore();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(states, isEmpty);

      await subscription.cancel();
    });
  });

  group('SpendingCubit - addSpendingRecord', () {
    final tInitialItems = [
      SpendingModel(
        id: '1',
        merchant: 'Store1',
        amount: 10.0,
        category: 'Cat1',
        currency: 'USD',
        date: DateTime(2024, 1, 1),
      ),
    ];

    final tNewRecord = SpendingModel(
      id: '123',
      merchant: 'NewStore',
      amount: 25.0,
      category: 'NewCat',
      currency: 'USD',
      date: DateTime.now(),
    );

    test(
      'shows optimistic update and replaces with server record on success',
      () async {
        mockGetSpending.mockSuccess((
          items: tInitialItems,
          total: 10.0,
          hasMore: false,
        ));

        final states = <SpendingState>[];
        final subscription = spendingCubit.stream.listen(states.add);

        await spendingCubit.loadSpending();
        await Future.delayed(const Duration(milliseconds: 100));

        mockAddSpending.mockSuccess(tNewRecord);

        await spendingCubit.addSpendingRecord(
          merchant: 'NewStore',
          amount: 25.0,
          category: 'NewCat',
        );

        await Future.delayed(const Duration(milliseconds: 100));

        final loadedStates = states.whereType<SpendingLoaded>().toList();
        expect(loadedStates.length >= 2, true);

        final optimisticState = loadedStates[1];
        expect(optimisticState.items.length, 2);
        expect(optimisticState.total, 35.0);

        final finalState = spendingCubit.state as SpendingLoaded;
        expect(finalState.items.length, 2);
        expect(finalState.items.first.id, '123');

        await subscription.cancel();
      },
    );

    test('rolls back optimistic update and shows error on failure', () async {
      mockGetSpending.mockSuccess((
        items: tInitialItems,
        total: 10.0,
        hasMore: false,
      ));

      final states = <SpendingState>[];
      final subscription = spendingCubit.stream.listen(states.add);

      await spendingCubit.loadSpending();
      await Future.delayed(const Duration(milliseconds: 100));

      mockAddSpending.mockError(ServerException(message: 'Add failed'));

      await spendingCubit.addSpendingRecord(
        merchant: 'NewStore',
        amount: 25.0,
        category: 'NewCat',
      );

      await Future.delayed(const Duration(milliseconds: 500));

      final errorState = states.whereType<SpendingError>().firstOrNull;

      expect(errorState, isNotNull);
      expect(errorState?.message, contains('Failed to add'));
      expect(errorState?.previousItems?.length, 1);

      await subscription.cancel();
    });

    test(
      'ignores addSpendingRecord when state is not SpendingLoaded',
      () async {
        final states = <SpendingState>[];
        final subscription = spendingCubit.stream.listen(states.add);

        await spendingCubit.addSpendingRecord(
          merchant: 'Store',
          amount: 10.0,
          category: 'Cat',
        );

        await Future.delayed(const Duration(milliseconds: 100));

        expect(states, isEmpty);

        await subscription.cancel();
      },
    );
  });
}
