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
      version: 5,
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
            FOREIGN KEY (event_id) REFERENCES events(id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        for (final migration in _eventColumnMigrations) {
          if (oldVersion < migration.version) {
            await db.execute(migration.sql);
          }
        }
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
      });
    }
    return event.id!;
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
      steps: stepRows
          .map(
            (s) => StepItem(
              stepOrder: (s['step_order'] as int?) ?? 1,
              description: (s['description'] as String?) ?? "",
              estimatedMin: (s['estimated_min'] as int?) ?? 0,
            ),
          )
          .toList(),
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
