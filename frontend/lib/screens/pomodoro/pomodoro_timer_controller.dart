import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/event.dart';
import '../../models/pomodoro_models.dart';
import '../../repositories/pomodoro_repository.dart';
import '../../shared/pomodoro_constants.dart';

class PomodoroTimerController extends ChangeNotifier {
  PomodoroTimerController({PomodoroRepository? repository})
    : _repository = repository ?? PomodoroRepository();

  final PomodoroRepository _repository;
  Timer? _timer;
  DateTime? _lastCompletedStepAt;
  int? _lastCompletedStepOrder;
  int? _lastCompletedElapsedSec;

  bool loading = true;
  Object? error;
  PomodoroTaskSnapshot? snapshot;

  Event? get event => snapshot?.event;
  PomodoroSession? get session => snapshot?.session;
  PomodoroTimerStatus get status =>
      snapshot?.session.status ?? PomodoroTimerStatus.idle;
  int get elapsedSeconds => snapshot?.session.durationSec ?? 0;

  Future<void> start({
    required int eventId,
    Event? initialEvent,
    PomodoroStartSource source = PomodoroStartSource.home,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      snapshot = await _repository.createSessionForEvent(
        eventId: eventId,
        initialEvent: initialEvent,
      );
      _restoreCompletionCursor();
      _startTicker();
    } catch (err) {
      error = err;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void pause() {
    final current = snapshot;
    if (current == null) return;
    _timer?.cancel();
    snapshot = _copySnapshot(
      current,
      session: current.session.copyWith(
        status: PomodoroTimerStatus.paused,
        updatedAt: DateTime.now(),
      ),
    );
    _saveCurrentSnapshot();
    notifyListeners();
  }

  void resume() {
    final current = snapshot;
    if (current == null) return;
    snapshot = _copySnapshot(
      current,
      session: current.session.copyWith(
        status: PomodoroTimerStatus.running,
        updatedAt: DateTime.now(),
      ),
    );
    _saveCurrentSnapshot();
    _startTicker();
    notifyListeners();
  }

  void addInterruption(String reason, {bool resolved = false}) {
    final current = snapshot;
    final session = current?.session;
    if (current == null || session == null || reason.trim().isEmpty) return;
    final item = PomodoroInterruption(
      id: current.interruptions.length + 1,
      sessionId: session.id ?? 0,
      reason: reason.trim(),
      elapsedSec: session.durationSec,
      createdAt: DateTime.now(),
      resolved: resolved,
    );
    snapshot = _copySnapshot(
      current,
      interruptions: [...current.interruptions, item],
    );
    _saveCurrentSnapshot(includeRecords: true);
    notifyListeners();
  }

  void addIdea(String content) {
    final current = snapshot;
    final session = current?.session;
    if (current == null || session == null || content.trim().isEmpty) return;
    final item = PomodoroIdea(
      id: current.ideas.length + 1,
      sessionId: session.id ?? 0,
      content: content.trim(),
      elapsedSec: session.durationSec,
      createdAt: DateTime.now(),
    );
    snapshot = _copySnapshot(current, ideas: [...current.ideas, item]);
    _saveCurrentSnapshot(includeRecords: true);
    notifyListeners();
  }

  void updateStepDescription(int stepOrder, String value) {
    final current = snapshot;
    if (current == null) return;
    final event = current.event;
    for (final step in event.steps) {
      if (step.stepOrder == stepOrder) {
        step.description = value;
        break;
      }
    }
    final records = current.stepRecords.map((record) {
      if (record.stepOrder != stepOrder) return record;
      return record.copyWith(descriptionSnapshot: value);
    }).toList();
    snapshot = _copySnapshot(current, stepRecords: records);
    _saveCurrentSnapshot(includeRecords: true, saveEvent: true);
    notifyListeners();
  }

  void completeStep(int stepOrder) {
    final current = snapshot;
    final session = current?.session;
    if (current == null || session == null) return;
    final now = DateTime.now();
    final shouldRecordDuration = _shouldRecordStepDuration(stepOrder, now);
    final durationSec = shouldRecordDuration
        ? session.durationSec - (_lastCompletedElapsedSec ?? 0)
        : null;
    final recordedDurationSec = durationSec?.clamp(0, 999999).toInt();
    var eventStepChanged = false;
    final completedAtText = now.toIso8601String();
    for (final step in current.event.steps) {
      if (step.stepOrder != stepOrder || step.completed) continue;
      step.completedAt = completedAtText;
      eventStepChanged = true;
      break;
    }
    final records = current.stepRecords.map((record) {
      if (record.stepOrder != stepOrder || record.completed) return record;
      return record.copyWith(
        completedAt: now,
        elapsedSec: session.durationSec,
        durationSec: recordedDurationSec,
      );
    }).toList();
    _lastCompletedStepAt = now;
    _lastCompletedStepOrder = stepOrder;
    _lastCompletedElapsedSec = session.durationSec;
    snapshot = _copySnapshot(current, stepRecords: records);
    _saveCurrentSnapshot(includeRecords: true, saveEvent: eventStepChanged);
    notifyListeners();
  }

  Future<void> finish({required bool taskCompleted}) async {
    final current = snapshot;
    if (current == null) return;
    _timer?.cancel();
    final endTime = DateTime.now();
    final session = current.session.copyWith(
      status: PomodoroTimerStatus.completed,
      endTime: endTime,
      tomatoCount:
          current.session.durationSec ~/ PomodoroConstants.tomatoSeconds,
      updatedAt: endTime,
    );
    if (taskCompleted) {
      await _repository.markEventCompleted(
        current.event,
        endTime,
        actualMinutes: (session.durationSec / 60).ceil().clamp(0, 9999),
        tomatoCount: session.tomatoCount,
      );
    }
    snapshot = _copySnapshot(current, session: session);
    await _repository.saveSnapshot(
      snapshot!,
      includeRecords: true,
      saveEvent: true,
    );
    notifyListeners();
  }

  Future<void> createInboxEventFromIdea(IdeaToInboxDraft draft) {
    return _repository.createInboxEventFromIdea(draft);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = snapshot;
      if (current == null ||
          current.session.status != PomodoroTimerStatus.running) {
        return;
      }
      snapshot = _copySnapshot(
        current,
        session: current.session.copyWith(
          durationSec: current.session.durationSec + 1,
          tomatoCount:
              (current.session.durationSec + 1) ~/
              PomodoroConstants.tomatoSeconds,
          updatedAt: DateTime.now(),
        ),
      );
      _saveCurrentSnapshot();
      notifyListeners();
    });
  }

