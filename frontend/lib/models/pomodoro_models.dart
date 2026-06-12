import 'event.dart';

enum PomodoroStartSource { home, eventDetail, history }

enum PomodoroTimerStatus { idle, running, paused, finishing, completed }

class PomodoroSession {
  final int? id;
  final int eventId;
  final DateTime startTime;
  final DateTime? endTime;
  final PomodoroTimerStatus status;
  final int durationSec;
  final int? plannedMinutesSnapshot;
  final int tomatoCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PomodoroSession({
    this.id,
    required this.eventId,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.durationSec,
    this.plannedMinutesSnapshot,
    required this.tomatoCount,
    required this.createdAt,
    required this.updatedAt,
  });

  PomodoroSession copyWith({
    int? id,
    DateTime? endTime,
    PomodoroTimerStatus? status,
    int? durationSec,
    int? tomatoCount,
    DateTime? updatedAt,
  }) {
    return PomodoroSession(
      id: id ?? this.id,
      eventId: eventId,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      durationSec: durationSec ?? this.durationSec,
      plannedMinutesSnapshot: plannedMinutesSnapshot,
      tomatoCount: tomatoCount ?? this.tomatoCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PomodoroInterruption {
  final int id;
  final int sessionId;
  final String reason;
  final int elapsedSec;
  final DateTime createdAt;
  final bool resolved;

  const PomodoroInterruption({
    required this.id,
    required this.sessionId,
    required this.reason,
    required this.elapsedSec,
    required this.createdAt,
    this.resolved = false,
  });
}

class PomodoroIdea {
  final int id;
  final int sessionId;
  final String content;
  final int elapsedSec;
  final DateTime createdAt;
  final bool addedToInbox;
  final bool inboxHandled;
  final int? inboxEventId;

  const PomodoroIdea({
    required this.id,
    required this.sessionId,
    required this.content,
    required this.elapsedSec,
    required this.createdAt,
    this.addedToInbox = false,
    this.inboxHandled = false,
    this.inboxEventId,
  });
}

class PomodoroStepRecord {
  final int stepOrder;
  final String descriptionSnapshot;
  final int estimatedMinSnapshot;
  final DateTime? completedAt;
  final int? elapsedSec;
  final int? durationSec;

  const PomodoroStepRecord({
    required this.stepOrder,
    required this.descriptionSnapshot,
    required this.estimatedMinSnapshot,
    this.completedAt,
    this.elapsedSec,
    this.durationSec,
  });

  bool get completed => completedAt != null;

  PomodoroStepRecord copyWith({
    String? descriptionSnapshot,
    DateTime? completedAt,
    int? elapsedSec,
    int? durationSec,
  }) {
    return PomodoroStepRecord(
      stepOrder: stepOrder,
      descriptionSnapshot: descriptionSnapshot ?? this.descriptionSnapshot,
      estimatedMinSnapshot: estimatedMinSnapshot,
      completedAt: completedAt ?? this.completedAt,
      elapsedSec: elapsedSec ?? this.elapsedSec,
      durationSec: durationSec ?? this.durationSec,
    );
  }
}

class PomodoroHistoryPreviewItem {
  final int sessionId;
  final int eventId;
  final String title;
  final DateTime displayTime;
  final int tomatoCount;
  final bool eventCompleted;

  const PomodoroHistoryPreviewItem({
    required this.sessionId,
    required this.eventId,
    required this.title,
    required this.displayTime,
    required this.tomatoCount,
    required this.eventCompleted,
  });
}

class PomodoroSelectableEvent {
  final Event event;
  final bool selected;

  const PomodoroSelectableEvent({required this.event, required this.selected});
}

class PomodoroTaskSnapshot {
  final Event event;
  final PomodoroSession session;
  final List<PomodoroInterruption> interruptions;
  final List<PomodoroIdea> ideas;
  final List<PomodoroStepRecord> stepRecords;

  const PomodoroTaskSnapshot({
    required this.event,
    required this.session,
    required this.interruptions,
    required this.ideas,
    required this.stepRecords,
  });
}

class PomodoroHistorySection {
  final String title;
  final List<PomodoroHistoryListItem> items;

  const PomodoroHistorySection({required this.title, required this.items});
}

class PomodoroHistoryListItem {
  final int sessionId;
  final Event event;
  final DateTime displayDateTime;
  final int interruptionCount;
  final int ideaCount;
  final int tomatoCount;

  const PomodoroHistoryListItem({
    required this.sessionId,
    required this.event,
    required this.displayDateTime,
    required this.interruptionCount,
    required this.ideaCount,
    required this.tomatoCount,
  });

  bool get completed => event.completedAt != null && event.completedAt != '';
}

class PomodoroHistoryDetail {
  final Event event;
  final PomodoroSession session;
  final List<PomodoroInterruption> interruptions;
  final List<PomodoroIdea> ideas;
  final List<PomodoroStepRecord> stepRecords;

  const PomodoroHistoryDetail({
    required this.event,
    required this.session,
    required this.interruptions,
    required this.ideas,
    this.stepRecords = const [],
  });
}

class IdeaToInboxDraft {
  final PomodoroIdea idea;
  final String title;
  final String purpose;
  final List<StepItem> steps;
  final bool shouldAddToInbox;

  const IdeaToInboxDraft({
    required this.idea,
    required this.title,
    required this.purpose,
    required this.steps,
    required this.shouldAddToInbox,
  });
}
