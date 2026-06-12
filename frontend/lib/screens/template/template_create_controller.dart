import 'package:flutter/foundation.dart';

import '../../models/template_models.dart';
import '../../repositories/template_repository.dart';

class TemplateCreateController extends ChangeNotifier {
  TemplateCreateController.newDraft({TemplateRepository? repository})
    : _repository = repository ?? TemplateRepository(),
      _createdAt = DateTime.now() {
    stages = [_emptyStage(1)];
  }

  TemplateCreateController.fromTemplate(
    TaskTemplate template, {
    TemplateRepository? repository,
  }) : _repository = repository ?? TemplateRepository(),
       draftId = template.id,
       templateName = template.name,
       templateGoal = template.goal,
       relation = template.relation,
       notices = template.notices.isEmpty
           ? [const TemplateNotice(noticeOrder: 1, content: '')]
           : List.of(template.notices),
       stages = List.of(template.stages),
       currentStep = template.currentCreateStep.clamp(1, 4).toInt(),
       currentStageIndex = template.currentStageIndex,
       createCompleted = template.createCompleted,
       _createdAt = template.createdAt;

  final TemplateRepository _repository;
  final DateTime _createdAt;

  int? draftId;
  int currentStep = 1;
  int currentStageIndex = 0;
  String templateName = '';
  String templateGoal = '';
  TemplateRelation? relation;
  List<TemplateNotice> notices = [
    const TemplateNotice(noticeOrder: 1, content: ''),
  ];
  List<TemplateStage> stages = [];
  bool createCompleted = false;
  bool dirty = false;

  TemplateStage get currentStage => stages[currentStageIndex];

  int get eventCount =>
      stages.fold<int>(0, (sum, stage) => sum + stage.eventCount);

  bool get hasAnyContent =>
      templateName.trim().isNotEmpty ||
      templateGoal.trim().isNotEmpty ||
      stages.any((stage) => stage.hasContent) ||
      notices.any((notice) => notice.content.trim().isNotEmpty);

  bool get canContinueStep1 {
    return templateName.trim().isNotEmpty &&
        templateGoal.trim().isNotEmpty &&
        stages.any(
          (stage) =>
              stage.name.trim().isNotEmpty && stage.goal.trim().isNotEmpty,
        );
  }

  bool get canContinueStep2 {
    final stage = currentStage;
    return stage.name.trim().isNotEmpty &&
        stage.goal.trim().isNotEmpty &&
        stage.events.any((event) => event.title.trim().isNotEmpty);
  }

  bool get canExport => relation != null;

  void updateTemplateName(String value) {
    templateName = value;
    _markDirty();
  }

  void updateTemplateGoal(String value) {
    templateGoal = value;
    _markDirty();
  }

  void addStage() {
    stages = [...stages, _emptyStage(stages.length + 1)];
    _markDirty();
  }

  void deleteStage(int index) {
    if (stages.length <= 1 || index < 0 || index >= stages.length) return;
    final next = [...stages]..removeAt(index);
    stages = _renumberStages(next);
    if (currentStageIndex >= stages.length) {
      currentStageIndex = stages.length - 1;
    }
    _markDirty();
  }

  void updateStageName(int index, String value) {
    _replaceStage(index, stages[index].copyWith(name: value));
  }

  void updateStageGoal(int index, String value) {
    _replaceStage(index, stages[index].copyWith(goal: value));
  }

  void updateStageEstimatedMinutes(int index, int minutes) {
    _replaceStage(index, stages[index].copyWith(estimatedMinutes: minutes));
  }

  void addEventToCurrentStage() {
    final stage = currentStage;
    final nextEvents = [...stage.events, _emptyEvent(stage.events.length + 1)];
    _replaceStage(currentStageIndex, stage.copyWith(events: nextEvents));
  }

  void updateCurrentStageEventTitle(int eventIndex, String value) {
    _replaceCurrentStageEvent(
      eventIndex,
      currentStage.events[eventIndex].copyWith(title: value),
    );
  }

  void updateCurrentStageEventPurpose(int eventIndex, String value) {
    _replaceCurrentStageEvent(
      eventIndex,
      currentStage.events[eventIndex].copyWith(purpose: value),
    );
  }

  void updateCurrentStageEventMinutes(int eventIndex, int minutes) {
    _replaceCurrentStageEvent(
      eventIndex,
      currentStage.events[eventIndex].copyWith(estimatedMinutes: minutes),
    );
  }

