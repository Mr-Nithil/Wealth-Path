import 'package:flutter_test/flutter_test.dart';
import 'package:wealthpath/core/errors/exceptions.dart';
import 'package:wealthpath/features/spending/data/datasources/spending_remote_data_source.dart';
import 'package:wealthpath/features/spending/data/models/spending_model.dart';
import 'package:wealthpath/features/spending/data/repositories/spending_repository_impl.dart';
import 'package:wealthpath/features/spending/domain/entities/spending.dart';

class MockSpendingRemoteDataSource implements SpendingRemoteDataSource {
  ({List<SpendingModel> items, double total, bool hasMore})? _mockGetResult;
  SpendingModel? _mockAddResult;
  ServerException? _mockException;

  void mockGetSpendingSuccess(
    ({List<SpendingModel> items, double total, bool hasMore}) result,
  ) {
    _mockGetResult = result;
    _mockException = null;
  }

  void mockAddSpendingSuccess(SpendingModel result) {
    _mockAddResult = result;
    _mockException = null;
  }

  void mockException(ServerException exception) {
    _mockException = exception;
    _mockGetResult = null;
    _mockAddResult = null;
  }

  void reset() {
    _mockGetResult = null;
    _mockAddResult = null;
    _mockException = null;
  }

  @override
  Future<({List<SpendingModel> items, double total, bool hasMore})>
  getSpending({required int page, int limit = 20}) async {
    if (_mockException != null) {
      throw _mockException!;
    }
    return _mockGetResult ??
        (items: <SpendingModel>[], total: 0.0, hasMore: false);
  }

