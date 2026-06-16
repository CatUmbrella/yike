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

  static Future<TaskTemplate> ensureStoredTemplate(
    TaskTemplate template,
  ) async {
    final templateId = template.id;
    if (templateId != null) {
      final existing = await getTemplateById(templateId);
      if (existing != null) return existing;
    }
    return _insertTemplateSnapshot(template);
  }

  static Future<List<TemplateDeployment>> getTemplateDeployments() async {
    final db = await _AppDatabase.database;
    await _syncActiveDeployments(db);

    final rows = await db.query(
      'template_deployments',
      orderBy: 'updated_at DESC, id DESC',
    );
    final deployments = <TemplateDeployment>[];
    for (final row in rows) {
      final templateId = row['template_id'] as int;
      final template = await getTemplateById(templateId);
      if (template == null) continue;
      final progress = await _loadDeploymentProgress(db, row['id'] as int);
      deployments.add(_deploymentFromRow(row, template, progress));
    }
    return deployments;
  }

  static Future<void> createTemplateDeployment(TaskTemplate template) async {
    final stored = await ensureStoredTemplate(template);
    final templateId = stored.id;
    if (templateId == null) return;

    final db = await _AppDatabase.database;
    final nowText = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      final deploymentId = await txn.insert('template_deployments', {
        'template_id': templateId,
        'status': 'not_started',
        'active_stage_id': null,
        'pause_after_current_stage': 0,
        'deployed_at': nowText,
        'enabled_at': null,
        'completed_at': null,
        'created_at': nowText,
        'updated_at': nowText,
      });
      await _ensureDeploymentProgressRows(txn, deploymentId, templateId);
    });
  }

  static Future<void> deleteTemplateDeployment(int deploymentId) async {
    final db = await _AppDatabase.database;
    await db.transaction((txn) async {
      await txn.delete(
        'template_deployment_stage_progress',
        where: 'deployment_id = ?',
        whereArgs: [deploymentId],
      );
      await txn.delete(
        'template_generated_events',
        where: 'deployment_id = ?',
        whereArgs: [deploymentId],
      );
      await txn.delete(
        'template_deployments',
        where: 'id = ?',
        whereArgs: [deploymentId],
      );
    });
  }

  static Future<void> enableTemplateDeployment(int deploymentId) async {
    final db = await _AppDatabase.database;
    await db.transaction((txn) async {
      final deployment = await _deploymentRow(txn, deploymentId);
      if (deployment == null) return;

      final templateId = deployment['template_id'] as int;
      final templateRows = await txn.query(
        'templates',
        where: 'id = ?',
        whereArgs: [templateId],
        limit: 1,
      );
      if (templateRows.isEmpty) return;

      final nowText = DateTime.now().toIso8601String();
      await _ensureDeploymentProgressRows(txn, deploymentId, templateId);
      await txn.update(
        'template_deployments',
        {
          'status': 'active',
          'enabled_at': deployment['enabled_at'] ?? nowText,
          'completed_at': null,
          'updated_at': nowText,
        },
        where: 'id = ?',
        whereArgs: [deploymentId],
      );

      if (_relationFromDb(templateRows.single['relation'] as String?) ==
          TemplateRelation.linear) {
        final firstStage = await _firstStageRow(txn, templateId);
        if (firstStage != null) {
          await _activateDeploymentStage(
            txn,
            deploymentId: deploymentId,
            templateId: templateId,
            stageId: firstStage['id'] as int,
          );
        }
      }
    });
  }

  static Future<void> enableTemplateDeploymentStage(
    int deploymentId,
    int stageId,
  ) async {
    final db = await _AppDatabase.database;
    await db.transaction((txn) async {
      final deployment = await _deploymentRow(txn, deploymentId);
      if (deployment == null) return;
      final templateId = deployment['template_id'] as int;
      await _ensureDeploymentProgressRows(txn, deploymentId, templateId);
      await _activateDeploymentStage(
        txn,
        deploymentId: deploymentId,
        templateId: templateId,
        stageId: stageId,
      );
    });
  }

  static Future<void> resetTemplateDeployment(int deploymentId) async {
    final db = await _AppDatabase.database;
    final nowText = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      final generatedRows = await txn.query(
        'template_generated_events',
        columns: ['event_id'],
        where: 'deployment_id = ?',
        whereArgs: [deploymentId],
      );
      final generatedEventIds = generatedRows
          .map((row) => row['event_id'])
          .whereType<int>()
          .toSet()
          .toList();
      if (generatedEventIds.isNotEmpty) {
        final placeholders = List.filled(
          generatedEventIds.length,
          '?',
        ).join(',');
        await txn.update(
          'events',
          {'deleted_at': nowText, 'updated_at': nowText},
          where: 'id IN ($placeholders) AND deleted_at IS NULL',
          whereArgs: generatedEventIds,
        );
      }

      await txn.update(
        'template_deployments',
        {
          'status': 'not_started',
          'active_stage_id': null,
          'pause_after_current_stage': 0,
          'enabled_at': null,
          'completed_at': null,
          'updated_at': nowText,
        },
        where: 'id = ?',
        whereArgs: [deploymentId],
      );
      await txn.update(
        'template_deployment_stage_progress',
        {
          'status': 'locked',
          'completed_event_count': 0,
          'elapsed_minutes': 0,
          'started_at': null,
          'completed_at': null,
          'updated_at': nowText,
        },
        where: 'deployment_id = ?',
        whereArgs: [deploymentId],
      );
      await txn.delete(
        'template_generated_events',
        where: 'deployment_id = ?',
        whereArgs: [deploymentId],
      );
    });
  }

  static Future<void> pauseTemplateDeployment(int deploymentId) async {
    final db = await _AppDatabase.database;
    final rows = await db.query(
      'template_deployments',
      columns: ['pause_after_current_stage'],
      where: 'id = ?',
      whereArgs: [deploymentId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final current = ((rows.single['pause_after_current_stage'] as int?) ?? 0);
    await db.update(
      'template_deployments',
      {
        'pause_after_current_stage': current == 1 ? 0 : 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [deploymentId],
    );
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

  static Future<TaskTemplate> _insertTemplateSnapshot(
    TaskTemplate template,
  ) async {
    final db = await _AppDatabase.database;
    final now = DateTime.now();
    late final int templateId;

    await db.transaction((txn) async {
      final row = _templateToRow(
        template.copyWith(
          updatedAt: now,
          createdAt: template.id == null ? now : template.createdAt,
        ),
      );
      templateId = await txn.insert('templates', row);
      await _insertTemplateChildren(txn, templateId, template);
    });

    final saved = await getTemplateById(templateId);
    return saved ?? template.copyWith(id: templateId, updatedAt: now);
  }

  static Future<void> _syncActiveDeployments(Database db) async {
    await db.transaction((txn) async {
      final rows = await txn.query(
        'template_deployments',
        columns: ['id'],
        where: 'status = ?',
        whereArgs: ['active'],
      );
      for (final row in rows) {
        await _syncDeployment(txn, row['id'] as int);
      }
    });
  }

  static Future<void> _syncDeployment(
    DatabaseExecutor executor,
    int deploymentId,
  ) async {
    final deployment = await _deploymentRow(executor, deploymentId);
    if (deployment == null || deployment['status'] != 'active') return;

    final templateId = deployment['template_id'] as int;
    await _ensureDeploymentProgressRows(executor, deploymentId, templateId);
    await _refreshDeploymentProgress(executor, deploymentId, templateId);

    final templateRows = await executor.query(
      'templates',
      where: 'id = ?',
      whereArgs: [templateId],
      limit: 1,
    );
    if (templateRows.isEmpty) return;

    if (_relationFromDb(templateRows.single['relation'] as String?) ==
        TemplateRelation.linear) {
      await _advanceLinearDeployment(executor, deploymentId, templateId);
      await _refreshDeploymentProgress(executor, deploymentId, templateId);
    }

    await _completeDeploymentIfReady(executor, deploymentId);
  }

  static Future<void> _advanceLinearDeployment(
    DatabaseExecutor executor,
    int deploymentId,
    int templateId,
  ) async {
    final stageRows = await executor.query(
      'template_stages',
      where: 'template_id = ?',
      whereArgs: [templateId],
      orderBy: 'stage_order ASC, id ASC',
    );
    if (stageRows.isEmpty) return;

    for (final stageRow in stageRows) {
      final stageId = stageRow['id'] as int;
      final progress = await _progressRow(executor, deploymentId, stageId);
      if (progress == null) continue;
      if (progress['status'] == 'completed') continue;

      final generated = await _generatedEventCount(
        executor,
        deploymentId,
        stageId,
      );
      if (generated == 0) {
        await _activateDeploymentStage(
          executor,
          deploymentId: deploymentId,
          templateId: templateId,
          stageId: stageId,
        );
      }
      return;
    }
  }

  static Future<void> _completeDeploymentIfReady(
    DatabaseExecutor executor,
    int deploymentId,
  ) async {
    final rows = await executor.query(
      'template_deployment_stage_progress',
      columns: ['completed_event_count', 'total_event_count'],
      where: 'deployment_id = ?',
      whereArgs: [deploymentId],
    );
    final total = rows.fold<int>(
      0,
      (sum, row) => sum + ((row['total_event_count'] as int?) ?? 0),
    );
    final completed = rows.fold<int>(
      0,
      (sum, row) => sum + ((row['completed_event_count'] as int?) ?? 0),
    );
    if (total == 0 || completed < total) return;

    final nowText = DateTime.now().toIso8601String();
    await executor.update(
      'template_deployments',
      {'status': 'completed', 'completed_at': nowText, 'updated_at': nowText},
      where: 'id = ?',
      whereArgs: [deploymentId],
    );
  }

  static Future<void> _ensureDeploymentProgressRows(
    DatabaseExecutor executor,
    int deploymentId,
    int templateId,
  ) async {
    final stageRows = await executor.query(
      'template_stages',
      where: 'template_id = ?',
      whereArgs: [templateId],
      orderBy: 'stage_order ASC, id ASC',
    );
    final nowText = DateTime.now().toIso8601String();
    for (final stageRow in stageRows) {
      final stageId = stageRow['id'] as int;
      final total = await _stageEventCount(executor, stageId);
      await executor.insert(
        'template_deployment_stage_progress',
        {
          'deployment_id': deploymentId,
          'stage_id': stageId,
          'status': 'locked',
          'completed_event_count': 0,
          'total_event_count': total,
          'elapsed_minutes': 0,
          'started_at': null,
          'completed_at': null,
          'updated_at': nowText,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      await executor.update(
        'template_deployment_stage_progress',
        {'total_event_count': total, 'updated_at': nowText},
        where: 'deployment_id = ? AND stage_id = ?',
        whereArgs: [deploymentId, stageId],
      );
    }
  }

  static Future<void> _refreshDeploymentProgress(
    DatabaseExecutor executor,
    int deploymentId,
    int templateId,
  ) async {
    final stageRows = await executor.query(
      'template_stages',
      where: 'template_id = ?',
      whereArgs: [templateId],
      orderBy: 'stage_order ASC, id ASC',
    );
    final nowText = DateTime.now().toIso8601String();
    for (final stageRow in stageRows) {
      final stageId = stageRow['id'] as int;
      final total = await _stageEventCount(executor, stageId);
      final generated = await _generatedEventCount(
        executor,
        deploymentId,
        stageId,
      );
      final completed = await _completedGeneratedEventCount(
        executor,
        deploymentId,
        stageId,
      );
      final current = await _progressRow(executor, deploymentId, stageId);
      final currentStatus = current?['status'] as String? ?? 'locked';
      final status = total > 0 && generated >= total && completed >= total
          ? 'completed'
          : generated > 0
          ? 'in_progress'
          : currentStatus == 'completed'
          ? 'completed'
          : 'locked';
      final completedAt = status == 'completed'
          ? ((current?['completed_at'] as String?) ?? nowText)
          : null;

      await executor.update(
        'template_deployment_stage_progress',
        {
          'status': status,
          'completed_event_count': completed,
          'total_event_count': total,
          'completed_at': completedAt,
          'updated_at': nowText,
        },
        where: 'deployment_id = ? AND stage_id = ?',
        whereArgs: [deploymentId, stageId],
      );
    }
  }

  static Future<void> _activateDeploymentStage(
    DatabaseExecutor executor, {
    required int deploymentId,
    required int templateId,
    required int stageId,
  }) async {
    final nowText = DateTime.now().toIso8601String();
    final eventRows = await executor.query(
      'template_stage_events',
      where: 'template_id = ? AND stage_id = ? AND TRIM(title) != ?',
      whereArgs: [templateId, stageId, ''],
      orderBy: 'event_order ASC, id ASC',
    );

    for (final eventRow in eventRows) {
      final templateEventId = eventRow['id'] as int;
      final existing = await executor.query(
        'template_generated_events',
        where: 'deployment_id = ? AND template_event_id = ?',
        whereArgs: [deploymentId, templateEventId],
        limit: 1,
      );
      if (existing.isNotEmpty) continue;

      final eventId = await executor.insert('events', {
        'title': (eventRow['title'] as String?) ?? '',
        'summary': '',
        'purpose': (eventRow['purpose'] as String?) ?? '',
        'review': '',
        'status': 'inbox',
        'quadrant': null,
        'scheduled_date': null,
        'time_slot': null,
        'calendar_order': 0,
        'total_minutes': eventRow['estimated_minutes'] as int? ?? 0,
        'actual_minutes': null,
        'tomato_count': 0,
        'created_at': nowText,
        'updated_at': nowText,
        'completed_at': null,
        'deleted_at': null,
      });

      final stepRows = await executor.query(
        'template_stage_event_steps',
        where: 'template_event_id = ?',
        whereArgs: [templateEventId],
        orderBy: 'step_order ASC, id ASC',
      );
      for (final stepRow in stepRows) {
        await executor.insert('steps', {
          'event_id': eventId,
          'step_order': stepRow['step_order'] as int? ?? 1,
          'description': (stepRow['description'] as String?) ?? '',
          'estimated_min': stepRow['estimated_minutes'] as int? ?? 0,
          'completed_at': null,
        });
      }

      await executor.insert('template_generated_events', {
        'deployment_id': deploymentId,
        'stage_id': stageId,
        'template_event_id': templateEventId,
        'event_id': eventId,
        'status': 'active',
        'created_at': nowText,
        'updated_at': nowText,
      });
    }

    await executor.update(
      'template_deployment_stage_progress',
      {'status': 'in_progress', 'started_at': nowText, 'updated_at': nowText},
      where: 'deployment_id = ? AND stage_id = ? AND status != ?',
      whereArgs: [deploymentId, stageId, 'completed'],
    );
    await executor.update(
      'template_deployments',
      {
        'status': 'active',
        'active_stage_id': stageId,
        'enabled_at': nowText,
        'completed_at': null,
        'updated_at': nowText,
      },
      where: 'id = ? AND enabled_at IS NULL',
      whereArgs: [deploymentId],
    );
    await executor.update(
      'template_deployments',
      {
        'status': 'active',
        'active_stage_id': stageId,
        'completed_at': null,
        'updated_at': nowText,
      },
      where: 'id = ? AND enabled_at IS NOT NULL',
      whereArgs: [deploymentId],
    );
  }

  static Future<Map<String, dynamic>?> _deploymentRow(
    DatabaseExecutor executor,
    int deploymentId,
  ) async {
    final rows = await executor.query(
      'template_deployments',
      where: 'id = ?',
      whereArgs: [deploymentId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single;
  }

  static Future<Map<String, dynamic>?> _firstStageRow(
    DatabaseExecutor executor,
    int templateId,
  ) async {
    final rows = await executor.query(
      'template_stages',
      where: 'template_id = ?',
      whereArgs: [templateId],
      orderBy: 'stage_order ASC, id ASC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single;
  }

  static Future<Map<String, dynamic>?> _progressRow(
    DatabaseExecutor executor,
    int deploymentId,
    int stageId,
  ) async {
    final rows = await executor.query(
      'template_deployment_stage_progress',
      where: 'deployment_id = ? AND stage_id = ?',
      whereArgs: [deploymentId, stageId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single;
  }

  static Future<int> _stageEventCount(
    DatabaseExecutor executor,
    int stageId,
  ) async {
    final rows = await executor.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM template_stage_events
      WHERE stage_id = ? AND TRIM(title) != ''
      ''',
      [stageId],
    );
    return (rows.single['count'] as int?) ?? 0;
  }

  static Future<int> _generatedEventCount(
    DatabaseExecutor executor,
    int deploymentId,
    int stageId,
  ) async {
    final rows = await executor.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM template_generated_events
      WHERE deployment_id = ? AND stage_id = ?
      ''',
      [deploymentId, stageId],
    );
    return (rows.single['count'] as int?) ?? 0;
  }

  static Future<int> _completedGeneratedEventCount(
    DatabaseExecutor executor,
    int deploymentId,
    int stageId,
  ) async {
    final rows = await executor.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM template_generated_events ge
      INNER JOIN events e ON e.id = ge.event_id
      WHERE ge.deployment_id = ?
        AND ge.stage_id = ?
        AND e.status = 'completed'
        AND e.deleted_at IS NULL
      ''',
      [deploymentId, stageId],
    );
    return (rows.single['count'] as int?) ?? 0;
  }

  static Future<List<TemplateDeploymentStageProgress>> _loadDeploymentProgress(
    Database db,
    int deploymentId,
  ) async {
    final rows = await db.query(
      'template_deployment_stage_progress',
      where: 'deployment_id = ?',
      whereArgs: [deploymentId],
      orderBy: 'id ASC',
    );
    return rows.map(_deploymentProgressFromRow).toList();
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

  static TemplateDeployment _deploymentFromRow(
    Map<String, dynamic> row,
    TaskTemplate template,
    List<TemplateDeploymentStageProgress> progress,
  ) {
    final activeStageId = row['active_stage_id'] as int?;
    var activeStageIndex = -1;
    if (activeStageId != null) {
      activeStageIndex = template.stages.indexWhere(
        (stage) => stage.id == activeStageId,
      );
    }
    if (activeStageIndex == -1 &&
        _deploymentStatusFromDb(row['status'] as String?) ==
            TemplateDeploymentStatus.completed) {
      activeStageIndex = template.stages.length;
    }

    return TemplateDeployment(
      id: row['id'] as int,
      template: template,
      status: _deploymentStatusFromDb(row['status'] as String?),
      activeStageId: activeStageId,
      activeStageIndex: activeStageIndex,
      pauseAfterCurrentStage:
          ((row['pause_after_current_stage'] as int?) ?? 0) == 1,
      deployedAt:
          _nullableDateFromRowValue(row['deployed_at']) ??
          _dateFromRowValue(row['created_at']),
      enabledAt: _nullableDateFromRowValue(row['enabled_at']),
      completedAt: _nullableDateFromRowValue(row['completed_at']),
      stageProgress: progress,
    );
  }

  static TemplateDeploymentStageProgress _deploymentProgressFromRow(
    Map<String, dynamic> row,
  ) {
    return TemplateDeploymentStageProgress(
      stageId: row['stage_id'] as int,
      status: _stageStatusFromDb(row['status'] as String?),
      completedEventCount: (row['completed_event_count'] as int?) ?? 0,
      totalEventCount: (row['total_event_count'] as int?) ?? 0,
      startedAt: _nullableDateFromRowValue(row['started_at']),
      completedAt: _nullableDateFromRowValue(row['completed_at']),
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

  static TemplateDeploymentStatus _deploymentStatusFromDb(String? value) {
    return switch (value) {
      'active' => TemplateDeploymentStatus.active,
      'completed' => TemplateDeploymentStatus.completed,
      _ => TemplateDeploymentStatus.notStarted,
    };
  }

  static TemplateDeploymentStageStatus _stageStatusFromDb(String? value) {
    return switch (value) {
      'in_progress' => TemplateDeploymentStageStatus.inProgress,
      'completed' => TemplateDeploymentStageStatus.completed,
      _ => TemplateDeploymentStageStatus.locked,
    };
  }
}
