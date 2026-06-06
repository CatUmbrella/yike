import 'package:flutter/foundation.dart';

import '../../models/event.dart';
import '../../services/api.dart';
import '../../services/database.dart';
import '../../shared/event_schedule.dart';
import 'event_draft.dart';
import 'event_input_state.dart';

class EventInputController extends ChangeNotifier {
  EventInputState _state = const EventInputState();
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

      _commitState(
        _state.copyWith(
          status: EventInputStatus.idle,
          errorText: null,
          drafts: _orderedDrafts(visibleEvents),
          currentDraftIndex: 0,
        ),
      );
    } catch (_) {
      // Keep the page usable when local persistence is unavailable.
    }
  }

  void updateInputText(String value) {
    _commitState(
      _state.copyWith(
        inputText: value,
        status: EventInputStatus.idle,
        errorText: null,
      ),
    );
  }

  void setCurrentDraftIndex(int index) {
    if (_state.drafts.isEmpty) return;
    final nextIndex = index.clamp(0, _state.drafts.length - 1);
    if (nextIndex == _state.currentDraftIndex) return;
    _commitState(_state.copyWith(currentDraftIndex: nextIndex));
  }

  Future<void> parseInputNow() async {
    final text = _state.inputText.trim();
    if (text.isEmpty) return;

    final runId = ++_parseRunId;
    _commitState(
      _state.copyWith(status: EventInputStatus.parsing, errorText: null),
    );

    final result = await ApiService.parseEventText(text);
    if (runId != _parseRunId) return;

    if (result.failed) {
      _commitState(
        _state.copyWith(
          status: EventInputStatus.failed,
          errorText: result.errorText,
        ),
      );
      return;
    }

    if (result.events.isEmpty) {
      _commitState(
        _state.copyWith(
          status: EventInputStatus.failed,
          errorText: '未识别到事件，请补充描述',
        ),
      );
      return;
    }

    _commitState(
      _state.copyWith(
        status: EventInputStatus.idle,
        errorText: null,
        drafts: _orderedDrafts([
          ...result.events.map(EventDraft.fromAiEvent),
          ..._state.drafts,
        ]),
        currentDraftIndex: 0,
      ),
    );
  }

  void addCustomEvent() {
    final drafts = _orderedDrafts([EventDraft.custom(), ..._state.drafts]);
    _commitState(
      _state.copyWith(
        status: EventInputStatus.idle,
        errorText: null,
        drafts: drafts,
        currentDraftIndex: 0,
      ),
    );
  }

  Future<SaveDraftsResult> saveValidDrafts() async {
    _parseRunId++;
    var failedCount = 0;
    var savedCount = 0;

    for (final draft in _state.drafts) {
      final event = draft.event;
      final title = event.title.trim();
      if (title.isEmpty) continue;
      if (event.id != null && !draft.edited) continue;

      event.title = title;
      event.summary = event.summary.trim();
      event.purpose = event.purpose.trim();
      _reorderSteps(event);

      try {
        await LocalDatabase.saveEvent(event);
        savedCount++;
      } catch (_) {
        failedCount++;
      }
    }

    return SaveDraftsResult(failedCount: failedCount, savedCount: savedCount);
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

  void updateTotalMinutes(int draftIndex, int value) {
    _editDraft(draftIndex, (draft) {
      final minutes = value.clamp(0, 1500).toInt();
      draft.event.totalMinutesOverride = minutes;
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
      draft.event.totalMinutesOverride = null;
      draft.markEdited(stepIndex: draft.event.steps.length - 1);
    });
  }

  void removeStep(int draftIndex, int stepIndex) {
    _editDraft(draftIndex, (draft) {
      if (stepIndex < 0 || stepIndex >= draft.event.steps.length) return;
      draft.event.steps.removeAt(stepIndex);
      _reorderSteps(draft.event);
      draft.event.totalMinutesOverride = null;
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
      draft.event.totalMinutesOverride = null;
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
    _commitState(
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

  void _editDraft(int draftIndex, void Function(EventDraft draft) edit) {
    if (draftIndex < 0 || draftIndex >= _state.drafts.length) return;
    final drafts = List<EventDraft>.from(_state.drafts);
    edit(drafts[draftIndex]);
    _commitState(
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

  List<EventDraft> _orderedDrafts(Iterable<EventDraft> drafts) {
    final newDrafts = <EventDraft>[];
    final todayArrangedDrafts = <EventDraft>[];
    final remainingDrafts = <EventDraft>[];
    final todayKey = dateKey(DateTime.now());

    for (final draft in drafts) {
      final event = draft.event;
      if (event.id == null) {
        newDrafts.add(draft);
      } else if (event.status == 'arranged' &&
          event.scheduledDate == todayKey) {
        todayArrangedDrafts.add(draft);
      } else {
        remainingDrafts.add(draft);
      }
    }

    todayArrangedDrafts.sort(_compareTodayArrangedDrafts);
    remainingDrafts.sort(_compareCreatedAtDesc);
    return [...newDrafts, ...todayArrangedDrafts, ...remainingDrafts];
  }

  DateTime _createdAtForSort(Event event) {
    return DateTime.parse(event.createdAt);
  }

  int _compareTodayArrangedDrafts(EventDraft a, EventDraft b) {
    final slotOrder = _slotIndex(a.event).compareTo(_slotIndex(b.event));
    if (slotOrder != 0) return slotOrder;
    return compareCalendarEvents(a.event, b.event);
  }

  int _compareCreatedAtDesc(EventDraft a, EventDraft b) {
    final created = _createdAtForSort(
      b.event,
    ).compareTo(_createdAtForSort(a.event));
    if (created != 0) return created;
    return (b.event.id ?? 0).compareTo(a.event.id ?? 0);
  }

  int _slotIndex(Event event) {
    final index = arrangeTimeSlots.indexWhere(
      (slot) => slot.key == event.timeSlot,
    );
    if (index >= 0) return index;
    return arrangeTimeSlots.length;
  }

  void _commitState(EventInputState value) {
    _state = value;
    notifyListeners();
  }
}

class SaveDraftsResult {
  final int failedCount;
  final int savedCount;

  const SaveDraftsResult({required this.failedCount, required this.savedCount});

  bool get changed => savedCount > 0;
}
