enum TemplateSection { create, deploy, library }

enum TemplateCreateTab { drafts, published }

enum TemplateDeployTab { notStarted, active, completed }

enum TemplateLibraryTab { official }

enum TemplateSource { user, official, publicUser }

enum TemplateStatus { draft, published, archived }

enum TemplateRelation { linear, parallel }

enum TemplateDeploymentStatus { notStarted, active, completed }

class TemplateNotice {
  final int? id;
  final int noticeOrder;
  final String content;

  const TemplateNotice({
    this.id,
    required this.noticeOrder,
    required this.content,
  });

  TemplateNotice copyWith({int? id, int? noticeOrder, String? content}) {
    return TemplateNotice(
      id: id ?? this.id,
      noticeOrder: noticeOrder ?? this.noticeOrder,
      content: content ?? this.content,
    );
  }
}

class TemplateStageEventStep {
  final int? id;
  final int stepOrder;
  final String description;
  final int estimatedMinutes;

  const TemplateStageEventStep({
    this.id,
    required this.stepOrder,
    required this.description,
    required this.estimatedMinutes,
  });

  TemplateStageEventStep copyWith({
    int? id,
    int? stepOrder,
    String? description,
    int? estimatedMinutes,
  }) {
    return TemplateStageEventStep(
      id: id ?? this.id,
      stepOrder: stepOrder ?? this.stepOrder,
      description: description ?? this.description,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    );
  }
}

class TemplateStageEvent {
  final int? id;
  final int eventOrder;
  final String title;
  final String purpose;
  final int estimatedMinutes;
  final List<TemplateStageEventStep> steps;

  const TemplateStageEvent({
    this.id,
    required this.eventOrder,
    required this.title,
    required this.purpose,
    required this.estimatedMinutes,
    required this.steps,
  });

  bool get hasContent =>
      title.trim().isNotEmpty ||
      purpose.trim().isNotEmpty ||
      steps.any((step) => step.description.trim().isNotEmpty);

  TemplateStageEvent copyWith({
    int? id,
    int? eventOrder,
    String? title,
    String? purpose,
    int? estimatedMinutes,
    List<TemplateStageEventStep>? steps,
  }) {
    return TemplateStageEvent(
      id: id ?? this.id,
      eventOrder: eventOrder ?? this.eventOrder,
      title: title ?? this.title,
      purpose: purpose ?? this.purpose,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      steps: steps ?? this.steps,
    );
  }
}

class TemplateStage {
  final int? id;
  final int stageOrder;
  final String name;
  final String goal;
  final int estimatedMinutes;
  final List<TemplateStageEvent> events;

  const TemplateStage({
    this.id,
    required this.stageOrder,
    required this.name,
    required this.goal,
    required this.estimatedMinutes,
    required this.events,
  });

  bool get hasContent =>
      name.trim().isNotEmpty ||
      goal.trim().isNotEmpty ||
      events.any((event) => event.hasContent);

  int get eventCount =>
      events.where((event) => event.title.trim().isNotEmpty).length;

  int get calculatedMinutes {
    final total = events.fold<int>(
      0,
      (sum, event) => sum + event.estimatedMinutes,
    );
    return total > 0 ? total : estimatedMinutes;
  }

  TemplateStage copyWith({
    int? id,
    int? stageOrder,
    String? name,
    String? goal,
    int? estimatedMinutes,
    List<TemplateStageEvent>? events,
  }) {
    return TemplateStage(
      id: id ?? this.id,
      stageOrder: stageOrder ?? this.stageOrder,
      name: name ?? this.name,
      goal: goal ?? this.goal,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      events: events ?? this.events,
    );
  }
}

class TaskTemplate {
  final int? id;
  final String name;
  final String goal;
  final TemplateSource source;
  final TemplateStatus status;
  final TemplateRelation? relation;
  final int currentCreateStep;
  final int currentStageIndex;
  final bool createCompleted;
  final List<TemplateStage> stages;
  final List<TemplateNotice> notices;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;

