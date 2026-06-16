import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/template_models.dart';
import 'package:frontend/repositories/event_repository.dart';
import 'package:frontend/repositories/template_repository.dart';
import 'package:frontend/services/database.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('template repository persists draft lifecycle', () async {
    final repository = TemplateRepository();
    final uniqueName = '测试草稿${DateTime.now().microsecondsSinceEpoch}';
    int? draftId;

    try {
      final saved = await repository.saveDraft(
        TaskTemplate(
          name: uniqueName,
          goal: '验证草稿保存和回读',
          source: TemplateSource.user,
          status: TemplateStatus.draft,
          relation: TemplateRelation.linear,
          currentCreateStep: 4,
          currentStageIndex: 0,
          createCompleted: true,
          stages: const [
            TemplateStage(
              stageOrder: 1,
              name: '阶段一',
              goal: '完成第一阶段',
              estimatedMinutes: 30,
              events: [
                TemplateStageEvent(
                  eventOrder: 1,
                  title: '事件一',
                  purpose: '验证事件保存',
                  estimatedMinutes: 30,
                  steps: [
                    TemplateStageEventStep(
                      stepOrder: 1,
                      description: '步骤一',
                      estimatedMinutes: 30,
                    ),
                  ],
                ),
              ],
            ),
          ],
          notices: const [TemplateNotice(noticeOrder: 1, content: '注意事项')],
          createdAt: DateTime(2026, 6, 12),
          updatedAt: DateTime(2026, 6, 12),
        ),
      );
      draftId = saved.id;

      expect(draftId, isNotNull);
      expect(saved.stages.single.events.single.steps.single.description, '步骤一');

      final loaded = await repository.loadTemplate(draftId!);
      expect(loaded?.name, uniqueName);
      expect(loaded?.stages.single.events.single.title, '事件一');
      expect(loaded?.notices.single.content, '注意事项');

      final updated = await repository.saveDraft(
        loaded!.copyWith(goal: '修改后的目标'),
      );
      expect(updated.goal, '修改后的目标');

      final snapshot = await repository.loadHome();
      expect(
        snapshot.drafts.any(
          (template) => template.id == draftId && template.goal == '修改后的目标',
        ),
        isTrue,
      );
    } finally {
      if (draftId != null) {
        await repository.deleteDraft(draftId);
      }
    }

    final savedDraftId = draftId;
    final afterDelete = await repository.loadTemplate(savedDraftId);
    expect(afterDelete, isNull);
  });

  test(
    'template repository leaves official templates empty without backend',
    () async {
      final repository = TemplateRepository();

      final snapshot = await repository.loadHome();

      expect(snapshot.officialTemplates, isEmpty);
    },
  );

  test(
    'linear deployment generates current stage and syncs progress',
    () async {
      final repository = TemplateRepository();
      const eventRepository = EventRepository();
      final unique = DateTime.now().microsecondsSinceEpoch;
      final saved = await repository.saveDraft(
        _deploymentTemplate(
          name: '线性部署$unique',
          relation: TemplateRelation.linear,
          firstEventTitle: '线性一$unique',
          secondEventTitle: '线性二$unique',
        ),
      );
      int? deploymentId;

      try {
        await repository.deployTemplate(saved.id!);
        var snapshot = await repository.loadHome();
        var deployment = snapshot.notStartedDeployments.firstWhere(
          (item) => item.template.id == saved.id,
        );
        deploymentId = deployment.id;

        await repository.enableDeployment(deployment.id);
        snapshot = await repository.loadHome();
        deployment = snapshot.activeDeployments.firstWhere(
          (item) => item.id == deploymentId,
        );

        expect(deployment.activeStage?.stageOrder, 1);
        expect(
          deployment.progressForStage(deployment.template.stages[0])?.status,
          TemplateDeploymentStageStatus.inProgress,
        );

        final inboxEvents = await eventRepository.loadEvents(status: 'inbox');
        final generated = inboxEvents.firstWhere(
          (event) => event.title == '线性一$unique',
        );

        await eventRepository.markCompleted(generated, DateTime.now());
        snapshot = await repository.loadHome();
        deployment = snapshot.activeDeployments.firstWhere(
          (item) => item.id == deploymentId,
        );

        expect(
          deployment.progressForStage(deployment.template.stages[0])?.status,
          TemplateDeploymentStageStatus.completed,
        );
        expect(deployment.activeStage?.stageOrder, 2);
        expect(deployment.completedEventCount, 1);
      } finally {
        if (deploymentId != null) {
          await LocalDatabase.deleteTemplateDeployment(deploymentId);
        }
        await repository.deleteDraft(saved.id!);
      }
    },
  );

  test('reset deployment trashes generated events before reuse', () async {
    final repository = TemplateRepository();
    const eventRepository = EventRepository();
    final unique = DateTime.now().microsecondsSinceEpoch;
    final firstTitle = '重置一$unique';
    final secondTitle = '重置二$unique';
    final saved = await repository.saveDraft(
      _deploymentTemplate(
        name: '重置部署$unique',
        relation: TemplateRelation.linear,
        firstEventTitle: firstTitle,
        secondEventTitle: secondTitle,
      ),
    );
    int? deploymentId;

    try {
      await repository.deployTemplate(saved.id!);
      var snapshot = await repository.loadHome();
      var deployment = snapshot.notStartedDeployments.firstWhere(
        (item) => item.template.id == saved.id,
      );
      deploymentId = deployment.id;

      await repository.enableDeployment(deployment.id);
      var inboxEvents = await eventRepository.loadEvents(status: 'inbox');
      final generated = inboxEvents.firstWhere(
        (event) => event.title == firstTitle,
      );
      final generatedId = generated.id;
      expect(generatedId, isNotNull);

      await repository.resetActiveDeployment(deployment.id);

      inboxEvents = await eventRepository.loadEvents(status: 'inbox');
      expect(inboxEvents.any((event) => event.id == generatedId), isFalse);
      final deletedEvents = await eventRepository.loadDeletedArrangeEvents();
      expect(deletedEvents.any((event) => event.id == generatedId), isTrue);

      await repository.enableDeployment(deployment.id);
      inboxEvents = await eventRepository.loadEvents(status: 'inbox');
      final regenerated = inboxEvents
          .where((event) => event.title == firstTitle)
          .toList();
      expect(regenerated, hasLength(1));
      expect(regenerated.single.id, isNot(generatedId));
    } finally {
      final activeEvents = await eventRepository.loadEvents();
      final deletedEvents = await eventRepository.loadDeletedArrangeEvents();
      for (final event in [...activeEvents, ...deletedEvents]) {
        if (event.id != null &&
            (event.title == firstTitle || event.title == secondTitle)) {
          await LocalDatabase.deleteEventPermanently(event.id!);
        }
      }
      if (deploymentId != null) {
        await LocalDatabase.deleteTemplateDeployment(deploymentId);
      }
      await repository.deleteDraft(saved.id!);
    }
  });

  test('parallel deployment waits for manual stage activation', () async {
    final repository = TemplateRepository();
    const eventRepository = EventRepository();
    final unique = DateTime.now().microsecondsSinceEpoch;
    final saved = await repository.saveDraft(
      _deploymentTemplate(
        name: '并列部署$unique',
        relation: TemplateRelation.parallel,
        firstEventTitle: '并列一$unique',
        secondEventTitle: '并列二$unique',
      ),
    );
    int? deploymentId;

    try {
      await repository.deployTemplate(saved.id!);
      var snapshot = await repository.loadHome();
      var deployment = snapshot.notStartedDeployments.firstWhere(
        (item) => item.template.id == saved.id,
      );
      deploymentId = deployment.id;

      await repository.enableDeployment(deployment.id);
      snapshot = await repository.loadHome();
      deployment = snapshot.activeDeployments.firstWhere(
        (item) => item.id == deploymentId,
      );

      expect(deployment.activeStage, isNull);
      var inboxEvents = await eventRepository.loadEvents(status: 'inbox');
      expect(inboxEvents.any((event) => event.title == '并列一$unique'), isFalse);

      final secondStage = deployment.template.stages[1];
      await repository.enableDeploymentStage(deployment.id, secondStage.id!);
      snapshot = await repository.loadHome();
      deployment = snapshot.activeDeployments.firstWhere(
        (item) => item.id == deploymentId,
      );

      expect(deployment.activeStage?.stageOrder, 2);
      expect(
        deployment.progressForStage(secondStage)?.status,
        TemplateDeploymentStageStatus.inProgress,
      );
      inboxEvents = await eventRepository.loadEvents(status: 'inbox');
      expect(inboxEvents.any((event) => event.title == '并列二$unique'), isTrue);
    } finally {
      if (deploymentId != null) {
        await LocalDatabase.deleteTemplateDeployment(deploymentId);
      }
      await repository.deleteDraft(saved.id!);
    }
  });
}

