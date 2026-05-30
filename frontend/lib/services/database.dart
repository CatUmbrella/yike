import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/event.dart';

class LocalDatabase {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _init();
    await _ensureSchema(_db!);
    return _db!;
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'yike.db'),
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL DEFAULT '',
            summary TEXT DEFAULT '',
            purpose TEXT DEFAULT '',
            status TEXT NOT NULL DEFAULT 'inbox',
            quadrant TEXT,
            scheduled_date TEXT,
            time_slot TEXT,
            calendar_order INTEGER NOT NULL DEFAULT 0,
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
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE events ADD COLUMN summary TEXT DEFAULT ''",
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE events ADD COLUMN calendar_order INTEGER NOT NULL DEFAULT 0",
          );
        }
      },
      onOpen: _ensureSchema,
    );
  }

  static Future<void> _ensureSchema(Database db) async {
    final eventColumns = await db.rawQuery('PRAGMA table_info(events)');
    final names = eventColumns.map((row) => row['name']).toSet();

    if (!names.contains('summary')) {
      await db.execute("ALTER TABLE events ADD COLUMN summary TEXT DEFAULT ''");
    }
    if (!names.contains('calendar_order')) {
      await db.execute(
        "ALTER TABLE events ADD COLUMN calendar_order INTEGER NOT NULL DEFAULT 0",
      );
    }
  }

  static Future<int> saveEvent(Event event) async {
    final db = await database;
    if (event.id != null) {
      await db.update('events', _eventToRow(event),
          where: 'id = ?', whereArgs: [event.id]);
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
    final events = <Event>[];
    for (final row in rows) {
      final stepRows = await db.query(
        'steps',
        where: 'event_id = ?',
        whereArgs: [row['id']],
        orderBy: 'step_order',
      );
      events.add(_rowToEvent(row, stepRows));
    }
    return events;
  }

  static Future<List<Event>> getDeletedEvents() async {
    final db = await database;
    final rows = await db.query(
      'events',
      where: 'deleted_at IS NOT NULL',
      orderBy: 'deleted_at DESC',
    );
    final events = <Event>[];
    for (final row in rows) {
      final stepRows = await db.query(
        'steps',
        where: 'event_id = ?',
        whereArgs: [row['id']],
        orderBy: 'step_order',
      );
      events.add(_rowToEvent(row, stepRows));
    }
    return events;
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
      {
        'deleted_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
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
        'status': e.status,
        'quadrant': e.quadrant,
        'scheduled_date': e.scheduledDate,
        'time_slot': e.timeSlot,
        'calendar_order': e.calendarOrder,
        'created_at': e.createdAt,
        'updated_at': DateTime.now().toIso8601String(),
        'completed_at': e.completedAt,
        'deleted_at': e.deletedAt,
      };

  static Event _rowToEvent(
      Map<String, dynamic> row, List<Map<String, dynamic>> stepRows) {
    return Event(
      id: row['id'] as int,
      title: (row['title'] as String?) ?? "",
      summary: (row['summary'] as String?) ?? "",
      purpose: (row['purpose'] as String?) ?? "",
      status: (row['status'] as String?) ?? "inbox",
      quadrant: row['quadrant'] as String?,
      scheduledDate: row['scheduled_date'] as String?,
      timeSlot: row['time_slot'] as String?,
      calendarOrder: (row['calendar_order'] as int?) ?? 0,
      steps: stepRows
          .map((s) => StepItem(
                stepOrder: (s['step_order'] as int?) ?? 1,
                description: (s['description'] as String?) ?? "",
                estimatedMin: (s['estimated_min'] as int?) ?? 0,
              ))
          .toList(),
      createdAt: (row['created_at'] as String?) ?? "",
      completedAt: row['completed_at'] as String?,
      deletedAt: row['deleted_at'] as String?,
    );
  }
}
