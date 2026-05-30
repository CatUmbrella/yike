import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/event.dart';
import '../../services/api.dart';
import '../../services/database.dart';
import 'event_draft.dart';
import 'event_input_state.dart';

class EventInputController extends ChangeNotifier {
  static const Duration parseDelay = Duration(seconds: 3);

  EventInputState _state = const EventInputState();
  Timer? _parseTimer;
  int _parseRunId = 0;

  EventInputState get state => _state;

  Future<void> loadExistingEvents() async {
    try {
      final events = await LocalDatabase.getEvents();
      final visibleEvents = events
          .where((event) => event.status != 'completed')
          .map(EventDraft.fromExistingEvent)
          .toList();

      if (_state.inputText.trim().isNotEmpty || _state.drafts.isNotEmpty) {
        return;
      }

      _setState(
        _state.copyWith(
          status: EventInputStatus.idle,
          errorText: null,
          drafts: visibleEvents,
          currentDraftIndex: 0,
        ),
      );
    } catch (_) {
      // Keep the page usable when local persistence is unavailable.
    }
  }

  void updateInputText(String value) {
    _setState(
      _state.copyWith(
        inputText: value,
        status: EventInputStatus.idle,
        errorText: null,
      ),
    );
    _scheduleParseIfReady();
  }

  void requestParseAfterInputSettled() {
    _scheduleParseIfReady();
  }

  void setCurrentDraftIndex(int index) {
    if (_state.drafts.isEmpty) return;
    final nextIndex = index.clamp(0, _state.drafts.length - 1);
    if (nextIndex == _state.currentDraftIndex) return;
    _setState(_state.copyWith(currentDraftIndex: nextIndex));
  }

  Future<void> parseInputNow() async {
    _parseTimer?.cancel();
    final text = _state.inputText.trim();
    if (text.isEmpty) return;

    final runId = ++_parseRunId;
    _setState(
      _state.copyWith(status: EventInputStatus.parsing, errorText: null),
    );

    final events = await ApiService.parseEventText(text);
    if (runId != _parseRunId) return;

    if (events.isEmpty) {
      _setState(
        _state.copyWith(status: EventInputStatus.failed, errorText: '生成失败，请重试'),
      );
      return;
    }

    _setState(
      _state.copyWith(
        status: EventInputStatus.idle,
        errorText: null,
        drafts: events.map(EventDraft.fromAiEvent).toList(),
        currentDraftIndex: 0,
      ),
    );
  }

  void addCustomEvent() {
    final drafts = List<EventDraft>.from(_state.drafts)
      ..add(EventDraft.custom());
    _setState(
      _state.copyWith(
        status: EventInputStatus.idle,
        errorText: null,
        drafts: drafts,
        currentDraftIndex: drafts.length - 1,
      ),
    );
  }

  void updateTitle(int draftIndex, String value) {
    _editDraft(draftIndex, (draft) {
      draft.event.title = value;
      draft.markEdited();
    });
  }

  void updateSummary(int draftIndex, String value) {
    _editDraft(draftIndex, (draft) {
      draft.event.summary = value;
      draft.markEdited();
    });
  }

  void updatePurpose(int draftIndex, String value) {
    _editDraft(draftIndex, (draft) {
      draft.event.purpose = value;
      draft.markEdited();
    });
  }

  void addStep(int draftIndex) {
    _editDraft(draftIndex, (draft) {
      draft.event.steps.add(
        StepItem(
          stepOrder: draft.event.steps.length + 1,
          description: '',
          estimatedMin: 0,
        ),
      );
      draft.markEdited(stepIndex: draft.event.steps.length - 1);
    });
  }

  void removeStep(int draftIndex, int stepIndex) {
    _editDraft(draftIndex, (draft) {
      if (stepIndex < 0 || stepIndex >= draft.event.steps.length) return;
      draft.event.steps.removeAt(stepIndex);
      _reorderSteps(draft.event);
      draft.markEdited();
    });
  }

  void updateStepDescription(int draftIndex, int stepIndex, String value) {
    if (value.trim().isEmpty) {
      removeStep(draftIndex, stepIndex);
      return;
    }

    _editDraft(draftIndex, (draft) {
      if (stepIndex < 0 || stepIndex >= draft.event.steps.length) return;
      draft.event.steps[stepIndex].description = value;
      draft.markEdited(stepIndex: stepIndex);
    });
  }

  void updateStepMinutes(int draftIndex, int stepIndex, int value) {
    _editDraft(draftIndex, (draft) {
      if (stepIndex < 0 || stepIndex >= draft.event.steps.length) return;
      draft.event.steps[stepIndex].estimatedMin = value;
      draft.totalDurationOverridden = false;
      draft.manualTotalMinutes = null;
      draft.markEdited(stepIndex: stepIndex);
    });
  }

  void resetAiSuggestion(int draftIndex) {
    _editDraft(draftIndex, (draft) => draft.resetAiSuggestion());
  }

  Future<bool> deleteDraft(int draftIndex) async {
    if (draftIndex < 0 || draftIndex >= _state.drafts.length) return false;

    final drafts = List<EventDraft>.from(_state.drafts);
    final event = drafts[draftIndex].event;
    if (event.id != null) {
      await LocalDatabase.softDeleteEvent(event.id!);
    }

    drafts.removeAt(draftIndex);
    _setState(
      _state.copyWith(
        status: EventInputStatus.idle,
        errorText: null,
        drafts: drafts,
        currentDraftIndex: drafts.isEmpty
            ? 0
            : draftIndex.clamp(0, drafts.length - 1).toInt(),
      ),
    );
    return true;
  }

  void _scheduleParseIfReady() {
    _parseTimer?.cancel();
    if (_state.inputText.trim().isEmpty) return;
    _parseTimer = Timer(parseDelay, parseInputNow);
  }

  void _editDraft(int draftIndex, void Function(EventDraft draft) edit) {
    if (draftIndex < 0 || draftIndex >= _state.drafts.length) return;
    final drafts = List<EventDraft>.from(_state.drafts);
    edit(drafts[draftIndex]);
    _setState(
      _state.copyWith(
        status: EventInputStatus.idle,
        errorText: null,
        drafts: drafts,
      ),
    );
  }

  void _reorderSteps(Event event) {
    for (var i = 0; i < event.steps.length; i++) {
      event.steps[i].stepOrder = i + 1;
    }
  }

  void _setState(EventInputState value) {
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _parseTimer?.cancel();
    super.dispose();
  }
}
