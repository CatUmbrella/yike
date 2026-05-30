import '../../models/event.dart';

DateTime mondayForWeekOffset(int weekOffset) {
  final now = DateTime.now();
  final thisMonday = now.subtract(Duration(days: now.weekday - 1));
  return DateTime(
    thisMonday.year,
    thisMonday.month,
    thisMonday.day,
  ).add(Duration(days: weekOffset * 7));
}

String dateRangeTextForWeekOffset(int weekOffset) {
  final monday = mondayForWeekOffset(weekOffset);
  final sunday = monday.add(const Duration(days: 6));
  return '${monday.month}.${monday.day}-${sunday.month}.${sunday.day}';
}

String dateKey(DateTime day) {
  final year = day.year.toString().padLeft(4, '0');
  final month = day.month.toString().padLeft(2, '0');
  final date = day.day.toString().padLeft(2, '0');
  return '$year-$month-$date';
}

int compareCalendarEvents(Event a, Event b) {
  final order = a.calendarOrder.compareTo(b.calendarOrder);
  if (order != 0) return order;

  final created = a.createdAt.compareTo(b.createdAt);
  if (created != 0) return created;

  return (a.id ?? 0).compareTo(b.id ?? 0);
}

String durationText(int minutes) {
  if (minutes <= 0) return '';
  if (minutes < 60) return '${minutes}m';

  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (rest == 0) return '${hours}h';
  return '${hours}h${rest}m';
}
