import '../models/event.dart';

class ArrangeTimeSlot {
  final String start;
  final String end;
  final int rowFlex;

  const ArrangeTimeSlot(this.start, this.end, this.rowFlex);

  String get key => '$start-$end';
}

const arrangeTimeSlots = [
  ArrangeTimeSlot('0:00', '8:00', 5),
  ArrangeTimeSlot('8:00', '11:00', 7),
  ArrangeTimeSlot('11:00', '14:00', 9),
  ArrangeTimeSlot('14:00', '17:00', 9),
  ArrangeTimeSlot('17:00', '20:00', 7),
  ArrangeTimeSlot('20:00', '24:00', 5),
];

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
