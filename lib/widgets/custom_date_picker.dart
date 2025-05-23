import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:farmacia/utils/app_colors.dart';

class CustomDatePicker extends StatelessWidget {
  final String label;
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool allowFutureDates;

  const CustomDatePicker({
    Key? key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.allowFutureDates = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.withOpacity(0.5),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.withOpacity(0.05),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd/MM/yyyy').format(selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    // Determine the valid date range
    final DateTime now = DateTime.now();
    final DateTime effectiveFirstDate = firstDate ?? DateTime(2000);
    
    // If future dates are not allowed, set lastDate to today
    final DateTime effectiveLastDate = allowFutureDates 
        ? (lastDate ?? DateTime(2100)) 
        : now;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.isAfter(effectiveLastDate) 
          ? effectiveLastDate 
          : (selectedDate.isBefore(effectiveFirstDate) ? effectiveFirstDate : selectedDate),
      firstDate: effectiveFirstDate,
      lastDate: effectiveLastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != selectedDate) {
      onDateSelected(picked);
    }
  }
}
