import 'dart:math' as math;

import '../models/event.dart';
import '../models/pomodoro_models.dart';
import '../services/database.dart';
import '../shared/event_formatters.dart';
import '../shared/pomodoro_constants.dart';
import 'event_repository.dart';

class PomodoroRepository {
  PomodoroRepository({EventRepository? eventRepository})
    : _eventRepository = eventRepository ?? const EventRepository();

  final EventRepository _eventRepository;

  Future<List<PomodoroHistoryPreviewItem>> loadRecentHistoryPreview() async {
    final snapshots = await _storedSnapshots();
    return snapshots.take(3).map((snapshot) {
      final event = snapshot.event;
      final session = snapshot.session;
      final completedAt = _dateFromText(event.completedAt);
      final displayTime = completedAt ?? session.updatedAt;
      return PomodoroHistoryPreviewItem(
        sessionId: session.id ?? event.id ?? 0,
        eventId: event.id ?? 0,
        title: eventDisplayTitle(event),
        displayTime: displayTime,
        tomatoCount: _sessionTomatoCount(session),
        eventCompleted: completedAt != null,
      );
    }).toList();
  }

  Future<List<Event>> loadCandidateEvents() async {
    final events = await _eventRepository.loadArrangeEvents();
    final candidates = events
        .where(
          (event) => event.status != 'completed' && event.deletedAt == null,
        )
        .toList();
    candidates.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return candidates;
  }

  Future<PomodoroTaskSnapshot?> loadActiveSession() async {
    final sessionRows = await LocalDatabase.getPomodoroSessionRows();
    for (final row in sessionRows) {
      final status = _statusFromText(row['status'] as String?);
      if (status == PomodoroTimerStatus.completed ||
          status == PomodoroTimerStatus.idle) {
        continue;
      }

      final snapshot = await _snapshotFromSessionRow(row);
      if (snapshot == null ||
          _dateFromText(snapshot.event.completedAt) != null) {
        continue;
      }
      return snapshot;
    }
    return null;
  }

  Future<PomodoroTaskSnapshot> createSessionForEvent({
    required int eventId,
    Event? initialEvent,
  }) async {
    final activeSession = await loadActiveSession();
    final activeEventId = activeSession?.event.id;
    if (activeEventId != null && activeEventId != eventId) {
      throw StateError('Another pomodoro session is active.');
    }

    final loadedEvent = await _eventRepository.loadEventById(eventId);
    final event = loadedEvent ?? initialEvent;
    if (event == null) {
      throw StateError('Pomodoro event not found: $eventId');
    }

    final resolvedEventId = event.id ?? eventId;
    final now = DateTime.now();
    final existing = await _loadLatestSnapshotForEvent(resolvedEventId);
    if (existing != null && _dateFromText(event.completedAt) == null) {
      final snapshot = PomodoroTaskSnapshot(
        event: event,
        session: _resumeSession(existing.session, event, now),
        interruptions: existing.interruptions,
        ideas: existing.ideas,
        stepRecords: _mergeStepRecords(event, existing.stepRecords),
      );
      await saveSnapshot(snapshot, includeRecords: true);
      return snapshot;
    }

    var session = PomodoroSession(
      eventId: resolvedEventId,
      startTime: now,
      status: PomodoroTimerStatus.running,
      durationSec: 0,
      plannedMinutesSnapshot: event.totalMinutes,
      tomatoCount: 0,
      createdAt: now,
      updatedAt: now,
    );
    final sessionId = await LocalDatabase.savePomodoroSessionRow(
      _sessionToRow(session),
    );
    session = session.copyWith(id: sessionId);

    final snapshot = PomodoroTaskSnapshot(
      event: event,
      session: session,
      interruptions: const [],
      ideas: const [],
      stepRecords: _stepRecordsFromEvent(event),
    );
    await saveSnapshot(snapshot, includeRecords: true);
    return snapshot;
  }

  Future<List<PomodoroHistorySection>> loadHistory({
    required int year,
    required int month,
    String keyword = '',
  }) async {
    final snapshots = await _storedSnapshots();
    final query = keyword.trim();
    final filtered = snapshots.where((snapshot) {
      final event = snapshot.event;
      final title = eventDisplayTitle(event);
      final date =
          _dateFromText(event.completedAt) ?? snapshot.session.updatedAt;
      return query.isEmpty ||
          title.contains(query) ||
          _dateSearchText(date).contains(query);
    }).toList();

    final items = filtered
        .map((snapshot) {
          final event = snapshot.event;
          final session = snapshot.session;
          final date = _dateFromText(event.completedAt) ?? session.updatedAt;
          return PomodoroHistoryListItem(
            sessionId: session.id ?? event.id ?? 0,
            event: event,
            displayDateTime: date,
            interruptionCount: snapshot.interruptions.length,
            ideaCount: snapshot.ideas.length,
            tomatoCount: _sessionTomatoCount(session),
          );
        })
        .where((item) {
          final date = item.displayDateTime;
          return date.year == year && date.month == month;
        })
        .toList();

    items.sort((a, b) => b.displayDateTime.compareTo(a.displayDateTime));
    return _groupHistory(items, DateTime.now());
  }