  void _saveCurrentSnapshot({
    bool includeRecords = false,
    bool saveEvent = false,
  }) {
    final current = snapshot;
    if (current != null) {
      unawaited(
        _repository.saveSnapshot(
          current,
          includeRecords: includeRecords,
          saveEvent: saveEvent,
        ),
      );
    }
  }

  void _restoreCompletionCursor() {
    final records = snapshot?.stepRecords
        .where((record) => record.completed)
        .toList();
    if (records == null || records.isEmpty) {
      _lastCompletedStepAt = null;
      _lastCompletedStepOrder = null;
      _lastCompletedElapsedSec = null;
      return;
    }
    records.sort((a, b) => a.completedAt!.compareTo(b.completedAt!));
    final latest = records.last;
    _lastCompletedStepAt = latest.completedAt;
    _lastCompletedStepOrder = latest.stepOrder;
    _lastCompletedElapsedSec = latest.elapsedSec;
  }

  bool _shouldRecordStepDuration(int stepOrder, DateTime now) {
    final lastAt = _lastCompletedStepAt;
    final lastOrder = _lastCompletedStepOrder;
    if (lastAt == null || lastOrder == null) return true;
    if (stepOrder != lastOrder + 1) return false;
    return now.difference(lastAt).inSeconds >
        PomodoroConstants.rapidStepThresholdSeconds;
  }

  static PomodoroTaskSnapshot _copySnapshot(
    PomodoroTaskSnapshot current, {
    PomodoroSession? session,
    List<PomodoroInterruption>? interruptions,
    List<PomodoroIdea>? ideas,
    List<PomodoroStepRecord>? stepRecords,
  }) {
    return PomodoroTaskSnapshot(
      event: current.event,
      session: session ?? current.session,
      interruptions: interruptions ?? current.interruptions,
      ideas: ideas ?? current.ideas,
      stepRecords: stepRecords ?? current.stepRecords,
    );
  }
}
