import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/api_models.dart' as api_models;

class TransactionCard extends StatelessWidget {
  final api_models.Transaction transaction;
  final String currencySymbol;
  final String currencyCode;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.currencySymbol,
    required this.currencyCode,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final amountColor = isIncome
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    final iconColor = isIncome
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    final backgroundColor = isIncome
        ? const Color(0xFF10B981).withOpacity(0.1)
        : const Color(0xFFEF4444).withOpacity(0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono de categoría
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(transaction.category.name),
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Información de la transacción
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse(
                                transaction.category.color.substring(1),
                                radix: 16,
                              ) +
                              0xFF000000,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        transaction.category.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(
                            int.parse(
                                  transaction.category.color.substring(1),
                                  radix: 16,
                                ) +
                                0xFF000000,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getPaymentMethodLabel(transaction.paymentMethod),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM yyyy').format(transaction.date),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          // Monto y acciones
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormat.currency(
                  locale: 'es_MX',
                  symbol: currencySymbol,
                  name: currencyCode,
                ).format(transaction.amount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  if (onEdit != null && onDelete != null)
                    const SizedBox(width: 8),
                  if (onDelete != null)
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.delete_rounded,
                          size: 16,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'alimentación':
        return Icons.restaurant_rounded;
      case 'transporte':
        return Icons.directions_car_rounded;
      case 'vivienda':
        return Icons.home_rounded;
      case 'entretenimiento':
        return Icons.movie_rounded;
      case 'salud':
        return Icons.health_and_safety_rounded;
      case 'educación':
        return Icons.school_rounded;
      case 'ropa':
        return Icons.checkroom_rounded;
      case 'salario':
        return Icons.work_rounded;
      case 'freelance':
        return Icons.laptop_rounded;
      case 'inversiones':
        return Icons.trending_up_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Efectivo';
      case 'transfer':
        return 'Transferencia';
      case 'debit':
        return 'Débito';
      case 'credit':
        return 'Crédito';
      default:
        return method;
    }
  }
}