  const TaskTemplate({
    this.id,
    required this.name,
    required this.goal,
    required this.source,
    required this.status,
    required this.relation,
    required this.currentCreateStep,
    required this.currentStageIndex,
    required this.createCompleted,
    required this.stages,
    required this.notices,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
  });

  int get eventCount =>
      stages.fold<int>(0, (sum, stage) => sum + stage.eventCount);

  bool get hasAnyEditableContent =>
      name.trim().isNotEmpty ||
      goal.trim().isNotEmpty ||
      stages.any((stage) => stage.hasContent) ||
      notices.any((notice) => notice.content.trim().isNotEmpty);

  TaskTemplate copyWith({
    int? id,
    String? name,
    String? goal,
    TemplateSource? source,
    TemplateStatus? status,
    TemplateRelation? relation,
    bool clearRelation = false,
    int? currentCreateStep,
    int? currentStageIndex,
    bool? createCompleted,
    List<TemplateStage>? stages,
    List<TemplateNotice>? notices,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
  }) {
    return TaskTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      goal: goal ?? this.goal,
      source: source ?? this.source,
      status: status ?? this.status,
      relation: clearRelation ? null : relation ?? this.relation,
      currentCreateStep: currentCreateStep ?? this.currentCreateStep,
      currentStageIndex: currentStageIndex ?? this.currentStageIndex,
      createCompleted: createCompleted ?? this.createCompleted,
      stages: stages ?? this.stages,
      notices: notices ?? this.notices,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}

class TemplateDeployment {
  final int id;
  final TaskTemplate template;
  final TemplateDeploymentStatus status;
  final int activeStageIndex;
  final bool pauseAfterCurrentStage;
  final DateTime deployedAt;
  final DateTime? enabledAt;
  final DateTime? completedAt;
  final bool expanded;

  const TemplateDeployment({
    required this.id,
    required this.template,
    required this.status,
    required this.activeStageIndex,
    required this.pauseAfterCurrentStage,
    required this.deployedAt,
    this.enabledAt,
    this.completedAt,
    this.expanded = false,
  });

  TemplateStage? get activeStage {
    if (template.stages.isEmpty) return null;
    final index = activeStageIndex.clamp(0, template.stages.length - 1).toInt();
    return template.stages[index];
  }

  double get progress {
    final total = template.eventCount;
    if (total == 0) return 0;
    if (status == TemplateDeploymentStatus.completed) return 1;
    final completed = activeStageIndex.clamp(0, total);
    return completed / total;
  }

  int get elapsedMinutes {
    final start = enabledAt ?? deployedAt;
    final end = completedAt ?? DateTime.now();
    return end.difference(start).inMinutes.clamp(0, 9999);
  }

  TemplateDeployment copyWith({
    int? id,
    TaskTemplate? template,
    TemplateDeploymentStatus? status,
    int? activeStageIndex,
    bool? pauseAfterCurrentStage,
    DateTime? deployedAt,
    DateTime? enabledAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    bool? expanded,
  }) {
    return TemplateDeployment(
      id: id ?? this.id,
      template: template ?? this.template,
      status: status ?? this.status,
      activeStageIndex: activeStageIndex ?? this.activeStageIndex,
      pauseAfterCurrentStage:
          pauseAfterCurrentStage ?? this.pauseAfterCurrentStage,
      deployedAt: deployedAt ?? this.deployedAt,
      enabledAt: enabledAt ?? this.enabledAt,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      expanded: expanded ?? this.expanded,
    );
  }
}

class TemplateHomeSnapshot {
  final List<TaskTemplate> drafts;
  final List<TemplateDeployment> notStartedDeployments;
  final List<TemplateDeployment> activeDeployments;
  final List<TemplateDeployment> completedDeployments;
  final List<TaskTemplate> officialTemplates;

  const TemplateHomeSnapshot({
    required this.drafts,
    required this.notStartedDeployments,
    required this.activeDeployments,
    required this.completedDeployments,
    required this.officialTemplates,
  });
}
