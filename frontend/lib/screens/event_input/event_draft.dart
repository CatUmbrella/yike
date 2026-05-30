import '../../models/event.dart';

class EventDraft {
  EventDraft({
    required this.event,
    this.fromAi = false,
    this.edited = false,
    this.totalDurationOverridden = false,
    this.manualTotalMinutes,
    Set<int>? editedStepIndexes,
    Event? originalAiEvent,
  }) : editedStepIndexes = editedStepIndexes ?? <int>{},
       originalAiEvent = originalAiEvent == null
           ? null
           : cloneEvent(originalAiEvent);

  factory EventDraft.fromAiEvent(Event event) {
    final draftEvent = cloneEvent(event);
    return EventDraft(
      event: draftEvent,
      fromAi: true,
      originalAiEvent: draftEvent,
    );
  }

  factory EventDraft.fromExistingEvent(Event event) {
    return EventDraft(event: cloneEvent(event));
  }

  factory EventDraft.custom() {
    return EventDraft(
      event: Event(
        title: '',
        summary: '',
        purpose: '',
        status: 'inbox',
        steps: [StepItem(stepOrder: 1, description: '', estimatedMin: 0)],
      ),
    );
  }

  Event event;
  final Event? originalAiEvent;
  bool fromAi;
  bool edited;
  bool totalDurationOverridden;
  int? manualTotalMinutes;
  final Set<int> editedStepIndexes;

  int get displayTotalMinutes {
    if (totalDurationOverridden) return manualTotalMinutes ?? 0;
    return event.totalMinutes;
  }

  bool stepIsAiSuggestion(int stepIndex) {
    return fromAi && !editedStepIndexes.contains(stepIndex);
  }

  void markEdited({int? stepIndex}) {
    edited = true;
    if (stepIndex != null) editedStepIndexes.add(stepIndex);
  }

  void resetAiSuggestion() {
    final original = originalAiEvent;
    if (original == null) return;
    event = cloneEvent(original);
    edited = false;
    totalDurationOverridden = false;
    manualTotalMinutes = null;
    editedStepIndexes.clear();
  }
}

Event cloneEvent(Event source) {
  return Event(
    id: source.id,
    title: source.title,
    summary: source.summary,
    purpose: source.purpose,
    status: source.status,
    quadrant: source.quadrant,
    scheduledDate: source.scheduledDate,
    timeSlot: source.timeSlot,
    calendarOrder: source.calendarOrder,
    steps: source.steps
        .map(
          (step) => StepItem(
            stepOrder: step.stepOrder,
            description: step.description,
            estimatedMin: step.estimatedMin,
          ),
        )
        .toList(),
    createdAt: source.createdAt,
    completedAt: source.completedAt,
    deletedAt: source.deletedAt,
  );
}