  Future<PomodoroHistoryDetail> loadHistoryDetail(
    PomodoroHistoryListItem item,
  ) async {
    final snapshot =
        await _loadSnapshotBySessionId(item.sessionId) ??
        (item.event.id == null
            ? null
            : await _loadLatestSnapshotForEvent(item.event.id!));
    if (snapshot != null) {
      return PomodoroHistoryDetail(
        event: snapshot.event,
        session: snapshot.session,
        interruptions: snapshot.interruptions,
        ideas: snapshot.ideas,
        stepRecords: snapshot.stepRecords,
      );
    }

    final event = item.event.id == null
        ? item.event
        : await _eventRepository.loadEventById(item.event.id!) ?? item.event;
    final now = DateTime.now();
    final session = PomodoroSession(
      id: item.sessionId,
      eventId: event.id ?? item.sessionId,
      startTime: item.displayDateTime,
      endTime: item.completed ? item.displayDateTime : null,
      status: item.completed
          ? PomodoroTimerStatus.completed
          : PomodoroTimerStatus.paused,
      durationSec: event.actualMinutes == null
          ? event.totalMinutes * 60
          : event.actualMinutes! * 60,
      plannedMinutesSnapshot: event.totalMinutes,
      tomatoCount: item.tomatoCount,
      createdAt: item.displayDateTime,
      updatedAt: now,
    );
    return PomodoroHistoryDetail(
      event: event,
      session: session,
      interruptions: const [],
      ideas: const [],
      stepRecords: const [],
    );
  }

  Future<void> saveSnapshot(
    PomodoroTaskSnapshot snapshot, {
    bool includeRecords = false,
    bool saveEvent = false,
  }) async {
    final eventId = snapshot.event.id ?? snapshot.session.eventId;
    final session = _withEffectiveTomatoCount(snapshot.session);
    final sessionId = await LocalDatabase.savePomodoroSessionRow(
      _sessionToRow(session),
    );

    if (includeRecords) {
      await LocalDatabase.replacePomodoroSnapshotRows(
        sessionId: sessionId,
        eventId: eventId,
        interruptions: snapshot.interruptions.map(_interruptionToRow).toList(),
        ideas: snapshot.ideas.map(_ideaToRow).toList(),
        stepRecords: snapshot.stepRecords.map(_stepRecordToRow).toList(),
      );
    }

    final tomatoCount = _sessionTomatoCount(session);
    snapshot.event.tomatoCount = math.max(
      snapshot.event.tomatoCount,
      tomatoCount,
    );
    if (saveEvent) {
      await _eventRepository.saveEvent(snapshot.event);
    } else {
      await _eventRepository.updatePomodoroStats(
        eventId,
        tomatoCount: snapshot.event.tomatoCount,
      );
    }
  }

  Future<void> saveHistoryEventEdit(Event event, {int? sessionId}) async {
    if (event.id == null) return;
    final existing = await _eventRepository.loadEventById(event.id!);
    if (existing != null && sessionId != null) {
      await _writeEditLogs(existing, event, sessionId);
    }
    await _eventRepository.saveEvent(event);
  }

  Future<void> markEventCompleted(
    Event event,
    DateTime completedAt, {
    int? actualMinutes,
    int? tomatoCount,
  }) async {
    await _eventRepository.markCompleted(
      event,
      completedAt,
      actualMinutes: actualMinutes,
      tomatoCount: tomatoCount,
    );
  }

  Future<void> createInboxEventFromIdea(IdeaToInboxDraft draft) async {
    if (!draft.shouldAddToInbox) {
      await LocalDatabase.markPomodoroIdeaInboxDecision(
        sessionId: draft.idea.sessionId,
        content: draft.idea.content,
        createdAt: draft.idea.createdAt.toIso8601String(),
      );
      return;
    }

    final now = DateTime.now().toIso8601String();
    final inboxEvent = Event(
      title: draft.title,
      summary: draft.title,
      purpose: draft.purpose,
      status: 'inbox',
      steps: draft.steps,
      createdAt: now,
    );
    final inboxEventId = await _eventRepository.saveEvent(inboxEvent);
    await LocalDatabase.markPomodoroIdeaInboxDecision(
      sessionId: draft.idea.sessionId,
      content: draft.idea.content,
      createdAt: draft.idea.createdAt.toIso8601String(),
      inboxEventId: inboxEventId,
    );
  }

