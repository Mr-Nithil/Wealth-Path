import 'package:wealthpath/features/spending/domain/entities/spending.dart';
import 'package:wealthpath/features/spending/domain/repositories/spending_repository.dart';

class GetSpending {
  final SpendingRepository repository;
  const GetSpending({required this.repository});

  Future<({List<Spending> items, double total, bool hasMore})> call({
    required int page,
    int limit = 20,
  }) {
    return repository.getSpending(page: page, limit: limit);
  }
}