  void deleteCurrentStageEvent(int eventIndex) {
    final nextEvents = [...currentStage.events]..removeAt(eventIndex);
    final renumbered = [
      for (var i = 0; i < nextEvents.length; i++)
        nextEvents[i].copyWith(eventOrder: i + 1),
    ];
    _replaceStage(currentStageIndex, currentStage.copyWith(events: renumbered));
  }

  void updateOverviewEventTitle(int stageIndex, int eventIndex, String value) {
    final stage = stages[stageIndex];
    final events = [...stage.events];
    events[eventIndex] = events[eventIndex].copyWith(title: value);
    if (value.trim().isEmpty) {
      events.removeAt(eventIndex);
    }
    _replaceStage(
      stageIndex,
      stage.copyWith(
        events: [
          for (var i = 0; i < events.length; i++)
            events[i].copyWith(eventOrder: i + 1),
        ],
      ),
    );
  }

  void updateRelation(TemplateRelation value) {
    relation = value;
    _markDirty();
  }

  void addNotice() {
    notices = [
      ...notices,
      TemplateNotice(noticeOrder: notices.length + 1, content: ''),
    ];
    _markDirty();
  }

  void updateNotice(int index, String value) {
    final next = [...notices];
    next[index] = next[index].copyWith(content: value);
    notices = next;
    _markDirty();
  }

  bool moveToNextStageOrOverview() {
    if (currentStageIndex < stages.length - 1) {
      currentStageIndex++;
      currentStep = 2;
      _ensureCurrentStageHasEvent();
      notifyListeners();
      return false;
    }
    currentStep = 3;
    notifyListeners();
    return true;
  }

  void moveToStep(int step) {
    currentStep = step.clamp(1, 4);
    notifyListeners();
  }

  void moveToPreviousStage() {
    if (currentStageIndex > 0) {
      currentStageIndex--;
    } else {
      currentStep = 1;
    }
    notifyListeners();
  }

  Future<TaskTemplate> saveDraft({bool completed = false}) async {
    final template = _buildTemplate(completed: completed);
    final saved = await _repository.saveDraft(template);
    draftId = saved.id;
    dirty = false;
    createCompleted = saved.createCompleted;
    notifyListeners();
    return saved;
  }

  TaskTemplate _buildTemplate({required bool completed}) {
    final cleanedNotices = [
      for (var i = 0; i < notices.length; i++)
        if (notices[i].content.trim().isNotEmpty)
          notices[i].copyWith(noticeOrder: i + 1),
    ];
    return TaskTemplate(
      id: draftId,
      name: templateName.trim(),
      goal: templateGoal.trim(),
      source: TemplateSource.user,
      status: TemplateStatus.draft,
      relation: relation,
      currentCreateStep: currentStep,
      currentStageIndex: currentStageIndex,
      createCompleted: completed,
      stages: _renumberStages(stages),
      notices: cleanedNotices,
      createdAt: _createdAt,
      updatedAt: DateTime.now(),
    );
  }

  void _ensureCurrentStageHasEvent() {
    if (currentStage.events.isNotEmpty) return;
    _replaceStage(
      currentStageIndex,
      currentStage.copyWith(events: [_emptyEvent(1)]),
      notify: false,
    );
  }

  void _replaceCurrentStageEvent(int eventIndex, TemplateStageEvent event) {
    final events = [...currentStage.events];
    events[eventIndex] = event;
    _replaceStage(currentStageIndex, currentStage.copyWith(events: events));
  }

  void _replaceStage(int index, TemplateStage stage, {bool notify = true}) {
    final next = [...stages];
    next[index] = stage;
    stages = next;
    dirty = true;
    if (notify) notifyListeners();
  }

  void _markDirty() {
    dirty = true;
    notifyListeners();
  }

  static TemplateStage _emptyStage(int order) {
    return TemplateStage(
      stageOrder: order,
      name: '',
      goal: '',
      estimatedMinutes: 0,
      events: const [],
    );
  }

  static TemplateStageEvent _emptyEvent(int order) {
    return TemplateStageEvent(
      eventOrder: order,
      title: '',
      purpose: '',
      estimatedMinutes: 25,
      steps: const [
        TemplateStageEventStep(
          stepOrder: 1,
          description: '明确要做什么',
          estimatedMinutes: 10,
        ),
      ],
    );
  }

  static List<TemplateStage> _renumberStages(List<TemplateStage> input) {
    return [
      for (var i = 0; i < input.length; i++)
        input[i].copyWith(stageOrder: i + 1),
    ];
  }
}
