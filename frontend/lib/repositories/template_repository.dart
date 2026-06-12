import '../models/template_models.dart';
import '../services/database.dart';

class TemplateRepository {
  TemplateRepository();

  static int _nextDeploymentId = 10;

  static final List<TaskTemplate> _officials = _buildOfficialTemplates();
  static final List<TemplateDeployment> _deployments = _buildDeployments();

  Future<TemplateHomeSnapshot> loadHome() async {
    final drafts = await LocalDatabase.getDraftTemplates();
    return TemplateHomeSnapshot(
      drafts: List.unmodifiable(drafts),
      notStartedDeployments: List.unmodifiable(
        _deployments.where(
          (item) => item.status == TemplateDeploymentStatus.notStarted,
        ),
      ),
      activeDeployments: List.unmodifiable(
        _deployments.where(
          (item) => item.status == TemplateDeploymentStatus.active,
        ),
      ),
      completedDeployments: List.unmodifiable(
        _deployments.where(
          (item) => item.status == TemplateDeploymentStatus.completed,
        ),
      ),
      officialTemplates: List.unmodifiable(_officials),
    );
  }

  Future<TaskTemplate?> loadTemplate(int templateId) async {
    final stored = await LocalDatabase.getTemplateById(templateId);
    if (stored != null) return stored;

    for (final template in _officials) {
      if (template.id == templateId) return template;
    }
    for (final deployment in _deployments) {
      if (deployment.template.id == templateId) return deployment.template;
    }
    return null;
  }

  Future<TaskTemplate> saveDraft(TaskTemplate draft) async {
    return LocalDatabase.saveDraftTemplate(
      draft.copyWith(source: TemplateSource.user, status: TemplateStatus.draft),
    );
  }

  Future<void> deleteDraft(int templateId) async {
    await LocalDatabase.deleteDraftTemplate(templateId);
  }

  Future<void> deleteNotStartedDeployment(int deploymentId) async {
    _deployments.removeWhere(
      (item) =>
          item.id == deploymentId &&
          item.status == TemplateDeploymentStatus.notStarted,
    );
  }

  Future<void> enableDeployment(int deploymentId, {int stageIndex = 0}) async {
    final index = _deployments.indexWhere((item) => item.id == deploymentId);
    if (index == -1) return;
    _deployments[index] = _deployments[index].copyWith(
      status: TemplateDeploymentStatus.active,
      enabledAt: DateTime.now(),
      activeStageIndex: stageIndex,
      expanded: false,
      clearCompletedAt: true,
    );
  }

  Future<void> resetActiveDeployment(int deploymentId) async {
    final index = _deployments.indexWhere((item) => item.id == deploymentId);
    if (index == -1) return;
    _deployments[index] = _deployments[index].copyWith(
      status: TemplateDeploymentStatus.notStarted,
      activeStageIndex: 0,
      pauseAfterCurrentStage: false,
      expanded: false,
      clearCompletedAt: true,
    );
  }

  Future<void> pauseDeployment(int deploymentId) async {
    final index = _deployments.indexWhere((item) => item.id == deploymentId);
    if (index == -1) return;
    final item = _deployments[index];
    _deployments[index] = item.copyWith(
      pauseAfterCurrentStage: !item.pauseAfterCurrentStage,
    );
  }

  Future<void> toggleDeploymentExpanded(int deploymentId) async {
    final index = _deployments.indexWhere((item) => item.id == deploymentId);
    if (index == -1) return;
    final item = _deployments[index];
    _deployments[index] = item.copyWith(expanded: !item.expanded);
  }

  Future<void> reuseCompletedDeployment(int deploymentId) async {
    TemplateDeployment? deployment;
    for (final item in _deployments) {
      if (item.id == deploymentId) {
        deployment = item;
        break;
      }
    }
    if (deployment == null) return;
    _deployments.insert(
      0,
      TemplateDeployment(
        id: _nextDeploymentId++,
        template: deployment.template,
        status: TemplateDeploymentStatus.notStarted,
        activeStageIndex: 0,
        pauseAfterCurrentStage: false,
        deployedAt: DateTime.now(),
      ),
    );
  }

  Future<void> deployTemplate(int templateId) async {
    final source = await loadTemplate(templateId);
    if (source == null) return;
    _deployments.insert(
      0,
      TemplateDeployment(
        id: _nextDeploymentId++,
        template: source,
        status: TemplateDeploymentStatus.notStarted,
        activeStageIndex: 0,
        pauseAfterCurrentStage: false,
        deployedAt: DateTime.now(),
      ),
    );
  }

  static List<TaskTemplate> _buildOfficialTemplates() {
    final now = DateTime.now();
    return [
      _template(
        id: 101,
        name: '考试复习模板',
        goal: '按章节复习、刷题、回顾错题。',
        source: TemplateSource.official,
        status: TemplateStatus.published,
        relation: TemplateRelation.linear,
        createdAt: now.subtract(const Duration(days: 80)),
      ),
      _template(
        id: 102,
        name: '新习惯养成模板',
        goal: '用阶段化练习建立稳定习惯。',
        source: TemplateSource.official,
        status: TemplateStatus.published,
        relation: TemplateRelation.parallel,
        createdAt: now.subtract(const Duration(days: 120)),
      ),
    ];
  }