  @override
  Future<SpendingModel> addSpending({
    required String merchant,
    required double amount,
    required String category,
    String currency = 'USD',
  }) async {
    if (_mockException != null) {
      throw _mockException!;
    }
    return _mockAddResult ??
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
  late SpendingRepositoryImpl repository;
  late MockSpendingRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockSpendingRemoteDataSource();
    repository = SpendingRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  group('SpendingRepositoryImpl - getSpending', () {
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

    test('returns correct data when getSpending succeeds', () async {
      mockRemoteDataSource.mockGetSpendingSuccess((
        items: tSpendingList,
        total: 55.5,
        hasMore: false,
      ));

      final result = await repository.getSpending(page: 1, limit: 20);

      expect(result.items, tSpendingList);
      expect(result.total, 55.5);
      expect(result.hasMore, false);
    });

    test('returns paginated data when hasMore is true', () async {
      mockRemoteDataSource.mockGetSpendingSuccess((
        items: tSpendingList,
        total: 100.0,
        hasMore: true,
      ));

      final result = await repository.getSpending(page: 1, limit: 20);

      expect(result.items.length, 2);
      expect(result.hasMore, true);
      expect(result.total, 100.0);
    });

    test('throws ServerException when remote data source fails', () async {
      mockRemoteDataSource.mockException(
        ServerException(message: 'Failed to fetch spending'),
      );

      expect(
        () => repository.getSpending(page: 1, limit: 20),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Failed to fetch spending',
          ),
        ),
      );
    });

    test('throws ServerException with specific status code', () async {
      mockRemoteDataSource.mockException(
        ServerException(message: 'Unauthorized', statusCode: 401),
      );

      expect(
        () => repository.getSpending(page: 1),
        throwsA(
          isA<ServerException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('uses default limit when not provided', () async {
      mockRemoteDataSource.mockGetSpendingSuccess((
        items: tSpendingList,
        total: 55.5,
        hasMore: false,
      ));

      final result = await repository.getSpending(page: 1);

      expect(result.items, tSpendingList);
    });

    test('handles empty response correctly', () async {
      mockRemoteDataSource.mockGetSpendingSuccess((
        items: <SpendingModel>[],
        total: 0.0,
        hasMore: false,
      ));

      final result = await repository.getSpending(page: 1, limit: 20);

      expect(result.items.isEmpty, true);
      expect(result.total, 0.0);
      expect(result.hasMore, false);
    });
  });

  group('SpendingRepositoryImpl - addSpending', () {
    final tNewSpending = SpendingModel(
      id: '123',
      merchant: 'NewStore',
      amount: 25.0,
      category: 'NewCat',
      currency: 'USD',
      date: DateTime.now(),
    );

    test('returns Spending entity when addSpending succeeds', () async {
      mockRemoteDataSource.mockAddSpendingSuccess(tNewSpending);

      final result = await repository.addSpending(
        merchant: 'NewStore',
        amount: 25.0,
        category: 'NewCat',
      );

      expect(result, isA<Spending>());
      expect(result.merchant, 'NewStore');
      expect(result.amount, 25.0);
      expect(result.category, 'NewCat');
    });

    test('uses default currency when not provided', () async {
      mockRemoteDataSource.mockAddSpendingSuccess(tNewSpending);

      final result = await repository.addSpending(
        merchant: 'Store',
        amount: 10.0,
        category: 'Cat',
      );

      expect(result.currency, 'USD');
    });

    test('uses custom currency when provided', () async {
      final tCustomSpending = SpendingModel(
        id: '456',
        merchant: 'Store',
        amount: 10.0,
        category: 'Cat',
        currency: 'EUR',
        date: DateTime.now(),
      );
      mockRemoteDataSource.mockAddSpendingSuccess(tCustomSpending);

      final result = await repository.addSpending(
        merchant: 'Store',
        amount: 10.0,
        category: 'Cat',
        currency: 'EUR',
      );

      expect(result.currency, 'EUR');
    });

    test('throws ServerException when remote data source fails', () async {
      mockRemoteDataSource.mockException(
        ServerException(message: 'Failed to add spending'),
      );

      expect(
        () => repository.addSpending(
          merchant: 'Store',
          amount: 10.0,
          category: 'Cat',
        ),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Failed to add spending',
          ),
        ),
      );
    });

    test('throws ServerException with status code on failure', () async {
      mockRemoteDataSource.mockException(
        ServerException(message: 'Server error', statusCode: 500),
      );

      expect(
        () => repository.addSpending(
          merchant: 'Store',
          amount: 10.0,
          category: 'Cat',
        ),
        throwsA(
          isA<ServerException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('preserves all spending details in response', () async {
      mockRemoteDataSource.mockAddSpendingSuccess(tNewSpending);

      final result = await repository.addSpending(
        merchant: 'NewStore',
        amount: 25.0,
        category: 'NewCat',
        currency: 'USD',
      );

      expect(result.id, tNewSpending.id);
      expect(result.merchant, tNewSpending.merchant);
      expect(result.amount, tNewSpending.amount);
      expect(result.category, tNewSpending.category);
      expect(result.currency, tNewSpending.currency);
    });
  });

  group('SpendingRepositoryImpl - Exception handling', () {
    test(
      'rethrows ServerException from getSpending without modification',
      () async {
        final testException = ServerException(
          message: 'Network error',
          statusCode: 503,
        );
        mockRemoteDataSource.mockException(testException);

        final throwsException = () => repository.getSpending(page: 1);

        expect(
          throwsException,
          throwsA(
            isA<ServerException>()
                .having((e) => e.message, 'message', 'Network error')
                .having((e) => e.statusCode, 'statusCode', 503),
          ),
        );
      },
    );

    test(
      'rethrows ServerException from addSpending without modification',
      () async {
        final testException = ServerException(
          message: 'Authentication failed',
          statusCode: 401,
        );
        mockRemoteDataSource.mockException(testException);

        final throwsException = () => repository.addSpending(
          merchant: 'Store',
          amount: 10.0,
          category: 'Cat',
        );

        expect(
          throwsException,
          throwsA(
            isA<ServerException>()
                .having((e) => e.message, 'message', 'Authentication failed')
                .having((e) => e.statusCode, 'statusCode', 401),
          ),
        );
      },
    );
  });

  group('SpendingRepositoryImpl - Data transformation', () {
    test(
      'correctly transforms SpendingModel to Spending entity in getSpending',
      () async {
        final tModel = SpendingModel(
          id: '1',
          merchant: 'Test',
          amount: 100.0,
          category: 'Cat',
          currency: 'USD',
          date: DateTime(2024, 1, 1),
        );
        mockRemoteDataSource.mockGetSpendingSuccess((
          items: [tModel],
          total: 100.0,
          hasMore: false,
        ));

        final result = await repository.getSpending(page: 1);

        expect(result.items.first, isA<Spending>());
        expect(result.items.first.id, tModel.id);
        expect(result.items.first.merchant, tModel.merchant);
      },
    );

    test('preserves all fields when transforming to record type', () async {
      final tSpendingList = [
        SpendingModel(
          id: '1',
          merchant: 'Store1',
          amount: 50.0,
          category: 'Cat1',
          currency: 'USD',
          date: DateTime(2024, 1, 1),
        ),
      ];
      mockRemoteDataSource.mockGetSpendingSuccess((
        items: tSpendingList,
        total: 50.0,
        hasMore: true,
      ));

      final result = await repository.getSpending(page: 1);

      expect(result.items.isNotEmpty, true);
      expect(result.total, 50.0);
      expect(result.hasMore, true);
    });
  });
}