  Future<PomodoroTaskSnapshot?> _loadLatestSnapshotForEvent(int eventId) async {
    final sessionRow = await LocalDatabase.getLatestPomodoroSessionRowByEventId(
      eventId,
    );
    if (sessionRow == null) return null;
    return _snapshotFromSessionRow(sessionRow);
  }

  Future<PomodoroTaskSnapshot?> _loadSnapshotBySessionId(int sessionId) async {
    final sessionRow = await LocalDatabase.getPomodoroSessionRowById(sessionId);
    if (sessionRow == null) return null;
    return _snapshotFromSessionRow(sessionRow);
  }

  Future<PomodoroTaskSnapshot?> _snapshotFromSessionRow(
    Map<String, dynamic> sessionRow,
  ) async {
    final eventId = _intValue(sessionRow['event_id']);
    final sessionId = _intValue(sessionRow['id']);
    if (eventId == null || sessionId == null) return null;

    final event = await _eventRepository.loadEventById(eventId);
    if (event == null) return null;

    final session = _withCurrentRunningDuration(
      _sessionFromRow(sessionRow),
      DateTime.now(),
    );
    final interruptionRows = await LocalDatabase.getPomodoroInterruptionRows(
      sessionId,
    );
    final ideaRows = await LocalDatabase.getPomodoroIdeaRows(sessionId);
    final stepRows = await LocalDatabase.getPomodoroStepRecordRows(sessionId);
    final stepRecords = stepRows.map(_stepRecordFromRow).toList();

    return PomodoroTaskSnapshot(
      event: event,
      session: session,
      interruptions: interruptionRows.map(_interruptionFromRow).toList(),
      ideas: ideaRows.map(_ideaFromRow).toList(),
      stepRecords: stepRecords.isEmpty
          ? _stepRecordsFromEvent(event)
          : _mergeStepRecords(event, stepRecords),
    );
  }

  Future<List<PomodoroTaskSnapshot>> _storedSnapshots() async {
    final sessionRows = await LocalDatabase.getPomodoroSessionRows();
    final snapshots = <PomodoroTaskSnapshot>[];
    final seenEventIds = <int>{};

    for (final row in sessionRows) {
      final eventId = _intValue(row['event_id']);
      if (eventId == null || seenEventIds.contains(eventId)) continue;
      final snapshot = await _snapshotFromSessionRow(row);
      if (snapshot == null) continue;
      seenEventIds.add(eventId);
      snapshots.add(snapshot);
    }

    snapshots.sort(
      (a, b) => b.session.updatedAt.compareTo(a.session.updatedAt),
    );
    return snapshots;
  }

  Future<void> _writeEditLogs(Event before, Event after, int sessionId) async {
    final eventId = after.id;
    if (eventId == null) return;
    final editedAt = DateTime.now().toIso8601String();

    if (before.purpose != after.purpose) {
      await LocalDatabase.upsertPomodoroEventEditLog(
        eventId: eventId,
        sessionId: sessionId,
        targetType: 'purpose',
        stepOrder: null,
        firstValue: before.purpose,
        latestValue: after.purpose,
        editedAt: editedAt,
      );
    }

    final beforeSteps = {for (final step in before.steps) step.stepOrder: step};
    for (final step in after.steps) {
      final previous = beforeSteps[step.stepOrder];
      if (previous == null) continue;
      if (previous.description != step.description) {
        await LocalDatabase.upsertPomodoroEventEditLog(
          eventId: eventId,
          sessionId: sessionId,
          targetType: 'step_description',
          stepOrder: step.stepOrder,
          firstValue: previous.description,
          latestValue: step.description,
          editedAt: editedAt,
        );
      }
      if (previous.estimatedMin != step.estimatedMin) {
        await LocalDatabase.upsertPomodoroEventEditLog(
          eventId: eventId,
          sessionId: sessionId,
          targetType: 'step_estimated_min',
          stepOrder: step.stepOrder,
          firstValue: previous.estimatedMin.toString(),
          latestValue: step.estimatedMin.toString(),
          editedAt: editedAt,
        );
      }
    }
  }

  static List<PomodoroStepRecord> _stepRecordsFromEvent(Event event) {
    return event.steps.map((step) {
      return PomodoroStepRecord(
        stepOrder: step.stepOrder,
        descriptionSnapshot: step.description,
        estimatedMinSnapshot: step.estimatedMin,
      );
    }).toList();
  }

