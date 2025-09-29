import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/api_models.dart';

class BudgetAlertWidget extends StatelessWidget {
  final List<Budget> budgets;
  final VoidCallback? onViewBudgets;

  const BudgetAlertWidget({
    super.key,
    required this.budgets,
    this.onViewBudgets,
  });

  @override
  Widget build(BuildContext context) {
    final alerts = _getBudgetAlerts();

    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Alertas de Presupuesto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const Spacer(),
              if (onViewBudgets != null)
                TextButton(
                  onPressed: onViewBudgets,
                  child: const Text('Ver todos'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...alerts.map((alert) => _buildAlertCard(context, alert)),
        ],
      ),
    );
  }

  List<BudgetAlert> _getBudgetAlerts() {
    final alerts = <BudgetAlert>[];
    final now = DateTime.now();

    for (final budget in budgets) {
      final percentage = budget.amount > 0
          ? (budget.spent / budget.amount) * 100
          : 0;
      final remaining = budget.amount - budget.spent;
      final daysLeft = budget.endDate.difference(now).inDays;
      final dailyAverage =
          budget.spent / (now.difference(budget.startDate).inDays + 1);
      final projectedSpent =
          dailyAverage *
          (budget.endDate.difference(budget.startDate).inDays + 1);

      // Alerta de presupuesto excedido
      if (budget.spent > budget.amount) {
        alerts.add(
          BudgetAlert(
            type: AlertType.exceeded,
            budget: budget,
            message:
                'Excediste ${NumberFormat.currency(symbol: '\$').format(budget.spent - budget.amount)} en ${budget.category.name}',
            severity: AlertSeverity.critical,
          ),
        );
      }
      // Alerta de 90% del presupuesto
      else if (percentage >= 90) {
        alerts.add(
          BudgetAlert(
            type: AlertType.warning,
            budget: budget,
            message:
                '¡Cuidado! Has gastado ${percentage.toStringAsFixed(0)}% del presupuesto de ${budget.category.name}',
            severity: AlertSeverity.high,
          ),
        );
      }
      // Alerta de 80% del presupuesto
      else if (percentage >= 80) {
        alerts.add(
          BudgetAlert(
            type: AlertType.warning,
            budget: budget,
            message:
                'Te quedan ${NumberFormat.currency(symbol: '\$').format(remaining)} en ${budget.category.name}',
            severity: AlertSeverity.medium,
          ),
        );
      }
      // Alerta de proyección de exceso
      else if (projectedSpent > budget.amount && daysLeft > 0) {
        alerts.add(
          BudgetAlert(
            type: AlertType.projection,
            budget: budget,
            message:
                'Si sigues gastando así, excederás el presupuesto de ${budget.category.name} en $daysLeft días',
            severity: AlertSeverity.low,
          ),
        );
      }
    }

    // Ordenar por severidad
    alerts.sort((a, b) => b.severity.index.compareTo(a.severity.index));

    return alerts.take(3).toList(); // Mostrar máximo 3 alertas
  }

  Widget _buildAlertCard(BuildContext context, BudgetAlert alert) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (alert.severity) {
      case AlertSeverity.critical:
        backgroundColor = Colors.red[50]!;
        textColor = Colors.red[700]!;
        icon = Icons.error_outline;
        break;
      case AlertSeverity.high:
        backgroundColor = Colors.orange[50]!;
        textColor = Colors.orange[700]!;
        icon = Icons.warning_amber_rounded;
        break;
      case AlertSeverity.medium:
        backgroundColor = Colors.yellow[50]!;
        textColor = Colors.yellow[800]!;
        icon = Icons.info_outline;
        break;
      case AlertSeverity.low:
        backgroundColor = Colors.blue[50]!;
        textColor = Colors.blue[700]!;
        icon = Icons.trending_up;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alert.message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BudgetAlert {
  final AlertType type;
  final Budget budget;
  final String message;
  final AlertSeverity severity;

  BudgetAlert({
    required this.type,
    required this.budget,
    required this.message,
    required this.severity,
  });
}

enum AlertType { exceeded, warning, projection }

enum AlertSeverity { low, medium, high, critical }
