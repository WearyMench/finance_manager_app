import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class BalanceCards extends StatelessWidget {
  final double monthlyIncome;
  final double monthlyExpenses;
  final double monthlyBalance;
  final String currencySymbol;
  final String currencyCode;

  const BalanceCards({
    super.key,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.monthlyBalance,
    required this.currencySymbol,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Balance Principal
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.getPrimaryColor(context),
                  AppTheme.getPrimaryColor(context).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.getPrimaryColor(context).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Balance del mes',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  NumberFormat.currency(
                    locale: 'es_MX',
                    symbol: currencySymbol,
                    name: currencyCode,
                  ).format(monthlyBalance),
                  style: TextStyle(
                    color: monthlyBalance >= 0
                        ? AppTheme.getSuccessColor(context)
                        : AppTheme.getErrorColor(context),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Ingresos y Gastos
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context: context,
                  icon: Icons.trending_up_rounded,
                  iconColor: AppTheme.getSuccessColor(context),
                  backgroundColor: AppTheme.getSuccessColor(
                    context,
                  ).withOpacity(0.1),
                  title: 'Ingresos',
                  amount: monthlyIncome,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context: context,
                  icon: Icons.trending_down_rounded,
                  iconColor: AppTheme.getErrorColor(context),
                  backgroundColor: AppTheme.getErrorColor(
                    context,
                  ).withOpacity(0.1),
                  title: 'Gastos',
                  amount: monthlyExpenses,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required double amount,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.getTextSecondaryColor(context),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            NumberFormat.currency(
              locale: 'es_MX',
              symbol: currencySymbol,
              name: currencyCode,
            ).format(amount),
            style: TextStyle(
              color: AppTheme.getTextPrimaryColor(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
