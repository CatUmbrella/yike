import '../../shared/event_formatters.dart';

export '../../shared/event_schedule.dart' show compareCalendarEvents, dateKey;

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

String durationText(int minutes) {
  return formatCompactEventDuration(minutes, blankWhenZero: true);
}
