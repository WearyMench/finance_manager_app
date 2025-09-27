import 'package:flutter/material.dart';

class FilterChips extends StatelessWidget {
  final List<FilterOption> options;
  final String? selectedValue;
  final Function(String?) onChanged;
  final bool allowMultiple;

  const FilterChips({
    super.key,
    required this.options,
    this.selectedValue,
    required this.onChanged,
    this.allowMultiple = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) {
          final isSelected = allowMultiple
              ? (selectedValue?.contains(option.value) ?? false)
              : selectedValue == option.value;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(option.label),
              selected: isSelected,
              onSelected: (selected) {
                if (allowMultiple) {
                  // Handle multiple selection logic here
                  onChanged(option.value);
                } else {
                  onChanged(selected ? option.value : null);
                }
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300]!,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class FilterOption {
  final String value;
  final String label;
  final IconData? icon;

  FilterOption({required this.value, required this.label, this.icon});
}

class DateRangeFilter extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?, DateTime?) onChanged;

  const DateRangeFilter({
    super.key,
    this.startDate,
    this.endDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildDateChip(
            context,
            label: 'Desde',
            date: startDate,
            onTap: () => _selectDate(context, true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDateChip(
            context,
            label: 'Hasta',
            date: endDate,
            onTap: () => _selectDate(context, false),
          ),
        ),
        if (startDate != null || endDate != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => onChanged(null, null),
            icon: const Icon(Icons.clear),
            iconSize: 20,
          ),
        ],
      ],
    );
  }

  Widget _buildDateChip(
    BuildContext context, {
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: date != null
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: date != null
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: date != null
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              date != null ? '${date.day}/${date.month}' : label,
              style: TextStyle(
                fontSize: 12,
                color: date != null
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
                fontWeight: date != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (startDate ?? DateTime.now())
          : (endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      if (isStartDate) {
        onChanged(picked, endDate);
      } else {
        onChanged(startDate, picked);
      }
    }
  }
}

class SearchFilter extends StatelessWidget {
  final String? query;
  final Function(String?) onChanged;
  final String hintText;

  const SearchFilter({
    super.key,
    this.query,
    required this.onChanged,
    this.hintText = 'Buscar...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
          suffixIcon: query != null && query!.isNotEmpty
              ? IconButton(
                  onPressed: () => onChanged(null),
                  icon: const Icon(Icons.clear),
                  iconSize: 20,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
