import 'package:flutter/material.dart';
import 'package:wealthpath/features/budget/domain/entities/budget.dart';

class CategoryBudgetCard extends StatelessWidget {
  final Budget budget;
  final VoidCallback onEditTap;

  const CategoryBudgetCard({
    super.key,
    required this.budget,
    required this.onEditTap,
  });

  Color _progressColor(BudgetStatus status) => switch (status) {
    BudgetStatus.danger => Colors.red[700]!,
    BudgetStatus.warning => Colors.amber[600]!,
    BudgetStatus.normal => const Color(0xFF238636),
  };

  @override
  Widget build(BuildContext context) {
    final pct = budget.spendPercentage;
    final color = _progressColor(budget.status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                budget.category,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  if (budget.status == BudgetStatus.danger)
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 18,
                    ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: onEditTap,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1F6FEB),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Spent \$${budget.spent.toStringAsFixed(2)} '
            'of \$${budget.limit.toStringAsFixed(2)} budget',
            style: const TextStyle(color: Color(0xFF8B949E), fontSize: 13),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: const Color(0xFF30363D),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(pct * 100).toStringAsFixed(0)}%',
              style: TextStyle(color: color, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
