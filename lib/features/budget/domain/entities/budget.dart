import 'package:equatable/equatable.dart';

class Budget extends Equatable {
  final String id;
  final String category;
  final double spent;
  final double limit;
  final String currency;

  Budget({
    required this.id,
    required this.category,
    required this.spent,
    required this.limit,
    required this.currency,
  });

  double get spendPercentage =>
      limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;

  BudgetStatus get status {
    final pct = spendPercentage * 100;
    if (pct >= 90) return BudgetStatus.danger;
    if (pct >= 75) return BudgetStatus.warning;
    return BudgetStatus.normal;
  }

  Budget copyWith({
    String? id,
    String? category,
    double? spent,
    double? limit,
    String? currency,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      spent: spent ?? this.spent,
      limit: limit ?? this.limit,
      currency: currency ?? this.currency,
    );
  }

  @override
  List<Object?> get props => [id, category, spent, limit, currency];
}

enum BudgetStatus { normal, warning, danger }
