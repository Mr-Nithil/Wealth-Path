import '../../domain/entities/spending.dart';

class SpendingModel extends Spending {
  const SpendingModel({
    required super.id,
    required super.merchant,
    required super.amount,
    required super.currency,
    required super.category,
    required super.date,
  });

  factory SpendingModel.fromJson(Map<String, dynamic> json) {
    return SpendingModel(
      id: json['id'] as String,
      merchant: json['merchant'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchant': merchant,
      'amount': amount,
      'currency': currency,
      'category': category,
      'date': date.toIso8601String(),
    };
  }

  factory SpendingModel.optimistic({
    required String tempId,
    required String merchant,
    required double amount,
    required String category,
  }) {
    return SpendingModel(
      id: tempId,
      merchant: merchant,
      amount: amount,
      currency: 'USD',
      category: category,
      date: DateTime.now(),
    );
  }
}
