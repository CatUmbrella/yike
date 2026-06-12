part of '../database.dart';

class _AppDatabase {
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
      version: _DatabaseMigrations.currentVersion,
      onCreate: _DatabaseMigrations.create,
      onUpgrade: _DatabaseMigrations.upgrade,
      onOpen: _DatabaseMigrations.ensureSchema,
    );
  }
}
