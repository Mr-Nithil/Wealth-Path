import 'package:dio/dio.dart';
import 'package:wealthpath/core/errors/exceptions.dart';
import 'package:wealthpath/core/network/dio_client.dart';
import 'package:wealthpath/features/budget/data/models/budget_model.dart';

abstract class BudgetRemoteDataSource {
  Future<({List<BudgetModel> budgets, bool hasMore})> getBudgets({
    int page = 1,
    int limit = 20,
  });

  Future<BudgetModel> updateBudgetLimit(String id, double newLimit);
}

class BudgetRemoteDataSourceImpl implements BudgetRemoteDataSource {
  final DioClient dioClient;

  const BudgetRemoteDataSourceImpl({required this.dioClient});

  String extractBudgetErrorMessage(DioException e, String fallback) {
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
  Future<({List<BudgetModel> budgets, bool hasMore})> getBudgets({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await dioClient.dio.get(
        '/budgets',
        queryParameters: {'page': page, 'limit': limit},
      );

      final data = response.data as Map<String, dynamic>;
      final budgets = (data['data'] as List)
          .map((e) => BudgetModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final hasMore = data['hasMore'] as bool;

      return (budgets: budgets, hasMore: hasMore);
    } on DioException catch (e) {
      throw ServerException(
        message: extractBudgetErrorMessage(
          e,
          'Failed to fetch budgets. Please try again.',
        ),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: "An unexpected error occurred: $e");
    }
  }

  @override
  Future<BudgetModel> updateBudgetLimit(String id, double newLimit) async {
    try {
      final response = await dioClient.dio.patch(
        '/budgets/$id',
        data: {'limit': newLimit},
      );
      return BudgetModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: extractBudgetErrorMessage(
          e,
          'Failed to update budget limit. Please try again.',
        ),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: "An unexpected error occurred: $e");
    }
  }
}
