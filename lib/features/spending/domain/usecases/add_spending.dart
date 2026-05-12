import 'package:wealthpath/features/spending/domain/entities/spending.dart';
import 'package:wealthpath/features/spending/domain/repositories/spending_repository.dart';

class AddSpending {
  final SpendingRepository repository;
  const AddSpending({required this.repository});

  Future<Spending> call({
    required String merchant,
    required double amount,
    required String category,
    String currency = 'USD',
  }) {
    return repository.addSpending(
      merchant: merchant,
      amount: amount,
      category: category,
      currency: currency,
    );
  }
}
