import 'package:flutter/material.dart';
import 'package:wealthpath/features/spending/domain/entities/spending.dart';

class SpendingItemWidget extends StatelessWidget {
  final Spending spending;
  final bool isOptimistic;

  const SpendingItemWidget({
    super.key,
    required this.spending,
    this.isOptimistic = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOptimistic
              ? const Color(0xFF238636).withOpacity(0.5)
              : const Color(0xFF30363D),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _categoryColor(spending.category).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _categoryIcon(spending.category),
              color: _categoryColor(spending.category),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        spending.merchant,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${spending.category} · ${_formatDate(spending.date)}',
                  style: const TextStyle(
                    color: Color(0xFF8B949E),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${spending.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isOptimistic ? const Color(0xFF238636) : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'groceries':
        return Icons.local_grocery_store_outlined;
      case 'streaming' || 'entertainment':
        return Icons.play_circle_outline;
      case 'transport' || 'travel':
        return Icons.directions_car_outlined;
      case 'dining':
        return Icons.restaurant_outlined;
      case 'utilities':
        return Icons.bolt_outlined;
      case 'health':
        return Icons.favorite_outline;
      default:
        return Icons.receipt_outlined;
    }
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'groceries':
        return const Color(0xFF238636);
      case 'streaming' || 'entertainment':
        return const Color(0xFF8957E5);
      case 'transport' || 'travel':
        return const Color(0xFF1F6FEB);
      case 'dining':
        return const Color(0xFFE3B341);
      case 'utilities':
        return const Color(0xFF58A6FF);
      case 'health':
        return const Color(0xFFDA3633);
      default:
        return const Color(0xFF8B949E);
    }
  }
}
