part of '../database.dart';

class _EventDao {
  static const _maxSqlWhereArgs = 900;

  static Future<int> saveEvent(Event event) async {
    final db = await _AppDatabase.database;
    final originalId = event.id;
    int? insertedId;

    final savedId = await db.transaction<int>((txn) async {
      if (originalId != null) {
        await txn.update(
          'events',
          _eventToRow(event),
          where: 'id = ?',
          whereArgs: [originalId],
        );
        await txn.delete(
          'steps',
          where: 'event_id = ?',
          whereArgs: [originalId],
        );
      } else {
        final row = _eventToRow(event)..remove('id');
        insertedId = await txn.insert('events', row);
      }

      final eventId = originalId ?? insertedId!;
      for (final s in event.steps) {
        await txn.insert('steps', {
          'event_id': eventId,
          'step_order': s.stepOrder,
          'description': s.description,
          'estimated_min': s.estimatedMin,
          'completed_at': s.completedAt,
        });
      }
      return eventId;
    });

    event.id = savedId;
    return savedId;
  }

  static Future<List<Event>> getArrangeEvents() {
    return _getArrangeEvents(deleted: false);
  }

  static Future<List<Event>> getDeletedArrangeEvents() {
    return _getArrangeEvents(deleted: true);
  }

  static Future<List<Event>> _getArrangeEvents({required bool deleted}) async {
    final db = await _AppDatabase.database;
    final rows = await db.rawQuery('''
      SELECT
        e.id,
        e.title,
        e.summary,
        e.purpose,
        e.review,
        e.status,
        e.quadrant,
        e.scheduled_date,
        e.time_slot,
        e.calendar_order,
        e.total_minutes,
        e.actual_minutes,
        e.tomato_count,
        e.created_at,
        e.updated_at,
        e.completed_at,
        e.deleted_at,
        COALESCE(e.total_minutes, SUM(COALESCE(s.estimated_min, 0)))
          AS display_total_minutes
      FROM events e
      LEFT JOIN steps s ON s.event_id = e.id
      WHERE e.deleted_at IS ${deleted ? 'NOT NULL' : 'NULL'}
      GROUP BY e.id
      ORDER BY ${deleted ? 'e.deleted_at DESC' : 'e.created_at DESC'}
    ''');
    return rows.map(_rowToArrangeEvent).toList();
  }

