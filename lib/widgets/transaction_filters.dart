import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TransactionFilters extends StatelessWidget {
  final String selectedType;
  final String selectedCategory;
  final List<String> categories;
  final Function(String) onTypeChanged;
  final Function(String) onCategoryChanged;
  final Function() onClearFilters;

  const TransactionFilters({
    super.key,
    required this.selectedType,
    required this.selectedCategory,
    required this.categories,
    required this.onTypeChanged,
    required this.onCategoryChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextPrimaryColor(context),
                ),
              ),
              TextButton(
                onPressed: onClearFilters,
                child: Text(
                  'Limpiar',
                  style: TextStyle(
                    color: AppTheme.getPrimaryColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filtro de tipo
          Text(
            'Tipo de transacción',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.getTextSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTypeChip(
                  context,
                  'Gastos',
                  selectedType == 'Gastos',
                  () => onTypeChanged('Gastos'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTypeChip(
                  context,
                  'Ingresos',
                  selectedType == 'Ingresos',
                  () => onTypeChanged('Ingresos'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTypeChip(
                  context,
                  'Ambos',
                  selectedType == 'Ambos',
                  () => onTypeChanged('Ambos'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filtro de categoría
          Text(
            'Categoría',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.getTextSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.getBorderColor(context)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCategory,
                isExpanded: true,
                items: categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) => onCategoryChanged(value!),
                style: TextStyle(
                  color: AppTheme.getTextPrimaryColor(context),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.getPrimaryColor(context)
              : AppTheme.getDividerColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.getPrimaryColor(context)
                : AppTheme.getBorderColor(context),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected
                ? Colors.white
                : AppTheme.getTextSecondaryColor(context),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
