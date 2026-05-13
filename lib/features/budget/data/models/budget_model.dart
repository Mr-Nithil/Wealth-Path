import 'package:hive/hive.dart';
import 'package:wealthpath/core/constants/hive_contants.dart';
import 'package:wealthpath/features/budget/domain/entities/budget.dart';

part 'budget_model.g.dart';

@HiveType(typeId: HiveConstants.budgetModelTypeId)
class BudgetModel extends Budget {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final String category;

  @HiveField(2)
  @override
  final double spent;

  @HiveField(3)
  @override
  final double limit;

  @HiveField(4)
  @override
  final String currency;

  BudgetModel({
    required this.id,
    required this.category,
    required this.spent,
    required this.limit,
    required this.currency,
  }) : super(
         id: id,
         category: category,
         spent: spent,
         limit: limit,
         currency: currency,
       );

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      category: json['category'] as String,
      spent: (json['spent'] as num).toDouble(),
      limit: (json['limit'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
    );
  }

  factory BudgetModel.fromEntity(Budget budget) {
    return BudgetModel(
      id: budget.id,
      category: budget.category,
      spent: budget.spent,
      limit: budget.limit,
      currency: budget.currency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'spent': spent,
      'limit': limit,
      'currency': currency,
    };
  }
}
