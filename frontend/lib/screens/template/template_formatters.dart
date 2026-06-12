String formatTemplateMonth(DateTime value) {
  return '${value.year}年${value.month}月';
}

String formatTemplateDateTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.month}月${value.day}日 $hour:$minute';
}

String formatTemplateDuration(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return '$hours h $rest m';
}
