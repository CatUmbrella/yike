part of '../database.dart';

class _DatabaseMigrations {
  static const currentVersion = 9;

  static const templateTableNames = [
    'templates',
    'template_stages',
    'template_stage_events',
    'template_stage_event_steps',
    'template_notices',
    'template_deployments',
    'template_deployment_stage_progress',
    'template_generated_events',
  ];

  static const eventColumnMigrations = [
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

  static const stepColumnMigrations = [
    _ColumnMigration(
      version: 7,
      name: 'completed_at',
      sql: 'ALTER TABLE steps ADD COLUMN completed_at TEXT',
    ),
  ];

  static const pomodoroIdeaColumnMigrations = [
    _ColumnMigration(
      version: 8,
      name: 'inbox_handled',
      sql:
          'ALTER TABLE pomodoro_ideas ADD COLUMN inbox_handled INTEGER NOT NULL DEFAULT 0',
    ),
  ];

  static const tableMigrations = [
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
    _TableMigration(
      version: 9,
      name: 'templates',
      sql: '''
        CREATE TABLE IF NOT EXISTS templates (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL DEFAULT '',
          goal TEXT NOT NULL DEFAULT '',
          source TEXT NOT NULL DEFAULT 'user',
          status TEXT NOT NULL DEFAULT 'draft',
          relation TEXT,
          current_create_step INTEGER NOT NULL DEFAULT 1,
          current_stage_index INTEGER NOT NULL DEFAULT 0,
          create_completed INTEGER NOT NULL DEFAULT 0,
          created_at TEXT,
          updated_at TEXT,
          published_at TEXT
        )
      ''',
    ),
    _TableMigration(
      version: 9,
      name: 'template_stages',
      sql: '''
        CREATE TABLE IF NOT EXISTS template_stages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          template_id INTEGER NOT NULL,
          stage_order INTEGER NOT NULL DEFAULT 1,
          name TEXT NOT NULL DEFAULT '',
          goal TEXT NOT NULL DEFAULT '',
          estimated_minutes INTEGER NOT NULL DEFAULT 0,
          created_at TEXT,
          updated_at TEXT,
          FOREIGN KEY (template_id) REFERENCES templates(id)
        )
      ''',
    ),
    _TableMigration(
      version: 9,
      name: 'template_stage_events',
      sql: '''
        CREATE TABLE IF NOT EXISTS template_stage_events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          template_id INTEGER NOT NULL,
          stage_id INTEGER NOT NULL,
          event_order INTEGER NOT NULL DEFAULT 1,
          title TEXT NOT NULL DEFAULT '',
          purpose TEXT NOT NULL DEFAULT '',
          estimated_minutes INTEGER NOT NULL DEFAULT 0,
          created_at TEXT,
          updated_at TEXT,
          FOREIGN KEY (template_id) REFERENCES templates(id),
          FOREIGN KEY (stage_id) REFERENCES template_stages(id)
        )
      ''',
    ),
    _TableMigration(
      version: 9,
      name: 'template_stage_event_steps',
      sql: '''
        CREATE TABLE IF NOT EXISTS template_stage_event_steps (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          template_event_id INTEGER NOT NULL,
          step_order INTEGER NOT NULL DEFAULT 1,
          description TEXT NOT NULL DEFAULT '',
          estimated_minutes INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (template_event_id) REFERENCES template_stage_events(id)
        )
      ''',
    ),
    _TableMigration(
      version: 9,
      name: 'template_notices',
      sql: '''
        CREATE TABLE IF NOT EXISTS template_notices (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          template_id INTEGER NOT NULL,
          notice_order INTEGER NOT NULL DEFAULT 1,
          content TEXT NOT NULL DEFAULT '',
          FOREIGN KEY (template_id) REFERENCES templates(id)
        )
      ''',
    ),
    _TableMigration(
      version: 9,
      name: 'template_deployments',
      sql: '''
        CREATE TABLE IF NOT EXISTS template_deployments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          template_id INTEGER NOT NULL,
          status TEXT NOT NULL DEFAULT 'not_started',
          active_stage_id INTEGER,
          pause_after_current_stage INTEGER NOT NULL DEFAULT 0,
          deployed_at TEXT,
          enabled_at TEXT,
          completed_at TEXT,
          created_at TEXT,
          updated_at TEXT,
          FOREIGN KEY (template_id) REFERENCES templates(id),
          FOREIGN KEY (active_stage_id) REFERENCES template_stages(id)
        )
      ''',
    ),
    _TableMigration(
      version: 9,
      name: 'template_deployment_stage_progress',
      sql: '''
        CREATE TABLE IF NOT EXISTS template_deployment_stage_progress (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          deployment_id INTEGER NOT NULL,
          stage_id INTEGER NOT NULL,
          status TEXT NOT NULL DEFAULT 'locked',
          completed_event_count INTEGER NOT NULL DEFAULT 0,
          total_event_count INTEGER NOT NULL DEFAULT 0,
          elapsed_minutes INTEGER NOT NULL DEFAULT 0,
          started_at TEXT,
          completed_at TEXT,
          updated_at TEXT,
          UNIQUE(deployment_id, stage_id),
          FOREIGN KEY (deployment_id) REFERENCES template_deployments(id),
          FOREIGN KEY (stage_id) REFERENCES template_stages(id)
        )
      ''',
    ),
    _TableMigration(
      version: 9,
      name: 'template_generated_events',
      sql: '''
        CREATE TABLE IF NOT EXISTS template_generated_events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          deployment_id INTEGER NOT NULL,
          stage_id INTEGER NOT NULL,
          template_event_id INTEGER NOT NULL,
          event_id INTEGER NOT NULL,
          status TEXT NOT NULL DEFAULT 'active',
          created_at TEXT,
          updated_at TEXT,
          UNIQUE(deployment_id, template_event_id, event_id),
          FOREIGN KEY (deployment_id) REFERENCES template_deployments(id),
          FOREIGN KEY (stage_id) REFERENCES template_stages(id),
          FOREIGN KEY (template_event_id) REFERENCES template_stage_events(id),
          FOREIGN KEY (event_id) REFERENCES events(id)
        )
      ''',
    ),
  ];

  static Future<void> create(Database db, int version) async {
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
    for (final migration in tableMigrations) {
      await db.execute(migration.sql);
    }
  }

  static Future<void> upgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    for (final migration in eventColumnMigrations) {
      if (oldVersion < migration.version) {
        await db.execute(migration.sql);
      }
    }
    for (final migration in stepColumnMigrations) {
      if (oldVersion < migration.version) {
        await db.execute(migration.sql);
      }
    }
    for (final migration in tableMigrations) {
      if (oldVersion < migration.version) {
        await db.execute(migration.sql);
      }
    }
    await _DatabaseSchemaHelpers.ensureTableColumns(
      db,
      'pomodoro_ideas',
      pomodoroIdeaColumnMigrations,
    );
    await _DatabaseSchemaHelpers.backfillHandledPomodoroIdeas(db);
  }

  static Future<void> ensureSchema(Database db) async {
    await _DatabaseSchemaHelpers.ensureTableColumns(
      db,
      'events',
      eventColumnMigrations,
    );
    await _DatabaseSchemaHelpers.ensureTableColumns(
      db,
      'steps',
      stepColumnMigrations,
    );

    for (final migration in tableMigrations) {
      await db.execute(migration.sql);
    }

    await _DatabaseSchemaHelpers.ensureTableColumns(
      db,
      'pomodoro_ideas',
      pomodoroIdeaColumnMigrations,
    );
    await _DatabaseSchemaHelpers.backfillHandledPomodoroIdeas(db);
  }
}
