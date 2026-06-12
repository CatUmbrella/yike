import 'package:flutter/foundation.dart';

import '../../models/event.dart';
import '../../models/pomodoro_models.dart';
import '../../repositories/pomodoro_repository.dart';

class PomodoroHomeController extends ChangeNotifier {
  PomodoroHomeController({PomodoroRepository? repository})
    : _repository = repository ?? PomodoroRepository();

  final PomodoroRepository _repository;

  bool loading = true;
  Object? error;
  List<PomodoroHistoryPreviewItem> recentSessions = const [];
  List<Event> candidateEvents = const [];
  PomodoroTaskSnapshot? activeSession;
  int? selectedEventId;

  Event? get selectedEvent {
    for (final event in candidateEvents) {
      if (event.id == selectedEventId) return event;
    }
    return null;
  }

  bool get canStart => selectedEvent != null;

  int? get activeEventId => activeSession?.event.id;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      notifyListeners();
    }
    error = null;
    try {
      recentSessions = await _repository.loadRecentHistoryPreview();
      candidateEvents = await _repository.loadCandidateEvents();
      activeSession = await _repository.loadActiveSession();
      if (selectedEventId != null &&
          !candidateEvents.any((event) => event.id == selectedEventId)) {
        selectedEventId = null;
      }
    } catch (err) {
      error = err;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void tickActiveSession() {
    final current = activeSession;
    if (current == null ||
        current.session.status != PomodoroTimerStatus.running) {
      return;
    }
    activeSession = PomodoroTaskSnapshot(
      event: current.event,
      session: current.session.copyWith(
        durationSec: current.session.durationSec + 1,
        updatedAt: DateTime.now(),
      ),
      interruptions: current.interruptions,
      ideas: current.ideas,
      stepRecords: current.stepRecords,
    );
    notifyListeners();
  }

  void selectEvent(Event event) {
    final id = event.id;
    if (id == null) return;
    selectedEventId = selectedEventId == id ? null : id;
    notifyListeners();
  }
}
