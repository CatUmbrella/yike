String formatEventDuration(int totalMinutes) {
  final minutes = totalMinutes < 0 ? 0 : totalMinutes;
  final hours = minutes ~/ 60;
  final restMinutes = minutes % 60;
  return '$hours h $restMinutes m';
}
