import 'package:equatable/equatable.dart';

class Spending extends Equatable {
  final String id;
  final String merchant;
  final double amount;
  final String currency;
  final String category;
  final DateTime date;

  const Spending({
    required this.id,
    required this.merchant,
    required this.amount,
    required this.currency,
    required this.category,
    required this.date,
  });

  @override
  List<Object?> get props => [id, merchant, amount, currency, category, date];
}
