import 'dart:math' as math;

import '../models/event.dart';
import '../services/database.dart';

class EventRepository {
  const EventRepository();

  Future<List<Event>> loadEvents({String? status}) {
    return LocalDatabase.getEvents(status: status);
  }

  Future<List<Event>> loadArrangeEvents() {
    return LocalDatabase.getArrangeEvents();
  }

  Future<List<Event>> loadDeletedArrangeEvents() {
    return LocalDatabase.getDeletedArrangeEvents();
  }

  Future<Event?> loadEventById(int id) {
    return LocalDatabase.getEventById(id);
  }

  Future<int> saveEvent(Event event) {
    return LocalDatabase.saveEvent(event);
  }

  Future<void> updateReview(int eventId, String review) {
    return LocalDatabase.updateEventReview(eventId, review);
  }

  Future<void> backfillStepCompletionsFromPomodoroRecords() {
    return LocalDatabase.backfillStepCompletionsFromPomodoroRecords();
  }

  Future<void> softDeleteEvent(int eventId) {
    return LocalDatabase.softDeleteEvent(eventId);
  }

  Future<void> restoreEvent(int eventId) {
    return LocalDatabase.restoreEvent(eventId);
  }

  Future<void> updateQuadrant(int eventId, String? quadrant) {
    return LocalDatabase.updateEventQuadrant(eventId, quadrant);
  }

  Future<void> updateCalendarOrderBatch(
    List<Event> events,
    String date,
    String timeSlot,
  ) {
    return LocalDatabase.updateEventCalendarOrderBatch(events, date, timeSlot);
  }

  Future<void> updatePomodoroStats(int eventId, {required int tomatoCount}) {
    return LocalDatabase.updateEventPomodoroStats(
      eventId,
      tomatoCount: tomatoCount,
    );
  }

  Future<void> markCompleted(
    Event event,
    DateTime completedAt, {
    int? actualMinutes,
    int? tomatoCount,
  }) async {
    final eventId = event.id;
    if (eventId == null) return;

    final completedAtText = completedAt.toIso8601String();
    event.status = 'completed';
    event.completedAt = completedAtText;
    event.actualMinutes = actualMinutes;
    if (tomatoCount != null) {
      event.tomatoCount = math.max(event.tomatoCount, tomatoCount);
    }

    await LocalDatabase.updateEventCompletion(
      eventId,
      completedAtText,
      actualMinutes: actualMinutes,
      tomatoCount: event.tomatoCount,
    );
  }
}