  static List<TemplateDeployment> _buildDeployments() {
    final now = DateTime.now();
    final notStarted = _template(
      id: 201,
      name: '搬家准备模板',
      goal: '完成打包、手续和搬家当天安排。',
      relation: TemplateRelation.linear,
      createdAt: now.subtract(const Duration(days: 10)),
    );
    final active = _template(
      id: 202,
      name: '作品集整理模板',
      goal: '筛选、修订并发布作品集。',
      relation: TemplateRelation.parallel,
      createdAt: now.subtract(const Duration(days: 18)),
    );
    final completed = _template(
      id: 203,
      name: '旅行计划模板',
      goal: '确定路线、预算和行前物品。',
      relation: TemplateRelation.linear,
      createdAt: now.subtract(const Duration(days: 70)),
    );

    return [
      TemplateDeployment(
        id: 1,
        template: notStarted,
        status: TemplateDeploymentStatus.notStarted,
        activeStageIndex: 0,
        pauseAfterCurrentStage: false,
        deployedAt: now.subtract(const Duration(days: 3)),
      ),
      TemplateDeployment(
        id: 2,
        template: active,
        status: TemplateDeploymentStatus.active,
        activeStageIndex: 1,
        pauseAfterCurrentStage: false,
        deployedAt: now.subtract(const Duration(days: 8)),
        enabledAt: now.subtract(const Duration(days: 2, hours: 4)),
        expanded: false,
      ),
      TemplateDeployment(
        id: 3,
        template: completed,
        status: TemplateDeploymentStatus.completed,
        activeStageIndex: 2,
        pauseAfterCurrentStage: false,
        deployedAt: now.subtract(const Duration(days: 50)),
        enabledAt: now.subtract(const Duration(days: 48)),
        completedAt: now.subtract(const Duration(days: 42)),
      ),
    ];
  }

  static TaskTemplate _template({
    required int id,
    required String name,
    required String goal,
    required TemplateRelation relation,
    required DateTime createdAt,
    TemplateSource source = TemplateSource.user,
    TemplateStatus status = TemplateStatus.draft,
    bool createCompleted = true,
    int currentCreateStep = 4,
    int currentStageIndex = 0,
  }) {
    return TaskTemplate(
      id: id,
      name: name,
      goal: goal,
      source: source,
      status: status,
      relation: relation,
      currentCreateStep: currentCreateStep,
      currentStageIndex: currentStageIndex,
      createCompleted: createCompleted,
      stages: [
        TemplateStage(
          id: id * 10 + 1,
          stageOrder: 1,
          name: '准备',
          goal: '确认目标、范围和必要资料。',
          estimatedMinutes: 90,
          events: [
            _event(id * 100 + 1, 1, '整理资料', 40),
            _event(id * 100 + 2, 2, '列出任务清单', 50),
          ],
        ),
        TemplateStage(
          id: id * 10 + 2,
          stageOrder: 2,
          name: '执行',
          goal: '按计划完成核心事项。',
          estimatedMinutes: 150,
          events: [
            _event(id * 100 + 3, 1, '推进第一批任务', 80),
            _event(id * 100 + 4, 2, '检查并调整计划', 70),
          ],
        ),
        TemplateStage(
          id: id * 10 + 3,
          stageOrder: 3,
          name: '收尾',
          goal: '复盘结果并完成归档。',
          estimatedMinutes: 60,
          events: [_event(id * 100 + 5, 1, '完成复盘记录', 60)],
        ),
      ],
      notices: const [
        TemplateNotice(id: 1, noticeOrder: 1, content: '每个阶段开始前先确认当前可用时间。'),
        TemplateNotice(id: 2, noticeOrder: 2, content: '如果中途目标变化，先回到总览页调整模板。'),
      ],
      createdAt: createdAt,
      updatedAt: createdAt.add(const Duration(hours: 2)),
      publishedAt: source == TemplateSource.official ? createdAt : null,
    );
  }

  static TemplateStageEvent _event(
    int id,
    int order,
    String title,
    int minutes,
  ) {
    return TemplateStageEvent(
      id: id,
      eventOrder: order,
      title: title,
      purpose: '让这一步有清晰产出。',
      estimatedMinutes: minutes,
      steps: [
        TemplateStageEventStep(
          id: id * 10 + 1,
          stepOrder: 1,
          description: '明确要做的第一件事',
          estimatedMinutes: minutes ~/ 2,
        ),
        TemplateStageEventStep(
          id: id * 10 + 2,
          stepOrder: 2,
          description: '完成并记录结果',
          estimatedMinutes: minutes - minutes ~/ 2,
        ),
      ],
    );
  }
}