  static PomodoroSession _resumeSession(
    PomodoroSession previous,
    Event event,
    DateTime now,
  ) {
    final current = _withCurrentRunningDuration(previous, now);
    return PomodoroSession(
      id: current.id,
      eventId: event.id ?? current.eventId,
      startTime: current.startTime,
      status: PomodoroTimerStatus.running,
      durationSec: current.durationSec,
      plannedMinutesSnapshot: event.totalMinutes,
      tomatoCount: _tomatoCountForDuration(current.durationSec),
      createdAt: current.createdAt,
      updatedAt: now,
    );
  }

  static List<PomodoroStepRecord> _mergeStepRecords(
    Event event,
    List<PomodoroStepRecord> previousRecords,
  ) {
    final previousByOrder = {
      for (final record in previousRecords) record.stepOrder: record,
    };
    return event.steps.map((step) {
      final previous = previousByOrder[step.stepOrder];
      if (previous == null) {
        return PomodoroStepRecord(
          stepOrder: step.stepOrder,
          descriptionSnapshot: step.description,
          estimatedMinSnapshot: step.estimatedMin,
        );
      }
      if (previous.completed) return previous;
      return PomodoroStepRecord(
        stepOrder: step.stepOrder,
        descriptionSnapshot: step.description,
        estimatedMinSnapshot: step.estimatedMin,
        completedAt: previous.completedAt,
        elapsedSec: previous.elapsedSec,
        durationSec: previous.durationSec,
      );
    }).toList();
  }

  static List<PomodoroHistorySection> _groupHistory(
    List<PomodoroHistoryListItem> items,
    DateTime now,
  ) {
    final groups = <String, List<PomodoroHistoryListItem>>{};
    for (final item in items) {
      final key = _sectionTitle(item.displayDateTime, now);
      groups.putIfAbsent(key, () => []).add(item);
    }
    return groups.entries
        .map(
          (entry) =>
              PomodoroHistorySection(title: entry.key, items: entry.value),
        )
        .toList();
  }

  static PomodoroSession _sessionFromRow(Map<String, dynamic> row) {
    final now = DateTime.now();
    return PomodoroSession(
      id: _intValue(row['id']),
      eventId: _intValue(row['event_id']) ?? 0,
      startTime: _dateValue(row['start_time'], fallback: now),
      endTime: _dateValueOrNull(row['end_time']),
      status: _statusFromText(row['status'] as String?),
      durationSec: _intValue(row['duration_sec']) ?? 0,
      plannedMinutesSnapshot: _intValue(row['planned_minutes_snapshot']),
      tomatoCount: _intValue(row['tomato_count']) ?? 0,
      createdAt: _dateValue(row['created_at'], fallback: now),
      updatedAt: _dateValue(row['updated_at'], fallback: now),
    );
  }

  static Map<String, dynamic> _sessionToRow(PomodoroSession session) {
    final effective = _withEffectiveTomatoCount(session);
    return {
      if (effective.id != null) 'id': effective.id,
      'event_id': effective.eventId,
      'start_time': effective.startTime.toIso8601String(),
      'end_time': effective.endTime?.toIso8601String(),
      'status': _statusText(effective.status),
      'duration_sec': effective.durationSec,
      'planned_minutes_snapshot': effective.plannedMinutesSnapshot,
      'tomato_count': effective.tomatoCount,
      'created_at': effective.createdAt.toIso8601String(),
      'updated_at': effective.updatedAt.toIso8601String(),
    };
  }

  static PomodoroInterruption _interruptionFromRow(Map<String, dynamic> row) {
    return PomodoroInterruption(
      id: _intValue(row['id']) ?? 0,
      sessionId: _intValue(row['session_id']) ?? 0,
      reason: (row['reason'] as String?) ?? '',
      elapsedSec: _intValue(row['elapsed_sec']) ?? 0,
      createdAt: _dateValue(row['created_at'], fallback: DateTime.now()),
      resolved: _intValue(row['resolved']) == 1,
    );
  }

  static Map<String, dynamic> _interruptionToRow(PomodoroInterruption item) {
    return {
      'id': item.id,
      'session_id': item.sessionId,
      'reason': item.reason,
      'elapsed_sec': item.elapsedSec,
      'created_at': item.createdAt.toIso8601String(),
      'resolved': item.resolved ? 1 : 0,
      'resolved_at': item.resolved ? item.createdAt.toIso8601String() : null,
    };
  }

