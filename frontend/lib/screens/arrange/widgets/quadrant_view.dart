import 'package:flutter/material.dart';

class QuadrantView extends StatelessWidget {
  const QuadrantView({super.key});

  @override
  Widget build(BuildContext context) {
    const labels = ['重要且紧急', '重要不紧急', '不重要但紧急', '不重要不紧急'];
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      crossAxisCount: 2,
      childAspectRatio: 1.15,
      children: labels.map((label) {
        return Container(
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade600),
          ),
          child: Text(label, style: const TextStyle(fontSize: 13)),
        );
      }).toList(),
    );
  }
}
