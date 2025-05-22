import 'package:flutter/material.dart';

class DatePickerModal extends StatelessWidget {
  final DateTime initialDate;

  const DatePickerModal({super.key, required this.initialDate});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '날짜 선택',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: CalendarDatePicker(
                initialDate: initialDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                onDateChanged: (DateTime date) {
                  Navigator.of(context).pop(date);
                },
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
          ],
        ),
      ),
    );
  }
}