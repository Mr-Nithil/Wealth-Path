import 'package:wealthpath/core/errors/exceptions.dart';
import 'package:wealthpath/features/spending/data/datasources/spending_remote_data_source.dart';
import 'package:wealthpath/features/spending/domain/entities/spending.dart';
import 'package:wealthpath/features/spending/domain/repositories/spending_repository.dart';

class SpendingRepositoryImpl implements SpendingRepository {
  final SpendingRemoteDataSource remoteDataSource;

  const SpendingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<({List<Spending> items, double total, bool hasMore})> getSpending({
    required int page,
    int limit = 20,
  }) async {
    try {
      final result = await remoteDataSource.getSpending(
        page: page,
        limit: limit,
      );
      return (
        items: result.items,
        total: result.total,
        hasMore: result.hasMore,
      );
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<Spending> addSpending({
    required String merchant,
    required double amount,
    required String category,
    String currency = 'USD',
  }) async {
    try {
      return await remoteDataSource.addSpending(
        merchant: merchant,
        amount: amount,
        category: category,
        currency: currency,
      );
    } on ServerException {
      rethrow;
    }
  }
}
