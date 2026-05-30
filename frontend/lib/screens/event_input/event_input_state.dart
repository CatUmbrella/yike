import 'event_draft.dart';

enum EventInputStatus { idle, parsing, failed }

const _unset = Object();

class EventInputState {
  const EventInputState({
    this.inputText = '',
    this.status = EventInputStatus.idle,
    this.errorText,
    this.drafts = const <EventDraft>[],
    this.currentDraftIndex = 0,
  });

  final String inputText;
  final EventInputStatus status;
  final String? errorText;
  final List<EventDraft> drafts;
  final int currentDraftIndex;

  bool get parsing => status == EventInputStatus.parsing;
  bool get failed => status == EventInputStatus.failed;
  bool get hasDrafts => drafts.isNotEmpty;

  EventDraft? get currentDraft {
    if (drafts.isEmpty) return null;
    final index = currentDraftIndex.clamp(0, drafts.length - 1);
    return drafts[index];
  }

  EventInputState copyWith({
    String? inputText,
    EventInputStatus? status,
    Object? errorText = _unset,
    List<EventDraft>? drafts,
    int? currentDraftIndex,
  }) {
    return EventInputState(
      inputText: inputText ?? this.inputText,
      status: status ?? this.status,
      errorText: identical(errorText, _unset)
          ? this.errorText
          : errorText as String?,
      drafts: drafts ?? this.drafts,
      currentDraftIndex: currentDraftIndex ?? this.currentDraftIndex,
    );
  }
}
