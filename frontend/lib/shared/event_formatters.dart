import '../models/event.dart';

String formatEventDuration(int totalMinutes) {
  final minutes = totalMinutes < 0 ? 0 : totalMinutes;
  final hours = minutes ~/ 60;
  final restMinutes = minutes % 60;
  return '$hours h $restMinutes m';
}

String formatCompactEventDuration(
  int totalMinutes, {
  bool blankWhenZero = false,
}) {
  final minutes = totalMinutes < 0 ? 0 : totalMinutes;
  if (minutes == 0 && blankWhenZero) return '';
  if (minutes < 60) return '${minutes}m';

  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (rest == 0) return '${hours}h';
  return '${hours}h${rest}m';
}

String eventDisplayTitle(
  Event event, {
  String fallback = '(无标题)',
  bool preferSummary = true,
}) {
  final primary = preferSummary ? event.summary.trim() : event.title.trim();
  if (primary.isNotEmpty) return primary;

  final secondary = preferSummary ? event.title.trim() : event.summary.trim();
  if (secondary.isNotEmpty) return secondary;

  return fallback;
}
