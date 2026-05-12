import 'package:dio/dio.dart';
import 'package:wealthpath/core/errors/exceptions.dart';
import 'package:wealthpath/core/network/dio_client.dart';
import 'package:wealthpath/features/spending/data/models/spending_model.dart';

abstract class SpendingRemoteDataSource {
  Future<({List<SpendingModel> items, double total, bool hasMore})>
  getSpending({required int page, int limit = 20});

  Future<SpendingModel> addSpending({
    required String merchant,
    required double amount,
    required String category,
    String currency = 'USD',
  });
}

class SpendingRemoteDataSourceImpl implements SpendingRemoteDataSource {
  final DioClient dioClient;

  const SpendingRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<({List<SpendingModel> items, double total, bool hasMore})>
  getSpending({required int page, int limit = 20}) async {
    try {
      final response = await dioClient.dio.get(
        '/spending',
        queryParameters: {'page': page, 'limit': limit},
      );

      final data = response.data as Map<String, dynamic>;
      final items = (data['data'] as List)
          .map((e) => SpendingModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final total = (data['total'] as num).toDouble();
      final hasMore = data['hasMore'] as bool;

      return (items: items, total: total, hasMore: hasMore);
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data?['message'] as String? ??
            e.message ??
            'Failed to fetch spending',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<SpendingModel> addSpending({
    required String merchant,
    required double amount,
    required String category,
    String currency = 'USD',
  }) async {
    try {
      final response = await dioClient.dio.post(
        '/spending',
        data: {
          'merchant': merchant,
          'amount': amount,
          'category': category,
          'currency': currency,
        },
      );
      return SpendingModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data?['message'] as String? ??
            e.message ??
            'Failed to add spending',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
