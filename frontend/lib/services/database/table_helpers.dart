part of '../database.dart';

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

class _DatabaseSchemaHelpers {
  static Future<void> ensureTableColumns(
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

  static Future<void> backfillHandledPomodoroIdeas(Database db) async {
    await db.update('pomodoro_ideas', {
      'inbox_handled': 1,
    }, where: 'added_to_inbox = 1 AND inbox_handled = 0');
  }
}

int? _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _validDateText(Object? value) {
  if (value is! String) return null;
  final text = value.trim();
  if (text.isEmpty || DateTime.tryParse(text) == null) return null;
  return text;
}
