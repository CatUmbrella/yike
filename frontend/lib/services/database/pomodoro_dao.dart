part of '../database.dart';

class _PomodoroDao {
  static Future<List<Map<String, dynamic>>> getSessionRows() async {
    final db = await _AppDatabase.database;
    return db.query('pomodoro_sessions', orderBy: 'updated_at DESC, id DESC');
  }

  static Future<Map<String, dynamic>?> getSessionRowById(int sessionId) async {
    final db = await _AppDatabase.database;
    final rows = await db.query(
      'pomodoro_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single;
  }

  static Future<Map<String, dynamic>?> getLatestSessionRowByEventId(
    int eventId,
  ) async {
    final db = await _AppDatabase.database;
    final rows = await db.query(
      'pomodoro_sessions',
      where: 'event_id = ?',
      whereArgs: [eventId],
      orderBy: 'updated_at DESC, id DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single;
  }

  static Future<List<Map<String, dynamic>>> getInterruptionRows(
    int sessionId,
  ) async {
    final db = await _AppDatabase.database;
    return db.query(
      'pomodoro_interruptions',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC, id ASC',
    );
  }

  static Future<List<Map<String, dynamic>>> getIdeaRows(int sessionId) async {
    final db = await _AppDatabase.database;
    return db.query(
      'pomodoro_ideas',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC, id ASC',
    );
  }

  static Future<List<Map<String, dynamic>>> getStepRecordRows(
    int sessionId,
  ) async {
    final db = await _AppDatabase.database;
    return db.query(
      'pomodoro_step_records',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'step_order ASC, id ASC',
    );
  }

  static Future<int> saveSessionRow(Map<String, dynamic> sessionRow) async {
    final db = await _AppDatabase.database;
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

  static Future<void> replaceSnapshotRows({
    required int sessionId,
    required int eventId,
    required List<Map<String, dynamic>> interruptions,
    required List<Map<String, dynamic>> ideas,
    required List<Map<String, dynamic>> stepRecords,
  }) async {
    final db = await _AppDatabase.database;
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

  static Future<void> markIdeaInboxDecision({
    required int sessionId,
    required String content,
    required String createdAt,
    int? inboxEventId,
  }) async {
    final db = await _AppDatabase.database;
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

  static Future<void> upsertEventEditLog({
    required int eventId,
    required int sessionId,
    required String targetType,
    required int? stepOrder,
    required String firstValue,
    required String latestValue,
    required String editedAt,
  }) async {
    final db = await _AppDatabase.database;
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
}
