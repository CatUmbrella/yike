part of '../database.dart';

class _TemplateDao {
  static Future<List<TaskTemplate>> getDraftTemplates() async {
    final db = await _AppDatabase.database;
    final rows = await db.query(
      'templates',
      where: 'source = ? AND status = ?',
      whereArgs: ['user', 'draft'],
      orderBy: 'updated_at DESC, id DESC',
    );
    return _templatesFromRows(db, rows);
  }

  static Future<TaskTemplate?> getTemplateById(int templateId) async {
    final db = await _AppDatabase.database;
    final rows = await db.query(
      'templates',
      where: 'id = ?',
      whereArgs: [templateId],
      limit: 1,
    );
    final templates = await _templatesFromRows(db, rows);
    return templates.isEmpty ? null : templates.single;
  }

  static Future<TaskTemplate> saveDraftTemplate(TaskTemplate template) async {
    final db = await _AppDatabase.database;
    final now = DateTime.now();
    final nowText = now.toIso8601String();
    late final int templateId;

    await db.transaction((txn) async {
      final row = _templateToRow(
        template.copyWith(
          source: TemplateSource.user,
          status: TemplateStatus.draft,
          updatedAt: now,
          createdAt: template.id == null ? now : template.createdAt,
        ),
      );

      if (template.id == null) {
        row.remove('id');
        templateId = await txn.insert('templates', row);
      } else {
        templateId = template.id!;
        row['updated_at'] = nowText;
        final updated = await txn.update(
          'templates',
          Map<String, dynamic>.from(row)..remove('id'),
          where: 'id = ?',
          whereArgs: [templateId],
        );
        if (updated == 0) {
          await txn.insert('templates', row);
        }
        await _deleteTemplateChildren(txn, templateId);
      }

      await _insertTemplateChildren(txn, templateId, template);
    });

    final saved = await getTemplateById(templateId);
    return saved ??
        template.copyWith(
          id: templateId,
          source: TemplateSource.user,
          status: TemplateStatus.draft,
          updatedAt: now,
        );
  }

  static Future<void> deleteDraftTemplate(int templateId) async {
    final db = await _AppDatabase.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'templates',
        where: 'id = ? AND source = ? AND status = ?',
        whereArgs: [templateId, 'user', 'draft'],
        limit: 1,
      );
      if (rows.isEmpty) return;

