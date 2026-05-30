import 'package:flutter/material.dart';

class CalendarTitle extends StatelessWidget {
  final String title;
  final String dateText;
  final String actionText;
  final VoidCallback onActionTap;

  const CalendarTitle({
    super.key,
    required this.title,
    required this.dateText,
    required this.actionText,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(dateText, style: const TextStyle(fontSize: 10)),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onActionTap,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(actionText, style: const TextStyle(fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }
}