  static Future<void> updateEventCalendarOrderBatch(
    List<Event> events,
    String date,
    String timeSlot,
  ) async {
    if (events.isEmpty) return;

    final db = await _AppDatabase.database;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      for (var i = 0; i < events.length; i++) {
        final event = events[i];
        final id = event.id;
        if (id == null) continue;

        event.scheduledDate = date;
        event.timeSlot = timeSlot;
        event.calendarOrder = i;
        await txn.update(
          'events',
          {
            'scheduled_date': date,
            'time_slot': timeSlot,
            'status': event.status,
            'calendar_order': i,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });
  }

  static Future<void> updateEventQuadrant(int eventId, String? quadrant) async {
    final db = await _AppDatabase.database;
    await db.update(
      'events',
      {'quadrant': quadrant, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  static Future<void> updateEventCompletion(
    int eventId,
    String completedAt, {
    int? actualMinutes,
    int? tomatoCount,
  }) async {
    final db = await _AppDatabase.database;
    final values = <String, dynamic>{
      'status': 'completed',
      'completed_at': completedAt,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (actualMinutes != null) values['actual_minutes'] = actualMinutes;
    if (tomatoCount != null) values['tomato_count'] = tomatoCount;
    await db.update('events', values, where: 'id = ?', whereArgs: [eventId]);
  }

  static Future<void> updateEventReview(int eventId, String review) async {
    final db = await _AppDatabase.database;
    await db.update(
      'events',
      {'review': review, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  static Future<void> backfillStepCompletionsFromPomodoroRecords() async {
    final db = await _AppDatabase.database;
    await db.rawUpdate('''
      UPDATE steps
      SET completed_at = (
        SELECT r.completed_at
        FROM pomodoro_step_records r
        WHERE r.event_id = steps.event_id
          AND r.step_order = steps.step_order
          AND r.completed_at IS NOT NULL
          AND TRIM(r.completed_at) != ''
        ORDER BY r.completed_at DESC
        LIMIT 1
      )
      WHERE (completed_at IS NULL OR TRIM(completed_at) = '')
        AND EXISTS (
          SELECT 1
          FROM pomodoro_step_records r
          WHERE r.event_id = steps.event_id
            AND r.step_order = steps.step_order
            AND r.completed_at IS NOT NULL
            AND TRIM(r.completed_at) != ''
        )
    ''');
  }

  static Future<List<Event>> getEvents({String? status}) async {
    final db = await _AppDatabase.database;
    var where = 'deleted_at IS NULL';
    var args = <dynamic>[];
    if (status != null) {
      where += ' AND status = ?';
      args.add(status);
    }
    final rows = await db.query(
      'events',
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'created_at DESC',
    );
    return _rowsToEvents(db, rows);
  }

  static Future<Event?> getEventById(int id) async {
    final db = await _AppDatabase.database;
    final rows = await db.query(
      'events',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    final events = await _rowsToEvents(db, rows);
    return events.isEmpty ? null : events.single;
  }

  static Future<List<Event>> getDeletedEvents() async {
    final db = await _AppDatabase.database;
    final rows = await db.query(
      'events',
      where: 'deleted_at IS NOT NULL',
      orderBy: 'deleted_at DESC',
    );
    return _rowsToEvents(db, rows);
  }

  static Future<void> softDeleteEvent(int eventId) async {
    final db = await _AppDatabase.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'events',
      {'deleted_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  static Future<void> restoreEvent(int eventId) async {
    final db = await _AppDatabase.database;
    await db.update(
      'events',
      {'deleted_at': null, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  static Future<void> deleteEventPermanently(int eventId) async {
    final db = await _AppDatabase.database;
    await db.delete('steps', where: 'event_id = ?', whereArgs: [eventId]);
    await db.delete('events', where: 'id = ?', whereArgs: [eventId]);
  }

  static Future<void> updateEventPomodoroStats(
    int eventId, {
    int? actualMinutes,
    int? tomatoCount,
  }) async {
    final values = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (actualMinutes != null) values['actual_minutes'] = actualMinutes;
    if (tomatoCount != null) values['tomato_count'] = tomatoCount;
    if (values.length == 1) return;

    final db = await _AppDatabase.database;
    await db.update('events', values, where: 'id = ?', whereArgs: [eventId]);
  }

  static Map<String, dynamic> _eventToRow(Event e) => {
    if (e.id != null) 'id': e.id,
    'title': e.title,
    'summary': e.summary,
    'purpose': e.purpose,
    'review': e.review,
    'status': e.status,
    'quadrant': e.quadrant,
    'scheduled_date': e.scheduledDate,
    'time_slot': e.timeSlot,
    'calendar_order': e.calendarOrder,
    'total_minutes': e.totalMinutesOverride,
    'actual_minutes': e.actualMinutes,
    'tomato_count': e.tomatoCount,
    'created_at': e.createdAt,
    'updated_at': DateTime.now().toIso8601String(),
    'completed_at': e.completedAt,
    'deleted_at': e.deletedAt,
  };

  static Future<List<Event>> _rowsToEvents(
    Database db,
    List<Map<String, dynamic>> eventRows,
  ) async {
    if (eventRows.isEmpty) return <Event>[];

    final stepRowsByEventId = await _loadStepRowsByEventId(db, eventRows);
    return eventRows.map((row) {
      final eventId = row['id'] as int;
      return _rowToEvent(row, stepRowsByEventId[eventId] ?? const []);
    }).toList();
  }

  static Future<Map<int, List<Map<String, dynamic>>>> _loadStepRowsByEventId(
    Database db,
    List<Map<String, dynamic>> eventRows,
  ) async {
    final eventIds = eventRows.map((row) => row['id'] as int).toList();
    final groupedRows = <int, List<Map<String, dynamic>>>{};

    for (var start = 0; start < eventIds.length; start += _maxSqlWhereArgs) {
      var end = start + _maxSqlWhereArgs;
      if (end > eventIds.length) end = eventIds.length;
      final chunk = eventIds.sublist(start, end);
      final placeholders = List.filled(chunk.length, '?').join(',');
      final stepRows = await db.query(
        'steps',
        where: 'event_id IN ($placeholders)',
        whereArgs: chunk,
        orderBy: 'event_id, step_order',
      );

      for (final row in stepRows) {
        final eventId = row['event_id'] as int;
        groupedRows.putIfAbsent(eventId, () => []).add(row);
      }
    }

    return groupedRows;
  }

  static Event _rowToEvent(
    Map<String, dynamic> row,
    List<Map<String, dynamic>> stepRows,
  ) {
    return Event(
      id: row['id'] as int,
      title: (row['title'] as String?) ?? "",
      summary: (row['summary'] as String?) ?? "",
      purpose: (row['purpose'] as String?) ?? "",
      review: (row['review'] as String?) ?? "",
      status: (row['status'] as String?) ?? "inbox",
      quadrant: row['quadrant'] as String?,
      scheduledDate: row['scheduled_date'] as String?,
      timeSlot: row['time_slot'] as String?,
      calendarOrder: (row['calendar_order'] as int?) ?? 0,
      totalMinutesOverride: row['total_minutes'] as int?,
      actualMinutes: row['actual_minutes'] as int?,
      tomatoCount: (row['tomato_count'] as int?) ?? 0,
      steps: stepRows
          .map(
            (s) => StepItem(
              stepOrder: (s['step_order'] as int?) ?? 1,
              description: (s['description'] as String?) ?? "",
              estimatedMin: (s['estimated_min'] as int?) ?? 0,
              completedAt: s['completed_at'] as String?,
            ),
          )
          .toList(),
      createdAt: _createdAtFromRow(row),
      completedAt: row['completed_at'] as String?,
      deletedAt: row['deleted_at'] as String?,
    );
  }

  static Event _rowToArrangeEvent(Map<String, dynamic> row) {
    final displayMinutes = _intValue(row['display_total_minutes']);
    return Event(
      id: row['id'] as int,
      title: (row['title'] as String?) ?? "",
      summary: (row['summary'] as String?) ?? "",
      purpose: (row['purpose'] as String?) ?? "",
      review: (row['review'] as String?) ?? "",
      status: (row['status'] as String?) ?? "inbox",
      quadrant: row['quadrant'] as String?,
      scheduledDate: row['scheduled_date'] as String?,
      timeSlot: row['time_slot'] as String?,
      calendarOrder: (row['calendar_order'] as int?) ?? 0,
      totalMinutesOverride: displayMinutes != null && displayMinutes > 0
          ? displayMinutes
          : null,
      actualMinutes: row['actual_minutes'] as int?,
      tomatoCount: (row['tomato_count'] as int?) ?? 0,
      steps: const <StepItem>[],
      createdAt: _createdAtFromRow(row),
      completedAt: row['completed_at'] as String?,
      deletedAt: row['deleted_at'] as String?,
    );
  }

  static String _createdAtFromRow(Map<String, dynamic> row) {
    return _validDateText(row['created_at']) ??
        _validDateText(row['updated_at']) ??
        DateTime.now().toIso8601String();
  }
}