      await _deleteTemplateChildren(txn, templateId);
      await txn.delete('templates', where: 'id = ?', whereArgs: [templateId]);
    });
  }

  static Future<List<TaskTemplate>> _templatesFromRows(
    Database db,
    List<Map<String, dynamic>> templateRows,
  ) async {
    if (templateRows.isEmpty) return const [];

    final result = <TaskTemplate>[];
    for (final row in templateRows) {
      final templateId = row['id'] as int;
      final stages = await _loadStages(db, templateId);
      final notices = await _loadNotices(db, templateId);
      result.add(_templateFromRow(row, stages, notices));
    }
    return result;
  }

  static Future<List<TemplateStage>> _loadStages(
    Database db,
    int templateId,
  ) async {
    final stageRows = await db.query(
      'template_stages',
      where: 'template_id = ?',
      whereArgs: [templateId],
      orderBy: 'stage_order ASC, id ASC',
    );
    final stages = <TemplateStage>[];
    for (final stageRow in stageRows) {
      final stageId = stageRow['id'] as int;
      final events = await _loadStageEvents(db, templateId, stageId);
      stages.add(_stageFromRow(stageRow, events));
    }
    return stages;
  }

  static Future<List<TemplateStageEvent>> _loadStageEvents(
    Database db,
    int templateId,
    int stageId,
  ) async {
    final eventRows = await db.query(
      'template_stage_events',
      where: 'template_id = ? AND stage_id = ?',
      whereArgs: [templateId, stageId],
      orderBy: 'event_order ASC, id ASC',
    );
    final events = <TemplateStageEvent>[];
    for (final eventRow in eventRows) {
      final eventId = eventRow['id'] as int;
      final steps = await _loadStageEventSteps(db, eventId);
      events.add(_eventFromRow(eventRow, steps));
    }
    return events;
  }

  static Future<List<TemplateStageEventStep>> _loadStageEventSteps(
    Database db,
    int templateEventId,
  ) async {
    final rows = await db.query(
      'template_stage_event_steps',
      where: 'template_event_id = ?',
      whereArgs: [templateEventId],
      orderBy: 'step_order ASC, id ASC',
    );
    return rows.map(_stepFromRow).toList();
  }

  static Future<List<TemplateNotice>> _loadNotices(
    Database db,
    int templateId,
  ) async {
    final rows = await db.query(
      'template_notices',
      where: 'template_id = ?',
      whereArgs: [templateId],
      orderBy: 'notice_order ASC, id ASC',
    );
    return rows.map(_noticeFromRow).toList();
  }

  static Future<void> _deleteTemplateChildren(
    Transaction txn,
    int templateId,
  ) async {
    await txn.delete(
      'template_stage_event_steps',
      where:
          'template_event_id IN (SELECT id FROM template_stage_events WHERE template_id = ?)',
      whereArgs: [templateId],
    );
    await txn.delete(
      'template_stage_events',
      where: 'template_id = ?',
      whereArgs: [templateId],
    );
    await txn.delete(
      'template_stages',
      where: 'template_id = ?',
      whereArgs: [templateId],
    );
    await txn.delete(
      'template_notices',
      where: 'template_id = ?',
      whereArgs: [templateId],
    );
  }

  static Future<void> _insertTemplateChildren(
    Transaction txn,
    int templateId,
    TaskTemplate template,
  ) async {
    final nowText = DateTime.now().toIso8601String();
    for (
      var stageIndex = 0;
      stageIndex < template.stages.length;
      stageIndex++
    ) {
      final stage = template.stages[stageIndex];
      final stageId = await txn.insert('template_stages', {
        'template_id': templateId,
        'stage_order': stageIndex + 1,
        'name': stage.name,
        'goal': stage.goal,
        'estimated_minutes': stage.estimatedMinutes,
        'created_at': nowText,
        'updated_at': nowText,
      });

      for (var eventIndex = 0; eventIndex < stage.events.length; eventIndex++) {
        final event = stage.events[eventIndex];
        final eventId = await txn.insert('template_stage_events', {
          'template_id': templateId,
          'stage_id': stageId,
          'event_order': eventIndex + 1,
          'title': event.title,
          'purpose': event.purpose,
          'estimated_minutes': event.estimatedMinutes,
          'created_at': nowText,
          'updated_at': nowText,
        });

        for (var stepIndex = 0; stepIndex < event.steps.length; stepIndex++) {
          final step = event.steps[stepIndex];
          await txn.insert('template_stage_event_steps', {
            'template_event_id': eventId,
            'step_order': stepIndex + 1,
            'description': step.description,
            'estimated_minutes': step.estimatedMinutes,
          });
        }
      }
    }

    for (
      var noticeIndex = 0;
      noticeIndex < template.notices.length;
      noticeIndex++
    ) {
      final notice = template.notices[noticeIndex];
      if (notice.content.trim().isEmpty) continue;
      await txn.insert('template_notices', {
        'template_id': templateId,
        'notice_order': noticeIndex + 1,
        'content': notice.content,
      });
    }
  }

  static Map<String, dynamic> _templateToRow(TaskTemplate template) {
    return {
      if (template.id != null) 'id': template.id,
      'name': template.name,
      'goal': template.goal,
      'source': _sourceToDb(template.source),
      'status': _statusToDb(template.status),
      'relation': _relationToDb(template.relation),
      'current_create_step': template.currentCreateStep,
      'current_stage_index': template.currentStageIndex,
      'create_completed': template.createCompleted ? 1 : 0,
      'created_at': template.createdAt.toIso8601String(),
      'updated_at': template.updatedAt.toIso8601String(),
      'published_at': template.publishedAt?.toIso8601String(),
    };
  }

  static TaskTemplate _templateFromRow(
    Map<String, dynamic> row,
    List<TemplateStage> stages,
    List<TemplateNotice> notices,
  ) {
    return TaskTemplate(
      id: row['id'] as int,
      name: (row['name'] as String?) ?? '',
      goal: (row['goal'] as String?) ?? '',
      source: _sourceFromDb(row['source'] as String?),
      status: _statusFromDb(row['status'] as String?),
      relation: _relationFromDb(row['relation'] as String?),
      currentCreateStep: (row['current_create_step'] as int?) ?? 1,
      currentStageIndex: (row['current_stage_index'] as int?) ?? 0,
      createCompleted: ((row['create_completed'] as int?) ?? 0) == 1,
      stages: stages,
      notices: notices,
      createdAt: _dateFromRowValue(row['created_at']),
      updatedAt: _dateFromRowValue(row['updated_at']),
      publishedAt: _nullableDateFromRowValue(row['published_at']),
    );
  }

  static TemplateStage _stageFromRow(
    Map<String, dynamic> row,
    List<TemplateStageEvent> events,
  ) {
    return TemplateStage(
      id: row['id'] as int,
      stageOrder: (row['stage_order'] as int?) ?? 1,
      name: (row['name'] as String?) ?? '',
      goal: (row['goal'] as String?) ?? '',
      estimatedMinutes: (row['estimated_minutes'] as int?) ?? 0,
      events: events,
    );
  }

  static TemplateStageEvent _eventFromRow(
    Map<String, dynamic> row,
    List<TemplateStageEventStep> steps,
  ) {
    return TemplateStageEvent(
      id: row['id'] as int,
      eventOrder: (row['event_order'] as int?) ?? 1,
      title: (row['title'] as String?) ?? '',
      purpose: (row['purpose'] as String?) ?? '',
      estimatedMinutes: (row['estimated_minutes'] as int?) ?? 0,
      steps: steps,
    );
  }

  static TemplateStageEventStep _stepFromRow(Map<String, dynamic> row) {
    return TemplateStageEventStep(
      id: row['id'] as int,
      stepOrder: (row['step_order'] as int?) ?? 1,
      description: (row['description'] as String?) ?? '',
      estimatedMinutes: (row['estimated_minutes'] as int?) ?? 0,
    );
  }

  static TemplateNotice _noticeFromRow(Map<String, dynamic> row) {
    return TemplateNotice(
      id: row['id'] as int,
      noticeOrder: (row['notice_order'] as int?) ?? 1,
      content: (row['content'] as String?) ?? '',
    );
  }

  static DateTime _dateFromRowValue(Object? value) {
    return DateTime.tryParse((value as String?) ?? '') ?? DateTime.now();
  }

  static DateTime? _nullableDateFromRowValue(Object? value) {
    final text = value as String?;
    if (text == null || text.trim().isEmpty) return null;
    return DateTime.tryParse(text);
  }

  static String _sourceToDb(TemplateSource source) {
    return switch (source) {
      TemplateSource.user => 'user',
      TemplateSource.official => 'official',
      TemplateSource.publicUser => 'public_user',
    };
  }

  static TemplateSource _sourceFromDb(String? value) {
    return switch (value) {
      'official' => TemplateSource.official,
      'public_user' => TemplateSource.publicUser,
      _ => TemplateSource.user,
    };
  }

  static String _statusToDb(TemplateStatus status) {
    return switch (status) {
      TemplateStatus.draft => 'draft',
      TemplateStatus.published => 'published',
      TemplateStatus.archived => 'archived',
    };
  }

  static TemplateStatus _statusFromDb(String? value) {
    return switch (value) {
      'published' => TemplateStatus.published,
      'archived' => TemplateStatus.archived,
      _ => TemplateStatus.draft,
    };
  }

  static String? _relationToDb(TemplateRelation? relation) {
    return switch (relation) {
      TemplateRelation.linear => 'linear',
      TemplateRelation.parallel => 'parallel',
      null => null,
    };
  }

  static TemplateRelation? _relationFromDb(String? value) {
    return switch (value) {
      'linear' => TemplateRelation.linear,
      'parallel' => TemplateRelation.parallel,
      _ => null,
    };
  }
}
