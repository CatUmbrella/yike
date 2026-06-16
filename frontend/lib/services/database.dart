import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/event.dart';
import '../models/template_models.dart';

part 'database/app_database.dart';
part 'database/database_migrations.dart';
part 'database/event_dao.dart';
part 'database/pomodoro_dao.dart';
part 'database/template_dao.dart';
part 'database/table_helpers.dart';

class LocalDatabase {
  static Future<Database> get database => _AppDatabase.database;

  @visibleForTesting
  static Future<void> createSchemaForTest(Database db) {
    return _DatabaseMigrations.create(db, _DatabaseMigrations.currentVersion);
  }

  @visibleForTesting
  static int get currentSchemaVersionForTest =>
      _DatabaseMigrations.currentVersion;

  @visibleForTesting
  static List<String> get templateTableNamesForTest =>
      _DatabaseMigrations.templateTableNames;

  static Future<int> saveEvent(Event event) {
    return _EventDao.saveEvent(event);
  }

  static Future<List<Event>> getArrangeEvents() {
    return _EventDao.getArrangeEvents();
  }

  static Future<List<Event>> getDeletedArrangeEvents() {
    return _EventDao.getDeletedArrangeEvents();
  }

  static Future<void> updateEventCalendarOrderBatch(
    List<Event> events,
    String date,
    String timeSlot,
  ) {
    return _EventDao.updateEventCalendarOrderBatch(events, date, timeSlot);
  }

  static Future<void> updateEventQuadrant(int eventId, String? quadrant) {
    return _EventDao.updateEventQuadrant(eventId, quadrant);
  }

  static Future<void> updateEventCompletion(
    int eventId,
    String completedAt, {
    int? actualMinutes,
    int? tomatoCount,
  }) {
    return _EventDao.updateEventCompletion(
      eventId,
      completedAt,
      actualMinutes: actualMinutes,
      tomatoCount: tomatoCount,
    );
  }

  static Future<void> updateEventReview(int eventId, String review) {
    return _EventDao.updateEventReview(eventId, review);
  }

  static Future<void> backfillStepCompletionsFromPomodoroRecords() {
    return _EventDao.backfillStepCompletionsFromPomodoroRecords();
  }

  static Future<List<Event>> getEvents({String? status}) {
    return _EventDao.getEvents(status: status);
  }

  static Future<Event?> getEventById(int id) {
    return _EventDao.getEventById(id);
  }

  static Future<List<Event>> getDeletedEvents() {
    return _EventDao.getDeletedEvents();
  }

  static Future<void> softDeleteEvent(int eventId) {
    return _EventDao.softDeleteEvent(eventId);
  }

  static Future<void> restoreEvent(int eventId) {
    return _EventDao.restoreEvent(eventId);
  }

  static Future<void> deleteEventPermanently(int eventId) {
    return _EventDao.deleteEventPermanently(eventId);
  }

  static Future<void> updateEventPomodoroStats(
    int eventId, {
    int? actualMinutes,
    int? tomatoCount,
  }) {
    return _EventDao.updateEventPomodoroStats(
      eventId,
      actualMinutes: actualMinutes,
      tomatoCount: tomatoCount,
    );
  }

  static Future<List<Map<String, dynamic>>> getPomodoroSessionRows() {
    return _PomodoroDao.getSessionRows();
  }

  static Future<Map<String, dynamic>?> getPomodoroSessionRowById(
    int sessionId,
  ) {
    return _PomodoroDao.getSessionRowById(sessionId);
  }

  static Future<Map<String, dynamic>?> getLatestPomodoroSessionRowByEventId(
    int eventId,
  ) {
    return _PomodoroDao.getLatestSessionRowByEventId(eventId);
  }

  static Future<List<Map<String, dynamic>>> getPomodoroInterruptionRows(
    int sessionId,
  ) {
    return _PomodoroDao.getInterruptionRows(sessionId);
  }

  static Future<List<Map<String, dynamic>>> getPomodoroIdeaRows(int sessionId) {
    return _PomodoroDao.getIdeaRows(sessionId);
  }

  static Future<List<Map<String, dynamic>>> getPomodoroStepRecordRows(
    int sessionId,
  ) {
    return _PomodoroDao.getStepRecordRows(sessionId);
  }

  static Future<int> savePomodoroSessionRow(Map<String, dynamic> sessionRow) {
    return _PomodoroDao.saveSessionRow(sessionRow);
  }

  static Future<void> replacePomodoroSnapshotRows({
    required int sessionId,
    required int eventId,
    required List<Map<String, dynamic>> interruptions,
    required List<Map<String, dynamic>> ideas,
    required List<Map<String, dynamic>> stepRecords,
  }) {
    return _PomodoroDao.replaceSnapshotRows(
      sessionId: sessionId,
      eventId: eventId,
      interruptions: interruptions,
      ideas: ideas,
      stepRecords: stepRecords,
    );
  }

  static Future<void> markPomodoroIdeaInboxDecision({
    required int sessionId,
    required String content,
    required String createdAt,
    int? inboxEventId,
  }) {
    return _PomodoroDao.markIdeaInboxDecision(
      sessionId: sessionId,
      content: content,
      createdAt: createdAt,
      inboxEventId: inboxEventId,
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
  }) {
    return _PomodoroDao.upsertEventEditLog(
      eventId: eventId,
      sessionId: sessionId,
      targetType: targetType,
      stepOrder: stepOrder,
      firstValue: firstValue,
      latestValue: latestValue,
      editedAt: editedAt,
    );
  }

  static Future<List<TaskTemplate>> getDraftTemplates() {
    return _TemplateDao.getDraftTemplates();
  }

  static Future<TaskTemplate?> getTemplateById(int templateId) {
    return _TemplateDao.getTemplateById(templateId);
  }

  static Future<TaskTemplate> saveDraftTemplate(TaskTemplate template) {
    return _TemplateDao.saveDraftTemplate(template);
  }

  static Future<void> deleteDraftTemplate(int templateId) {
    return _TemplateDao.deleteDraftTemplate(templateId);
  }

  static Future<TaskTemplate> ensureStoredTemplate(TaskTemplate template) {
    return _TemplateDao.ensureStoredTemplate(template);
  }

  static Future<List<TemplateDeployment>> getTemplateDeployments() {
    return _TemplateDao.getTemplateDeployments();
  }

  static Future<void> createTemplateDeployment(TaskTemplate template) {
    return _TemplateDao.createTemplateDeployment(template);
  }

  static Future<void> deleteTemplateDeployment(int deploymentId) {
    return _TemplateDao.deleteTemplateDeployment(deploymentId);
  }

  static Future<void> enableTemplateDeployment(int deploymentId) {
    return _TemplateDao.enableTemplateDeployment(deploymentId);
  }

  static Future<void> enableTemplateDeploymentStage(
    int deploymentId,
    int stageId,
  ) {
    return _TemplateDao.enableTemplateDeploymentStage(deploymentId, stageId);
  }

  static Future<void> resetTemplateDeployment(int deploymentId) {
    return _TemplateDao.resetTemplateDeployment(deploymentId);
  }

  static Future<void> pauseTemplateDeployment(int deploymentId) {
    return _TemplateDao.pauseTemplateDeployment(deploymentId);
  }
}
