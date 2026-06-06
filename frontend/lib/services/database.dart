import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/event.dart';

class LocalDatabase {
  static const _maxSqlWhereArgs = 900;
  static const _eventColumnMigrations = [
    _ColumnMigration(
      version: 2,
      name: 'summary',
      sql: "ALTER TABLE events ADD COLUMN summary TEXT DEFAULT ''",
    ),
    _ColumnMigration(
      version: 3,
      name: 'calendar_order',
      sql:
          'ALTER TABLE events ADD COLUMN calendar_order INTEGER NOT NULL DEFAULT 0',
    ),
    _ColumnMigration(
      version: 4,
      name: 'total_minutes',
      sql: 'ALTER TABLE events ADD COLUMN total_minutes INTEGER',
    ),
    _ColumnMigration(
      version: 5,
      name: 'review',
      sql: "ALTER TABLE events ADD COLUMN review TEXT DEFAULT ''",
    ),
    _ColumnMigration(
      version: 6,
      name: 'actual_minutes',
      sql: 'ALTER TABLE events ADD COLUMN actual_minutes INTEGER',
    ),
    _ColumnMigration(
      version: 6,
      name: 'tomato_count',
      sql:
          'ALTER TABLE events ADD COLUMN tomato_count INTEGER NOT NULL DEFAULT 0',
    ),
  ];
  static const _stepColumnMigrations = [
    _ColumnMigration(
      version: 7,
      name: 'completed_at',
      sql: 'ALTER TABLE steps ADD COLUMN completed_at TEXT',
    ),
  ];
  static const _pomodoroIdeaColumnMigrations = [
    _ColumnMigration(
      version: 8,
      name: 'inbox_handled',
      sql:
          'ALTER TABLE pomodoro_ideas ADD COLUMN inbox_handled INTEGER NOT NULL DEFAULT 0',
    ),
  ];
  static const _tableMigrations = [
    _TableMigration(
      version: 6,
      name: 'pomodoro_sessions',
      sql: '''
        CREATE TABLE IF NOT EXISTS pomodoro_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id INTEGER NOT NULL,
          start_time TEXT,
          end_time TEXT,
          status TEXT NOT NULL DEFAULT 'running',
          duration_sec INTEGER NOT NULL DEFAULT 0,
          planned_minutes_snapshot INTEGER,
          tomato_count INTEGER NOT NULL DEFAULT 0,
          created_at TEXT,
          updated_at TEXT,
          FOREIGN KEY (event_id) REFERENCES events(id)
        )
      ''',
    ),
    _TableMigration(
      version: 6,
      name: 'pomodoro_interruptions',
      sql: '''
        CREATE TABLE IF NOT EXISTS pomodoro_interruptions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id INTEGER NOT NULL,
          reason TEXT DEFAULT '',
          elapsed_sec INTEGER NOT NULL DEFAULT 0,
          created_at TEXT,
          resolved INTEGER NOT NULL DEFAULT 0,
          resolved_at TEXT,
          FOREIGN KEY (session_id) REFERENCES pomodoro_sessions(id)
        )
      ''',
    ),
    _TableMigration(
      version: 6,
      name: 'pomodoro_ideas',
      sql: '''
        CREATE TABLE IF NOT EXISTS pomodoro_ideas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id INTEGER NOT NULL,
          content TEXT DEFAULT '',
          elapsed_sec INTEGER NOT NULL DEFAULT 0,
          created_at TEXT,
          added_to_inbox INTEGER NOT NULL DEFAULT 0,
          inbox_handled INTEGER NOT NULL DEFAULT 0,
          inbox_event_id INTEGER,
          FOREIGN KEY (session_id) REFERENCES pomodoro_sessions(id)
        )
      ''',
    ),
    _TableMigration(
      version: 6,
      name: 'pomodoro_step_records',
      sql: '''
        CREATE TABLE IF NOT EXISTS pomodoro_step_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id INTEGER NOT NULL,
          event_id INTEGER NOT NULL,
          step_order INTEGER NOT NULL,
          description_snapshot TEXT DEFAULT '',
          estimated_min_snapshot INTEGER DEFAULT 0,
          completed_at TEXT,
          elapsed_sec INTEGER NOT NULL DEFAULT 0,
          duration_sec INTEGER,
          FOREIGN KEY (session_id) REFERENCES pomodoro_sessions(id),
          FOREIGN KEY (event_id) REFERENCES events(id)
        )
      ''',
    ),
    _TableMigration(
      version: 6,
      name: 'pomodoro_event_edit_logs',
      sql: '''
        CREATE TABLE IF NOT EXISTS pomodoro_event_edit_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id INTEGER NOT NULL,
          session_id INTEGER,
          target_type TEXT NOT NULL,
          step_order INTEGER,
          first_value TEXT DEFAULT '',
          latest_value TEXT DEFAULT '',
          first_edited_at TEXT,
          last_edited_at TEXT,
          UNIQUE(event_id, session_id, target_type, step_order),
          FOREIGN KEY (event_id) REFERENCES events(id),
          FOREIGN KEY (session_id) REFERENCES pomodoro_sessions(id)
        )
      ''',
    ),
  ];
  static Database? _db;

