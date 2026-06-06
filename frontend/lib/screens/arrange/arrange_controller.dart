import 'package:flutter/foundation.dart';

import '../../models/event.dart';
import '../../services/database.dart';
import 'arrange_constants.dart';
import 'arrange_helpers.dart';
import 'arrange_style.dart';

class ArrangeController extends ChangeNotifier {
  List<Event> _inboxEvents = [];
  Map<String, List<Event>> _calendarEventsByCell = {};
  List<Event> _completedEvents = [];
  List<Event> _deletedEvents = [];
  bool _disposed = false;

  List<Event> get inboxEvents => _inboxEvents;

  Future<void> load() async {
    try {
      final active = await LocalDatabase.getArrangeEvents();
      final deleted = await LocalDatabase.getDeletedArrangeEvents();
      final calendarEvents = active
          .where((e) => e.scheduledDate != null && e.timeSlot != null)
          .toList();

      _inboxEvents = active.where((e) => e.status != 'completed').toList();
      _calendarEventsByCell = _buildCalendarEventIndex(calendarEvents);
      _completedEvents = active.where((e) => e.status == 'completed').toList();
      _deletedEvents = deleted;
    } catch (_) {
      _inboxEvents = [];
      _calendarEventsByCell = {};
      _completedEvents = [];
      _deletedEvents = [];
    }
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  List<Event> eventsForPage(int page) {
    switch (page % 3) {
      case 1:
        return _completedEvents;
      case 2:
        return _deletedEvents;
      default:
        return _inboxEvents;
    }
  }

  List<Event> eventsForCell(DateTime day, ArrangeTimeSlot slot) {
    return _eventsForCellByKey(dateKey(day), slot.key);
  }

  Future<void> markCompleted(Event event) async {
    if (event.id == null) return;
    event.status = 'completed';
    event.completedAt = DateTime.now().toIso8601String();
    await LocalDatabase.updateEventCompletion(event.id!, event.completedAt!);
    await load();
  }

  Future<void> restoreEvent(Event event) async {
    if (event.id == null) return;
    await LocalDatabase.restoreEvent(event.id!);
    await load();
  }

  Future<void> dropEventToCell(
    Event event,
    DateTime day,
    ArrangeTimeSlot slot,
    int insertIndex,
  ) async {
    if (event.id == null) return;
    final targetDate = dateKey(day);
    final targetSlot = slot.key;
    final sourceDate = event.scheduledDate;
    final sourceSlot = event.timeSlot;
    if (sourceDate == targetDate && sourceSlot == targetSlot) return;

    final currentTargetEvents = _eventsForCellByKey(targetDate, targetSlot);
    var targetIndex = insertIndex.clamp(0, currentTargetEvents.length).toInt();

    final targetEvents = currentTargetEvents
        .where((e) => e.id != event.id)
        .toList();
    targetIndex = targetIndex.clamp(0, targetEvents.length).toInt();

    event.scheduledDate = targetDate;
    event.timeSlot = targetSlot;
    event.status = 'arranged';
    targetEvents.insert(targetIndex, event);

    if (sourceDate != null && sourceSlot != null) {
      final sourceEvents = _eventsForCellByKey(
        sourceDate,
        sourceSlot,
      ).where((e) => e.id != event.id).toList();
      await _saveCellOrder(sourceEvents, sourceDate, sourceSlot);
    }

    await _saveCellOrder(targetEvents, targetDate, targetSlot);
    await load();
  }

  Future<void> dropEventToQuadrant(
    Event event,
    ArrangeQuadrantStyle quadrant,
  ) async {
    if (event.id == null) return;
    if (ArrangeQuadrants.sameQuadrant(event.quadrant, quadrant)) return;

    event.quadrant = quadrant.id;
    await LocalDatabase.updateEventQuadrant(event.id!, event.quadrant);
    await load();
  }

  List<Event> _eventsForCellByKey(String date, String timeSlot) {
    return _calendarEventsByCell[_calendarCellKey(date, timeSlot)] ??
        const <Event>[];
  }

  Future<void> _saveCellOrder(
    List<Event> events,
    String date,
    String timeSlot,
  ) async {
    await LocalDatabase.updateEventCalendarOrderBatch(events, date, timeSlot);
  }

  Map<String, List<Event>> _buildCalendarEventIndex(List<Event> events) {
    final indexed = <String, List<Event>>{};

    for (final event in events) {
      final date = event.scheduledDate;
      final timeSlot = event.timeSlot;
      if (date == null || timeSlot == null) continue;
      indexed
          .putIfAbsent(_calendarCellKey(date, timeSlot), () => [])
          .add(event);
    }

    for (final events in indexed.values) {
      events.sort(compareCalendarEvents);
    }
    return indexed;
  }

  String _calendarCellKey(String date, String timeSlot) {
    return '$date|$timeSlot';
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
