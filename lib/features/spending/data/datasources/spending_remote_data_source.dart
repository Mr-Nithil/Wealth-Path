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

  String extractSpendingErrorMessage(DioException e, String fallback) {
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;

      final error = data['error'];
      if (error is String && error.isNotEmpty) return error;

      final details = data['details'];
      if (details is List && details.isNotEmpty) {
        return details.whereType<String>().join(', ');
      }
    }

    return e.message ?? fallback;
  }

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
        message: extractSpendingErrorMessage(
          e,
          'Failed to fetch spending records. Please try again.',
        ),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: "An unexpected error occurred: $e");
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
        message: extractSpendingErrorMessage(
          e,
          'Failed to add spending record. Please try again.',
        ),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: "An unexpected error occurred: $e");
    }
  }
}