  static Future<Database> get database async {
    final current = _db;
    if (current != null) return current;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'yike.db'),
      version: 8,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL DEFAULT '',
            summary TEXT DEFAULT '',
            purpose TEXT DEFAULT '',
            review TEXT DEFAULT '',
            status TEXT NOT NULL DEFAULT 'inbox',
            quadrant TEXT,
            scheduled_date TEXT,
            time_slot TEXT,
            calendar_order INTEGER NOT NULL DEFAULT 0,
            total_minutes INTEGER,
            actual_minutes INTEGER,
            tomato_count INTEGER NOT NULL DEFAULT 0,
            created_at TEXT,
            updated_at TEXT,
            completed_at TEXT,
            deleted_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE steps (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event_id INTEGER NOT NULL,
            step_order INTEGER NOT NULL DEFAULT 1,
            description TEXT DEFAULT '',
            estimated_min INTEGER DEFAULT 0,
            completed_at TEXT,
            FOREIGN KEY (event_id) REFERENCES events(id)
          )
        ''');
        for (final migration in _tableMigrations) {
          await db.execute(migration.sql);
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        for (final migration in _eventColumnMigrations) {
          if (oldVersion < migration.version) {
            await db.execute(migration.sql);
          }
        }
        for (final migration in _stepColumnMigrations) {
          if (oldVersion < migration.version) {
            await db.execute(migration.sql);
          }
        }
        for (final migration in _tableMigrations) {
          if (oldVersion < migration.version) {
            await db.execute(migration.sql);
          }
        }
        await _ensureTableColumns(
          db,
          'pomodoro_ideas',
          _pomodoroIdeaColumnMigrations,
        );
        await _backfillHandledPomodoroIdeas(db);
      },
      onOpen: _ensureSchema,
    );
  }

  static Future<void> _ensureSchema(Database db) async {
    final eventColumns = await db.rawQuery('PRAGMA table_info(events)');
    final names = eventColumns.map((row) => row['name']).toSet();

    for (final migration in _eventColumnMigrations) {
      if (!names.contains(migration.name)) {
        await db.execute(migration.sql);
      }
    }

    final stepColumns = await db.rawQuery('PRAGMA table_info(steps)');
    final stepColumnNames = stepColumns.map((row) => row['name']).toSet();
    for (final migration in _stepColumnMigrations) {
      if (!stepColumnNames.contains(migration.name)) {
        await db.execute(migration.sql);
      }
    }

    for (final migration in _tableMigrations) {
      await db.execute(migration.sql);
    }

    await _ensureTableColumns(
      db,
      'pomodoro_ideas',
      _pomodoroIdeaColumnMigrations,
    );
    await _backfillHandledPomodoroIdeas(db);
  }

  static Future<void> _ensureTableColumns(
    Database db,
    String table,
    List<_ColumnMigration> migrations,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final names = columns.map((row) => row['name']).toSet();
    for (final migration in migrations) {
      if (!names.contains(migration.name)) {
        await db.execute(migration.sql);
      }
    }
  }

  static Future<void> _backfillHandledPomodoroIdeas(Database db) async {
    await db.update('pomodoro_ideas', {
      'inbox_handled': 1,
    }, where: 'added_to_inbox = 1 AND inbox_handled = 0');
  }

  static Future<int> saveEvent(Event event) async {
    final db = await database;
    if (event.id != null) {
      await db.update(
        'events',
        _eventToRow(event),
        where: 'id = ?',
        whereArgs: [event.id],
      );
      await db.delete('steps', where: 'event_id = ?', whereArgs: [event.id]);
    } else {
      event.id = await db.insert('events', _eventToRow(event));
    }
    for (final s in event.steps) {
      await db.insert('steps', {
        'event_id': event.id,
        'step_order': s.stepOrder,
        'description': s.description,
        'estimated_min': s.estimatedMin,
        'completed_at': s.completedAt,
      });
    }
    return event.id!;
  }

  static Future<List<Event>> getArrangeEvents() {
    return _getArrangeEvents(deleted: false);
  }

  static Future<List<Event>> getDeletedArrangeEvents() {
    return _getArrangeEvents(deleted: true);
  }

  static Future<List<Event>> _getArrangeEvents({required bool deleted}) async {
    final db = await database;
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

    final db = await database;
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
    final db = await database;
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
    final db = await database;
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
    final db = await database;
    await db.update(
      'events',
      {'review': review, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  static Future<List<Event>> getEvents({String? status}) async {
    final db = await database;
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
    final db = await database;
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
    final db = await database;
    final rows = await db.query(
      'events',
      where: 'deleted_at IS NOT NULL',
      orderBy: 'deleted_at DESC',
    );
    return _rowsToEvents(db, rows);
  }

  static Future<void> softDeleteEvent(int eventId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'events',
      {'deleted_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  static Future<void> restoreEvent(int eventId) async {
    final db = await database;
    await db.update(
      'events',
      {'deleted_at': null, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  static Future<void> deleteEventPermanently(int eventId) async {
    final db = await database;
    await db.delete('steps', where: 'event_id = ?', whereArgs: [eventId]);
    await db.delete('events', where: 'id = ?', whereArgs: [eventId]);
  }

  static Future<List<Map<String, dynamic>>> getPomodoroSessionRows() async {
    final db = await database;
    return db.query('pomodoro_sessions', orderBy: 'updated_at DESC, id DESC');
  }

  static Future<Map<String, dynamic>?> getPomodoroSessionRowById(
    int sessionId,
  ) async {
    final db = await database;
    final rows = await db.query(
      'pomodoro_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single;
  }

  static Future<Map<String, dynamic>?> getLatestPomodoroSessionRowByEventId(
    int eventId,
  ) async {
    final db = await database;
    final rows = await db.query(
      'pomodoro_sessions',
      where: 'event_id = ?',
      whereArgs: [eventId],
      orderBy: 'updated_at DESC, id DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single;
  }

  static Future<List<Map<String, dynamic>>> getPomodoroInterruptionRows(
    int sessionId,
  ) async {
    final db = await database;
    return db.query(
      'pomodoro_interruptions',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC, id ASC',
    );
  }

  static Future<List<Map<String, dynamic>>> getPomodoroIdeaRows(
    int sessionId,
  ) async {
    final db = await database;
    return db.query(
      'pomodoro_ideas',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC, id ASC',
    );
  }

  static Future<List<Map<String, dynamic>>> getPomodoroStepRecordRows(
    int sessionId,
  ) async {
    final db = await database;
    return db.query(
      'pomodoro_step_records',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'step_order ASC, id ASC',
    );
  }

  static Future<int> savePomodoroSessionRow(
    Map<String, dynamic> sessionRow,
  ) async {
    final db = await database;
    final values = Map<String, dynamic>.from(sessionRow);
    final id = _intValue(values.remove('id'));
    if (id == null) {
      return db.insert('pomodoro_sessions', values);
    }
    await db.update(
      'pomodoro_sessions',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
    return id;
  }

  static Future<void> replacePomodoroSnapshotRows({
    required int sessionId,
    required int eventId,
    required List<Map<String, dynamic>> interruptions,
    required List<Map<String, dynamic>> ideas,
    required List<Map<String, dynamic>> stepRecords,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'pomodoro_interruptions',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      await txn.delete(
        'pomodoro_ideas',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      await txn.delete(
        'pomodoro_step_records',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );

      for (final row in interruptions) {
        final values = Map<String, dynamic>.from(row)
          ..remove('id')
          ..['session_id'] = sessionId;
        await txn.insert('pomodoro_interruptions', values);
      }

      for (final row in ideas) {
        final values = Map<String, dynamic>.from(row)
          ..remove('id')
          ..['session_id'] = sessionId;
        await txn.insert('pomodoro_ideas', values);
      }

      for (final row in stepRecords) {
        final values = Map<String, dynamic>.from(row)
          ..remove('id')
          ..['session_id'] = sessionId
          ..['event_id'] = eventId;
        await txn.insert('pomodoro_step_records', values);
      }
    });
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

    final db = await database;
    await db.update('events', values, where: 'id = ?', whereArgs: [eventId]);
  }

  static Future<void> markPomodoroIdeaInboxDecision({
    required int sessionId,
    required String content,
    required String createdAt,
    int? inboxEventId,
  }) async {
    final db = await database;
    await db.update(
      'pomodoro_ideas',
      {
        'added_to_inbox': inboxEventId == null ? 0 : 1,
        'inbox_handled': 1,
        'inbox_event_id': inboxEventId,
      },
      where: 'session_id = ? AND content = ? AND created_at = ?',
      whereArgs: [sessionId, content, createdAt],
    );
  }

  static Future<void> upsertPomodoroEventEditLog({
    required int eventId,
    required int sessionId,
    required String targetType,
    required int? stepOrder,
    required String firstValue,
    required String latestValue,
    required String editedAt,
  }) async {
    final db = await database;
    final where = stepOrder == null
        ? 'event_id = ? AND session_id = ? AND target_type = ? AND step_order IS NULL'
        : 'event_id = ? AND session_id = ? AND target_type = ? AND step_order = ?';
    final whereArgs = <Object?>[eventId, sessionId, targetType];
    if (stepOrder != null) whereArgs.add(stepOrder);

    final existing = await db.query(
      'pomodoro_event_edit_logs',
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );
    if (existing.isEmpty) {
      await db.insert('pomodoro_event_edit_logs', {
        'event_id': eventId,
        'session_id': sessionId,
        'target_type': targetType,
        'step_order': stepOrder,
        'first_value': firstValue,
        'latest_value': latestValue,
        'first_edited_at': editedAt,
        'last_edited_at': editedAt,
      });
      return;
    }

    await db.update(
      'pomodoro_event_edit_logs',
      {'latest_value': latestValue, 'last_edited_at': editedAt},
      where: 'id = ?',
      whereArgs: [existing.single['id']],
    );
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

  static int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _createdAtFromRow(Map<String, dynamic> row) {
    return _validDateText(row['created_at']) ??
        _validDateText(row['updated_at']) ??
        DateTime.now().toIso8601String();
  }

  static String? _validDateText(Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    if (text.isEmpty || DateTime.tryParse(text) == null) return null;
    return text;
  }
}

class _ColumnMigration {
  final int version;
  final String name;
  final String sql;

  const _ColumnMigration({
    required this.version,
    required this.name,
    required this.sql,
  });
}

class _TableMigration {
  final int version;
  final String name;
  final String sql;

  const _TableMigration({
    required this.version,
    required this.name,
    required this.sql,
  });
}
