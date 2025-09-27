import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class CategoryChart extends StatelessWidget {
  final Map<String, double> categoryData;
  final String title;
  final String currencySymbol;
  final String currencyCode;
  final Color primaryColor;

  const CategoryChart({
    super.key,
    required this.categoryData,
    required this.title,
    required this.currencySymbol,
    required this.currencyCode,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppTheme.getTextPrimaryColor(context),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 48,
              color: AppTheme.getTextSecondaryColor(context),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay datos disponibles',
              style: TextStyle(
                color: AppTheme.getTextSecondaryColor(context),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final sortedData = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = categoryData.values.fold(0.0, (sum, value) => sum + value);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.getTextPrimaryColor(context),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _buildPieChartSections(sortedData, total),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildLegend(context, sortedData, total),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    List<MapEntry<String, double>> data,
    double total,
  ) {
    final colors = [
      primaryColor,
      primaryColor.withOpacity(0.8),
      primaryColor.withOpacity(0.6),
      primaryColor.withOpacity(0.4),
      primaryColor.withOpacity(0.2),
    ];

    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final percentage = (category.value / total) * 100;

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: category.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _buildLegend(
    BuildContext context,
    List<MapEntry<String, double>> data,
    double total,
  ) {
    final colors = [
      primaryColor,
      primaryColor.withOpacity(0.8),
      primaryColor.withOpacity(0.6),
      primaryColor.withOpacity(0.4),
      primaryColor.withOpacity(0.2),
    ];

    return data.take(5).toList().asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category.key,
                style: TextStyle(
                  color: AppTheme.getTextPrimaryColor(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              NumberFormat.currency(
                locale: 'es_MX',
                symbol: currencySymbol,
                name: currencyCode,
              ).format(category.value),
              style: TextStyle(
                color: AppTheme.getTextSecondaryColor(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class CategoryList extends StatelessWidget {
  final Map<String, double> categoryData;
  final String title;
  final String currencySymbol;
  final String currencyCode;
  final Color primaryColor;

  const CategoryList({
    super.key,
    required this.categoryData,
    required this.title,
    required this.currencySymbol,
    required this.currencyCode,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppTheme.getTextPrimaryColor(context),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Icon(
              Icons.list_alt_rounded,
              size: 48,
              color: AppTheme.getTextSecondaryColor(context),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay datos disponibles',
              style: TextStyle(
                color: AppTheme.getTextSecondaryColor(context),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final sortedData = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = categoryData.values.fold(0.0, (sum, value) => sum + value);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.getTextPrimaryColor(context),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedData.map((entry) {
            final percentage = (entry.value / total) * 100;
            final index = sortedData.indexOf(entry);
            final color = primaryColor.withOpacity(1.0 - (index * 0.2));

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            color: AppTheme.getTextPrimaryColor(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: AppTheme.getDividerColor(context),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        NumberFormat.currency(
                          locale: 'es_MX',
                          symbol: currencySymbol,
                          name: currencyCode,
                        ).format(entry.value),
                        style: TextStyle(
                          color: AppTheme.getTextPrimaryColor(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: AppTheme.getTextSecondaryColor(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