  static PomodoroIdea _ideaFromRow(Map<String, dynamic> row) {
    return PomodoroIdea(
      id: _intValue(row['id']) ?? 0,
      sessionId: _intValue(row['session_id']) ?? 0,
      content: (row['content'] as String?) ?? '',
      elapsedSec: _intValue(row['elapsed_sec']) ?? 0,
      createdAt: _dateValue(row['created_at'], fallback: DateTime.now()),
      addedToInbox: _intValue(row['added_to_inbox']) == 1,
      inboxHandled: _intValue(row['inbox_handled']) == 1,
      inboxEventId: _intValue(row['inbox_event_id']),
    );
  }

  static Map<String, dynamic> _ideaToRow(PomodoroIdea item) {
    return {
      'id': item.id,
      'session_id': item.sessionId,
      'content': item.content,
      'elapsed_sec': item.elapsedSec,
      'created_at': item.createdAt.toIso8601String(),
      'added_to_inbox': item.addedToInbox ? 1 : 0,
      'inbox_handled': item.inboxHandled ? 1 : 0,
      'inbox_event_id': item.inboxEventId,
    };
  }

  static PomodoroStepRecord _stepRecordFromRow(Map<String, dynamic> row) {
    return PomodoroStepRecord(
      stepOrder: _intValue(row['step_order']) ?? 1,
      descriptionSnapshot: (row['description_snapshot'] as String?) ?? '',
      estimatedMinSnapshot: _intValue(row['estimated_min_snapshot']) ?? 0,
      completedAt: _dateValueOrNull(row['completed_at']),
      elapsedSec: _intValue(row['elapsed_sec']),
      durationSec: _intValue(row['duration_sec']),
    );
  }

  static Map<String, dynamic> _stepRecordToRow(PomodoroStepRecord record) {
    return {
      'step_order': record.stepOrder,
      'description_snapshot': record.descriptionSnapshot,
      'estimated_min_snapshot': record.estimatedMinSnapshot,
      'completed_at': record.completedAt?.toIso8601String(),
      'elapsed_sec': record.elapsedSec ?? 0,
      'duration_sec': record.durationSec,
    };
  }

  static PomodoroSession _withCurrentRunningDuration(
    PomodoroSession session,
    DateTime now,
  ) {
    if (session.status != PomodoroTimerStatus.running) return session;
    final elapsedSinceUpdate = now.difference(session.updatedAt).inSeconds;
    if (elapsedSinceUpdate <= 0) return session;
    final duration = session.durationSec + elapsedSinceUpdate;
    return session.copyWith(
      durationSec: duration,
      tomatoCount: _tomatoCountForDuration(duration),
      updatedAt: now,
    );
  }

  static PomodoroSession _withEffectiveTomatoCount(PomodoroSession session) {
    final tomatoCount = _tomatoCountForDuration(session.durationSec);
    if (session.tomatoCount == tomatoCount) return session;
    return session.copyWith(tomatoCount: tomatoCount);
  }

  static String _sectionTitle(DateTime date, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    return '${date.day}日';
  }

  static int _sessionTomatoCount(PomodoroSession session) {
    if (session.tomatoCount > 0) return session.tomatoCount;
    return _tomatoCountForDuration(session.durationSec);
  }

  static int _tomatoCountForDuration(int durationSec) {
    return (durationSec ~/ PomodoroConstants.tomatoSeconds).clamp(0, 999);
  }

  static PomodoroTimerStatus _statusFromText(String? value) {
    switch (value) {
      case 'running':
        return PomodoroTimerStatus.running;
      case 'paused':
        return PomodoroTimerStatus.paused;
      case 'completed':
        return PomodoroTimerStatus.completed;
      case 'finishing':
        return PomodoroTimerStatus.finishing;
      default:
        return PomodoroTimerStatus.idle;
    }
  }

  static String _statusText(PomodoroTimerStatus status) {
    switch (status) {
      case PomodoroTimerStatus.running:
        return 'running';
      case PomodoroTimerStatus.paused:
        return 'paused';
      case PomodoroTimerStatus.completed:
        return 'completed';
      case PomodoroTimerStatus.finishing:
        return 'finishing';
      case PomodoroTimerStatus.idle:
        return 'idle';
    }
  }

  static DateTime? _dateFromText(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static DateTime? _dateValueOrNull(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static DateTime _dateValue(Object? value, {required DateTime fallback}) {
    return _dateValueOrNull(value) ?? fallback;
  }

  static int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _dateSearchText(DateTime date) {
    return [
      '${date.year}年${date.month}月${date.day}日',
      '${date.month}月${date.day}日',
      '${date.day}日',
      '${date.year}-${date.month}-${date.day}',
      '${date.month}.${date.day}',
    ].join(' ');
  }
}