TaskTemplate _deploymentTemplate({
  required String name,
  required TemplateRelation relation,
  required String firstEventTitle,
  required String secondEventTitle,
}) {
  return TaskTemplate(
    name: name,
    goal: '验证部署',
    source: TemplateSource.user,
    status: TemplateStatus.draft,
    relation: relation,
    currentCreateStep: 4,
    currentStageIndex: 0,
    createCompleted: true,
    stages: [
      TemplateStage(
        stageOrder: 1,
        name: '阶段一',
        goal: '完成第一阶段',
        estimatedMinutes: 30,
        events: [
          TemplateStageEvent(
            eventOrder: 1,
            title: firstEventTitle,
            purpose: '验证第一阶段生成',
            estimatedMinutes: 30,
            steps: const [
              TemplateStageEventStep(
                stepOrder: 1,
                description: '步骤一',
                estimatedMinutes: 30,
              ),
            ],
          ),
        ],
      ),
      TemplateStage(
        stageOrder: 2,
        name: '阶段二',
        goal: '完成第二阶段',
        estimatedMinutes: 20,
        events: [
          TemplateStageEvent(
            eventOrder: 1,
            title: secondEventTitle,
            purpose: '验证第二阶段生成',
            estimatedMinutes: 20,
            steps: const [
              TemplateStageEventStep(
                stepOrder: 1,
                description: '步骤二',
                estimatedMinutes: 20,
              ),
            ],
          ),
        ],
      ),
    ],
    notices: const [],
    createdAt: DateTime(2026, 6, 12),
    updatedAt: DateTime(2026, 6, 12),
  );
}
